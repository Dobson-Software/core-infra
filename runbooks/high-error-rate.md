# Runbook: High Error Rate (API 5xx > 5%)

## Trigger
- Alert: ALB 5xx error rate exceeds 5% for 2 evaluation periods
- Severity: P1
- Impact: Users experiencing failures

## Diagnostic Steps

### Step 1: Identify affected services
```bash
# Check which target groups have unhealthy targets
kubectl get pods -n cobalt-services | grep -v Running
```
```apl
['cobalt-prod'] | where level == 'ERROR' | summarize count() by kubernetes.labels.app, bin(_time, 1m) | sort by _time desc
```

### Step 2: Check for recent deployments
```bash
kubectl get deployments -n cobalt-services -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.deployment\.kubernetes\.io/revision}{"\t"}{.metadata.creationTimestamp}{"\n"}{end}'
```
- **If a deployment happened in the last 30 minutes** → likely cause. Go to "Remediation: Bad Deployment"

### Step 3: Check error logs
```apl
['cobalt-prod'] | where level == 'ERROR' | sort by _time desc | take 50
```
Look for:
- `java.lang.OutOfMemoryError` → Go to "Remediation: OOM"
- `org.postgresql.util.PSQLException` → Go to "Remediation: Database Issue"
- `java.net.ConnectException` → Go to "Remediation: Connectivity Issue"
- Stack traces with business logic → Go to "Remediation: Code Bug"

### Step 4: Check pod health
```bash
kubectl get pods -n cobalt-services -o wide
kubectl top pods -n cobalt-services
```

### Step 5: Check database
```bash
# CloudWatch: RDS CPU and connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=cobalt-prod \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 --statistics Average
```

## Remediation

### Bad Deployment
```bash
# Rollback to previous version
kubectl rollout undo deployment/cobalt-core-service -n cobalt-services
kubectl rollout status deployment/cobalt-core-service -n cobalt-services --timeout=120s
```
- **Verify**: Error rate drops below 1% within 5 minutes
- **Follow-up**: Create GitHub issue for the broken deployment

### OOM (Out of Memory)
```bash
# Check which pods were OOM killed
kubectl get events -n cobalt-services --field-selector reason=OOMKilled
# Short-term: increase replicas to spread load
kubectl scale deployment/cobalt-core-service --replicas=2 -n cobalt-services
```
- **Verify**: No new OOMKilled events in 10 minutes
- **Follow-up**: Investigate memory leak, increase pod memory limits

### Database Issue
```bash
# Check connection count
kubectl logs deployment/cobalt-core-service -n cobalt-services --tail=50 | grep -i "connection"
# Rolling restart to reset connection pools
kubectl rollout restart deployment/cobalt-core-service -n cobalt-services
```
- **Verify**: Database connections normalize, errors stop
- **Follow-up**: Check HikariCP pool settings, look for connection leaks

### Connectivity Issue
- Check VPC security groups, NACLs, NAT gateway status
- Check if downstream services (notification-service, violations-service) are healthy
- Check DNS resolution from within the pod

### Code Bug
- Capture full stack trace from logs
- Create GitHub issue with stack trace, request context, and reproduction steps
- If affecting all requests: rollback deployment
- If affecting specific endpoints: consider feature flag or quick patch

## Escalation
- If not resolved in 15 minutes: page on-call engineer
- If root cause unclear after investigation: escalate to P1 incident channel
