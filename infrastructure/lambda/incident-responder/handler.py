"""
Cobalt AI Incident Responder Lambda

Triggered by SNS when a CloudWatch alarm fires. Uses Claude API to:
1. Parse the alarm details
2. Query Axiom for recent error logs
3. Match against operational runbooks
4. Generate a structured incident report
5. Create a GitHub Issue with findings
"""

import json
import os
import urllib.request
import urllib.error
from datetime import datetime, timezone


ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
AXIOM_API_TOKEN = os.environ.get("AXIOM_API_TOKEN", "")
AXIOM_DATASET = os.environ.get("AXIOM_DATASET", "cobalt-logs")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
GITHUB_REPO = os.environ.get("GITHUB_REPO", "")
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "prod")
CLAUDE_MODEL = "claude-sonnet-4-20250514"


# ---------------------------------------------------------------------------
# Runbook content (embedded so Lambda doesn't need filesystem access)
# ---------------------------------------------------------------------------
RUNBOOKS = {
    "5xx": {
        "title": "High Error Rate",
        "severity": "P1",
        "steps": [
            "Check for recent deployments (kubectl rollout history)",
            "Query Axiom: ['cobalt-logs'] | where level == 'ERROR' | sort by _time desc | limit 50",
            "Check pod health: kubectl get pods -n cobalt-services",
            "Check pod events: kubectl describe pods -n cobalt-services",
            "Check RDS connections and CPU via CloudWatch",
            "If deployment-related: kubectl rollout undo deployment/<service>",
        ],
    },
    "rds-cpu": {
        "title": "Database CPU Pressure",
        "severity": "P2",
        "steps": [
            "Check active queries: pg_stat_activity",
            "Look for long-running queries or lock waits",
            "Check connection count vs pool size",
            "Query Axiom for slow query logs (> 1s)",
            "Check if issue correlates with a deployment or traffic spike",
        ],
    },
    "rds-connections": {
        "title": "Database Connection Pressure",
        "severity": "P2",
        "steps": [
            "Check HikariCP pool metrics via /actuator/metrics",
            "Verify connection pool settings (max 10 per service = 30 total)",
            "Check for connection leaks in logs",
            "Check if a service is in a restart loop consuming connections",
        ],
    },
    "latency": {
        "title": "High Latency",
        "severity": "P2",
        "steps": [
            "Query Axiom for slow requests (>2s)",
            "Check if specific endpoints or tenants are affected",
            "Check RDS and pod CPU/memory",
            "Look for N+1 query patterns in logs",
        ],
    },
    "pod-crash": {
        "title": "Pod Crash / Restart",
        "severity": "P1",
        "steps": [
            "kubectl get pods -n cobalt-services (check restart counts)",
            "kubectl describe pod <name> -n cobalt-services (check events)",
            "kubectl logs <name> -n cobalt-services --previous (check crash logs)",
            "Check for OOMKilled in pod events",
            "Check for startup probe failures",
        ],
    },
}


def _classify_alarm(alarm_name: str) -> str:
    """Map alarm name to runbook key."""
    name = alarm_name.lower()
    if "5xx" in name:
        return "5xx"
    if "cpu" in name and "rds" in name:
        return "rds-cpu"
    if "connection" in name:
        return "rds-connections"
    if "latency" in name:
        return "latency"
    return "5xx"  # default to high error rate runbook


def _http_post(url: str, headers: dict, body: dict, timeout: int = 30) -> dict:
    """Simple HTTP POST using urllib (no external dependencies)."""
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8") if e.fp else ""
        print(f"HTTP {e.code} from {url}: {error_body[:500]}")
        raise


def _query_axiom(query: str, timeout: int = 20) -> list:
    """Query Axiom APL endpoint for recent logs."""
    if not AXIOM_API_TOKEN:
        return [{"note": "Axiom not configured — skipping log query"}]

    url = "https://api.axiom.co/v1/datasets/_apl"
    headers = {
        "Authorization": f"Bearer {AXIOM_API_TOKEN}",
        "Content-Type": "application/json",
    }
    body = {
        "apl": query,
        "startTime": datetime.now(timezone.utc).isoformat(),
        "endTime": datetime.now(timezone.utc).isoformat(),
    }

    try:
        result = _http_post(url, headers, body, timeout=timeout)
        matches = result.get("matches", [])
        return [m.get("data", m) for m in matches[:30]]
    except Exception as e:
        return [{"error": f"Axiom query failed: {str(e)}"}]


def _call_claude(system_prompt: str, user_message: str) -> str:
    """Call Anthropic Messages API."""
    if not ANTHROPIC_API_KEY:
        return "Claude API key not configured. Manual investigation required."

    url = "https://api.anthropic.com/v1/messages"
    headers = {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
    }
    body = {
        "model": CLAUDE_MODEL,
        "max_tokens": 4096,
        "system": system_prompt,
        "messages": [{"role": "user", "content": user_message}],
    }

    result = _http_post(url, headers, body, timeout=60)
    content = result.get("content", [])
    return content[0].get("text", "") if content else "No response from Claude"


def _create_github_issue(title: str, body: str, labels: list) -> str:
    """Create a GitHub issue with the incident report."""
    if not GITHUB_TOKEN or not GITHUB_REPO:
        print("GitHub not configured — skipping issue creation")
        return ""

    url = f"https://api.github.com/repos/{GITHUB_REPO}/issues"
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json",
    }
    issue_body = {
        "title": title,
        "body": body,
        "labels": labels,
    }

    result = _http_post(url, headers, issue_body, timeout=15)
    return result.get("html_url", "")


def _post_slack(message: str) -> None:
    """Post a message to Slack via webhook."""
    if not SLACK_WEBHOOK_URL:
        return

    headers = {"Content-Type": "application/json"}
    body = {"text": message}
    try:
        _http_post(SLACK_WEBHOOK_URL, headers, body, timeout=10)
    except Exception as e:
        print(f"Slack notification failed: {e}")


def handler(event, context):
    """Lambda entry point — triggered by SNS."""
    print(f"Received event: {json.dumps(event)[:1000]}")

    # Parse SNS message
    for record in event.get("Records", []):
        sns_message = record.get("Sns", {}).get("Message", "{}")
        try:
            alarm = json.loads(sns_message)
        except json.JSONDecodeError:
            alarm = {"AlarmName": "unknown", "NewStateReason": sns_message}

        alarm_name = alarm.get("AlarmName", "unknown")
        alarm_state = alarm.get("NewStateValue", "ALARM")
        alarm_reason = alarm.get("NewStateReason", "No reason provided")
        alarm_time = alarm.get("StateChangeTime", datetime.now(timezone.utc).isoformat())

        # Only investigate ALARM state (not OK recovery)
        if alarm_state == "OK":
            print(f"Alarm {alarm_name} recovered to OK — no investigation needed")
            _post_slack(f"Resolved: {alarm_name} in {ENVIRONMENT} returned to OK state")
            return {"statusCode": 200, "body": "OK state — no action"}

        print(f"Investigating alarm: {alarm_name} ({alarm_state})")

        # Classify and get runbook
        category = _classify_alarm(alarm_name)
        runbook = RUNBOOKS.get(category, RUNBOOKS["5xx"])

        # Query Axiom for recent errors
        error_logs = _query_axiom(
            f"['{AXIOM_DATASET}'] | where level == 'ERROR' | sort by _time desc | limit 30"
        )

        # Query for recent warn-level logs too
        warn_logs = _query_axiom(
            f"['{AXIOM_DATASET}'] | where level == 'WARN' | sort by _time desc | limit 15"
        )

        # Build context for Claude
        system_prompt = """You are the Cobalt platform AI incident response agent.

Platform: 3 Spring Boot services (core:8080, notification:8081, violations:8082) + React frontend on EKS.
Database: PostgreSQL on RDS. Caching: Caffeine (in-process). Logs: Structured JSON with MDC (requestId, tenantId, userId).

Your job is to analyze the alarm and log evidence, then produce a structured incident report.

Safety rules:
- NEVER recommend destructive actions without flagging them as requiring human approval
- NEVER include sensitive data (passwords, tokens, PII) in the report
- If uncertain about root cause, say so — do not guess
- Always reference the relevant runbook steps
- Include specific log excerpts as evidence"""

        user_message = f"""## Alert Triggered

**Alarm**: {alarm_name}
**State**: {alarm_state}
**Time**: {alarm_time}
**Reason**: {alarm_reason}
**Environment**: {ENVIRONMENT}

## Relevant Runbook: {runbook['title']} ({runbook['severity']})

Investigation steps:
{chr(10).join(f'- {step}' for step in runbook['steps'])}

## Recent Error Logs (from Axiom)

```json
{json.dumps(error_logs[:20], indent=2, default=str)[:3000]}
```

## Recent Warning Logs

```json
{json.dumps(warn_logs[:10], indent=2, default=str)[:1500]}
```

Please produce an incident report following this format:

## Incident Report: [Title]
**Alert**: [details]
**Severity**: {runbook['severity']}
**Time detected**: {alarm_time}
**Services affected**: [determine from logs]
**Tenants affected**: [determine from logs]

### Timeline
[reconstruct from evidence]

### Evidence
[cite specific log entries]

### Root Cause Analysis
[your diagnosis]

### Recommended Actions
[numbered list with expected outcomes — flag destructive actions as REQUIRES HUMAN APPROVAL]

### Risk Assessment
- Immediate risk: [high/medium/low]
- Customer impact: [description]
- Data integrity: [assessment]"""

        # Call Claude for analysis
        report = _call_claude(system_prompt, user_message)
        print(f"Claude report generated ({len(report)} chars)")

        # Create GitHub Issue
        severity_label = runbook["severity"].lower()
        issue_title = f"[{runbook['severity']}] {ENVIRONMENT}: {alarm_name}"
        issue_body = f"""> Auto-generated by Cobalt AI Incident Responder

{report}

---

**Alarm details**: `{alarm_name}` transitioned to `{alarm_state}`
**Trigger reason**: {alarm_reason[:500]}
**Runbook**: {runbook['title']}
**Environment**: {ENVIRONMENT}
"""

        issue_url = _create_github_issue(
            title=issue_title,
            body=issue_body,
            labels=["incident", severity_label, f"env:{ENVIRONMENT}", "ai-generated"],
        )

        if issue_url:
            print(f"GitHub Issue created: {issue_url}")

        # Notify Slack
        slack_msg = (
            f"*{runbook['severity']} Incident — {ENVIRONMENT}*\n"
            f"Alarm: `{alarm_name}`\n"
            f"AI Report: {issue_url or 'See GitHub Issues'}\n"
            f"Runbook: {runbook['title']}"
        )
        _post_slack(slack_msg)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "alarm": alarm_name,
                "category": category,
                "severity": runbook["severity"],
                "github_issue": issue_url,
                "report_length": len(report),
            }),
        }

    return {"statusCode": 200, "body": "No records processed"}
