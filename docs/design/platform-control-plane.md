# Platform Control Plane — Design Document

**Status:** Draft
**Author:** Engineering
**Created:** 2026-02-03
**Last Updated:** 2026-02-03

---

## Executive Summary

The Platform Control Plane (codename: **Apollo**) is an internal developer platform that provides unified visibility, deployment management, and AI-assisted operations across all production stacks. It serves as the single pane of glass for managing 20-50+ applications across multiple environments.

### Core Capabilities

1. **Service Catalog** — Registry of all applications, their environments, and metadata
2. **Deployment Management** — One-click deployments, rollbacks, and environment provisioning
3. **Secrets Management** — UI for managing credentials across all stacks
4. **Cost Intelligence** — Per-service, per-environment cost tracking and optimization
5. **Incident Management** — Alerts, runbooks, and resolution tracking
6. **Observability Hub** — Unified access to logs, metrics, and traces
7. **AI Operations Console** — Claude-powered terminal for debugging, upgrades, and automation

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Apollo UI (React)                               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ Service  │ │ Deploy   │ │ Secrets  │ │  Costs   │ │ Incidents│          │
│  │ Catalog  │ │ Center   │ │ Manager  │ │ Dashboard│ │ & Alerts │          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│  ┌──────────────────────────────────────────────────────────────┐          │
│  │                   AI Operations Console                       │          │
│  │  ┌─────────────────────────────────────────────────────────┐ │          │
│  │  │  Claude Code Terminal (WebSocket + PTY)                 │ │          │
│  │  │  $ apollo debug cobalt-prod core-service                │ │          │
│  │  │  > Analyzing logs from last 15 minutes...               │ │          │
│  │  │  > Found 3 errors related to database connection pool   │ │          │
│  │  └─────────────────────────────────────────────────────────┘ │          │
│  └──────────────────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Apollo API (Go / Rust)                               │
│                                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Catalog    │  │  Deploy     │  │  Secrets    │  │  Cost       │        │
│  │  Service    │  │  Service    │  │  Service    │  │  Service    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Incident   │  │  Logs       │  │  AI Agent   │  │  Audit      │        │
│  │  Service    │  │  Service    │  │  Orchestrator│ │  Service    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────┐         │
│  │                    Agent Runtime Pool                          │         │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐          │         │
│  │  │ Agent 1 │  │ Agent 2 │  │ Agent 3 │  │ Agent N │          │         │
│  │  │ (idle)  │  │ (active)│  │ (active)│  │ (idle)  │          │         │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘          │         │
│  └───────────────────────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│   AWS Integration   │  │  GitHub Integration │  │  Monitoring Stack   │
│  • EKS clusters     │  │  • Repository sync  │  │  • Axiom / Datadog  │
│  • Secrets Manager  │  │  • Actions triggers │  │  • PagerDuty        │
│  • Cost Explorer    │  │  • PR automation    │  │  • CloudWatch       │
│  • CloudWatch       │  │  • ArgoCD sync      │  │  • Prometheus       │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

---

## Component Details

### 1. Service Catalog

Central registry of all applications and their deployment topology.

#### Data Model

```typescript
interface Service {
  id: string;
  name: string;                    // e.g., "core-service"
  displayName: string;             // e.g., "Core Service"
  description: string;
  repository: string;              // GitHub repo URL
  team: string;                    // Owning team
  tier: 'critical' | 'standard' | 'experimental';
  language: string;                // e.g., "java", "typescript"
  framework: string;               // e.g., "spring-boot", "react"

  environments: Environment[];
  dependencies: Dependency[];
  runbooks: Runbook[];

  metadata: {
    createdAt: Date;
    updatedAt: Date;
    lastDeployedAt: Date;
    healthStatus: 'healthy' | 'degraded' | 'down' | 'unknown';
  };
}

interface Environment {
  id: string;
  name: string;                    // e.g., "prod", "staging", "dev"
  cluster: string;                 // EKS cluster name
  namespace: string;               // K8s namespace

  deployment: {
    imageTag: string;
    replicas: number;
    lastDeployedAt: Date;
    lastDeployedBy: string;
    gitCommit: string;
  };

  endpoints: {
    internal: string;              // K8s service URL
    external?: string;             // Public URL if exposed
    healthCheck: string;           // Health endpoint
  };

  resources: {
    cpu: { request: string; limit: string };
    memory: { request: string; limit: string };
  };

  secrets: SecretReference[];      // References to required secrets
}

interface Dependency {
  serviceId: string;
  type: 'runtime' | 'build' | 'optional';
  description: string;
}

interface Runbook {
  id: string;
  title: string;
  trigger: string;                 // Alert pattern that triggers this
  content: string;                 // Markdown content
  automatable: boolean;            // Can AI execute this?
  aiPrompt?: string;               // Prompt for AI automation
}
```

#### API Endpoints

```
GET    /api/v1/services                    # List all services
GET    /api/v1/services/:id                # Get service details
POST   /api/v1/services                    # Register new service
PUT    /api/v1/services/:id                # Update service
DELETE /api/v1/services/:id                # Deregister service

GET    /api/v1/services/:id/environments   # List environments
GET    /api/v1/services/:id/dependencies   # Dependency graph
GET    /api/v1/services/:id/runbooks       # List runbooks
GET    /api/v1/services/:id/health         # Aggregated health status
```

#### Service Discovery

Services are discovered via:
1. **GitHub App** — scans repos for `apollo.yaml` manifest
2. **ArgoCD sync** — watches Application resources
3. **Manual registration** — API/UI for legacy services

```yaml
# apollo.yaml — Service manifest (in repo root)
apiVersion: apollo/v1
kind: Service
metadata:
  name: core-service
  displayName: Core Service
  team: platform
  tier: critical
spec:
  language: java
  framework: spring-boot
  port: 5080
  healthCheck: /actuator/health

  dependencies:
    - service: postgres
      type: runtime
    - service: redis
      type: runtime

  runbooks:
    - trigger: "HighErrorRate"
      path: ./docs/runbooks/high-error-rate.md
      automatable: true
    - trigger: "DatabaseConnectionExhausted"
      path: ./docs/runbooks/db-pool-exhausted.md
      automatable: true
```

---

### 2. Deployment Management

GitOps-based deployment with manual override capabilities.

#### Deployment Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Apollo  │────▶│  GitHub  │────▶│  ArgoCD  │────▶│   EKS    │
│    UI    │     │  (PR/    │     │  (sync)  │     │ (deploy) │
│          │     │  merge)  │     │          │     │          │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
     │                                                   │
     │              Deployment Status                    │
     └───────────────────────────────────────────────────┘
```

#### Deployment Operations

| Operation | Description | Implementation |
|-----------|-------------|----------------|
| **Deploy** | Deploy specific version to environment | Update image tag in GitOps repo → ArgoCD syncs |
| **Rollback** | Revert to previous version | Revert GitOps commit or specify previous tag |
| **Promote** | Promote from staging → prod | Copy image tag between environment configs |
| **Scale** | Adjust replica count | Update HPA or deployment replicas |
| **Restart** | Rolling restart | `kubectl rollout restart` via K8s API |

#### API Endpoints

```
POST   /api/v1/deployments                 # Trigger deployment
GET    /api/v1/deployments/:id             # Get deployment status
POST   /api/v1/deployments/:id/cancel      # Cancel in-progress deployment
GET    /api/v1/deployments/history         # Deployment history

POST   /api/v1/services/:id/rollback       # Rollback to previous version
POST   /api/v1/services/:id/promote        # Promote between environments
POST   /api/v1/services/:id/scale          # Scale service
POST   /api/v1/services/:id/restart        # Rolling restart
```

#### Deployment Safeguards

1. **Environment locks** — Prevent deployments during incidents
2. **Approval gates** — Require approval for prod deployments
3. **Canary analysis** — Automatic rollback on error spike
4. **Deployment windows** — Restrict prod deploys to business hours
5. **Dependency checks** — Warn if deploying breaking changes

---

### 3. Secrets Management

Unified interface for managing secrets across all environments.

#### Architecture

```
┌─────────────────┐          ┌─────────────────┐
│    Apollo UI    │          │   Apollo API    │
│  Secrets Panel  │─────────▶│ Secrets Service │
└─────────────────┘          └────────┬────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
            ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
            │ AWS Secrets   │ │ AWS Secrets   │ │ AWS Secrets   │
            │ Manager (dev) │ │ Manager (stg) │ │ Manager (prod)│
            └───────────────┘ └───────────────┘ └───────────────┘
                    │                 │                 │
                    ▼                 ▼                 ▼
            ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
            │ External      │ │ External      │ │ External      │
            │ Secrets (K8s) │ │ Secrets (K8s) │ │ Secrets (K8s) │
            └───────────────┘ └───────────────┘ └───────────────┘
```

#### Secret Categories

| Category | Examples | Rotation Policy |
|----------|----------|-----------------|
| **Database** | Connection strings, passwords | 90 days |
| **API Keys** | Stripe, Twilio, Socrata | 180 days |
| **OAuth** | Google Client ID/Secret | On compromise |
| **Internal** | JWT secrets, service tokens | 30 days |
| **Certificates** | TLS certs, mTLS | Before expiry |

#### API Endpoints

```
GET    /api/v1/secrets                     # List all secrets (metadata only)
GET    /api/v1/secrets/:path               # Get secret metadata
POST   /api/v1/secrets/:path               # Create secret
PUT    /api/v1/secrets/:path               # Update secret value
DELETE /api/v1/secrets/:path               # Delete secret

POST   /api/v1/secrets/:path/rotate        # Trigger rotation
GET    /api/v1/secrets/:path/history       # Version history
POST   /api/v1/secrets/:path/rollback      # Rollback to previous version

GET    /api/v1/secrets/expiring            # Secrets expiring soon
GET    /api/v1/secrets/audit               # Access audit log
```

#### Security Controls

1. **RBAC** — Role-based access (view metadata vs. view value vs. modify)
2. **Audit logging** — All access logged to immutable audit trail
3. **Value masking** — Secret values never returned in full (only last 4 chars)
4. **MFA required** — 2FA for viewing/modifying production secrets
5. **Expiry alerts** — Notify before secrets expire

---

### 4. Cost Intelligence

Real-time and historical cost tracking with optimization recommendations.

#### Data Sources

| Source | Data | Refresh |
|--------|------|---------|
| **AWS Cost Explorer** | Account-level costs by service | Daily |
| **Kubecost** | Per-pod, per-namespace costs | Hourly |
| **CloudWatch** | Resource utilization metrics | Real-time |
| **Reserved Instances** | RI coverage and utilization | Daily |

#### Cost Allocation

```
Organization ($X/month)
├── Environment: Production ($Y/month)
│   ├── Cluster: cobalt-prod ($Z/month)
│   │   ├── Namespace: cobalt-services
│   │   │   ├── core-service: $150/month
│   │   │   ├── notification-service: $80/month
│   │   │   ├── violations-service: $60/month
│   │   │   └── frontend: $40/month
│   │   └── Namespace: monitoring
│   │       ├── prometheus: $50/month
│   │       └── grafana: $20/month
│   ├── RDS: cobalt-prod-db: $200/month
│   └── ElastiCache: cobalt-prod-redis: $80/month
├── Environment: Staging ($A/month)
│   └── ...
└── Environment: Development ($B/month)
    └── ...
```

#### API Endpoints

```
GET    /api/v1/costs/summary               # Organization summary
GET    /api/v1/costs/environments/:env     # Environment breakdown
GET    /api/v1/costs/services/:id          # Service cost history
GET    /api/v1/costs/forecast              # Cost forecast

GET    /api/v1/costs/anomalies             # Cost anomaly alerts
GET    /api/v1/costs/recommendations       # Optimization recommendations
POST   /api/v1/costs/budgets               # Set budget alerts
```

#### Optimization Recommendations

AI-powered recommendations based on:
- **Right-sizing** — Pods requesting more resources than used
- **Spot opportunities** — Workloads suitable for spot instances
- **Reserved instances** — Consistent workloads that should use RIs
- **Idle resources** — Dev environments running outside business hours
- **Storage optimization** — Unused EBS volumes, old snapshots

---

### 5. Incident Management

Centralized incident tracking with runbook automation.

#### Incident Lifecycle

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Alert   │───▶│ Triage  │───▶│ Invest- │───▶│ Resolve │───▶│ Post-   │
│ Fired   │    │         │    │ igate   │    │         │    │ mortem  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     ▼              ▼              ▼              ▼              ▼
  PagerDuty    Auto-assign    AI Console    Auto/Manual    AI-generated
  webhook      + runbook      + logs        remediation    summary
```

#### Data Model

```typescript
interface Incident {
  id: string;
  title: string;
  description: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  status: 'triggered' | 'acknowledged' | 'investigating' | 'resolved';

  source: {
    type: 'pagerduty' | 'cloudwatch' | 'manual' | 'ai-detected';
    alertId?: string;
    alertName?: string;
  };

  affectedServices: string[];      // Service IDs
  affectedEnvironments: string[];  // Environment names

  timeline: TimelineEvent[];
  runbook?: Runbook;
  aiSessions: AISession[];         // Claude sessions for this incident

  assignee?: string;
  acknowledgedAt?: Date;
  resolvedAt?: Date;

  postmortem?: {
    summary: string;
    rootCause: string;
    actionItems: ActionItem[];
    generatedByAI: boolean;
  };
}

interface TimelineEvent {
  timestamp: Date;
  type: 'alert' | 'status_change' | 'comment' | 'action' | 'ai_action';
  actor: string;                   // User or "ai-agent"
  content: string;
  metadata?: Record<string, any>;
}

interface AISession {
  id: string;
  startedAt: Date;
  endedAt?: Date;
  initiatedBy: string;
  prompt: string;
  actions: AIAction[];
  outcome: 'resolved' | 'escalated' | 'in_progress' | 'failed';
}
```

#### API Endpoints

```
GET    /api/v1/incidents                   # List incidents
GET    /api/v1/incidents/:id               # Get incident details
POST   /api/v1/incidents                   # Create manual incident
PUT    /api/v1/incidents/:id               # Update incident
POST   /api/v1/incidents/:id/acknowledge   # Acknowledge
POST   /api/v1/incidents/:id/resolve       # Resolve

POST   /api/v1/incidents/:id/timeline      # Add timeline entry
POST   /api/v1/incidents/:id/ai-session    # Start AI debug session
GET    /api/v1/incidents/:id/runbook       # Get associated runbook

POST   /api/v1/incidents/:id/postmortem    # Generate postmortem
```

---

### 6. Observability Hub

Unified access to logs, metrics, and traces across all services.

#### Integrations

| System | Purpose | Integration |
|--------|---------|-------------|
| **Axiom** | Log aggregation | API for queries, deep links |
| **Prometheus** | Metrics | PromQL queries |
| **Grafana** | Dashboards | Embedded iframes, deep links |
| **Jaeger/Tempo** | Distributed tracing | Trace ID lookups |
| **CloudWatch** | AWS metrics/logs | API queries |

#### Features

1. **Unified search** — Query logs across all services from one interface
2. **Contextual logs** — When viewing an incident, auto-filter to relevant time/services
3. **Trace correlation** — Click on a log line to see full distributed trace
4. **Metric overlays** — View metrics alongside deployment events
5. **AI log analysis** — "Summarize errors in the last hour"

#### API Endpoints

```
POST   /api/v1/logs/query                  # Query logs (proxies to Axiom)
GET    /api/v1/logs/services/:id           # Logs for specific service
GET    /api/v1/logs/trace/:traceId         # Get trace details

GET    /api/v1/metrics/services/:id        # Key metrics for service
POST   /api/v1/metrics/query               # PromQL query

GET    /api/v1/observability/deeplink      # Generate deep link to external tool
```

---

### 7. AI Operations Console

The crown jewel — an embedded Claude Code terminal for AI-assisted operations.

#### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Apollo UI                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                  AI Console Component                      │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  xterm.js Terminal                                  │  │  │
│  │  │                                                     │  │  │
│  │  │  apollo> debug cobalt-prod core-service             │  │  │
│  │  │  🤖 Connecting to AI agent...                       │  │  │
│  │  │  🤖 Analyzing service health...                     │  │  │
│  │  │  📊 CPU: 45% | Memory: 62% | Error rate: 0.3%      │  │  │
│  │  │  📋 Last 5 errors:                                  │  │  │
│  │  │     - Connection pool exhausted (3x)                │  │  │
│  │  │     - Request timeout (2x)                          │  │  │
│  │  │  🔍 Root cause: HikariCP max-pool-size too low     │  │  │
│  │  │  💡 Recommendation: Increase pool size to 20       │  │  │
│  │  │                                                     │  │  │
│  │  │  apollo> apply recommendation                       │  │  │
│  │  │  🤖 Creating PR to update configuration...          │  │  │
│  │  │  ✅ PR #1234 created: https://github.com/...        │  │  │
│  │  │                                                     │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ WebSocket
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AI Agent Orchestrator                       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Session Manager                       │   │
│  │  • Session lifecycle (create, resume, terminate)        │   │
│  │  • User authentication & authorization                   │   │
│  │  • Rate limiting & quotas                               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Agent Runtime Pool                    │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │   │
│  │  │ Agent 1 │  │ Agent 2 │  │ Agent 3 │  │ Agent N │   │   │
│  │  │ Session │  │ Session │  │ Session │  │  (idle) │   │   │
│  │  │  #abc   │  │  #def   │  │  #ghi   │  │         │   │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Tool Registry                         │   │
│  │  • kubectl (scoped to allowed namespaces)               │   │
│  │  • aws cli (scoped IAM role)                            │   │
│  │  • gh cli (GitHub operations)                           │   │
│  │  • terraform (plan only, apply requires approval)       │   │
│  │  • Apollo API (internal operations)                     │   │
│  │  • Log queries (Axiom, CloudWatch)                      │   │
│  │  • Metrics queries (Prometheus)                         │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Anthropic API
                              ▼
                    ┌─────────────────┐
                    │   Claude API    │
                    │  (Opus / Sonnet)│
                    └─────────────────┘
```

#### Agent Capabilities

| Capability | Tools Available | Approval Required |
|------------|-----------------|-------------------|
| **Read operations** | kubectl get, logs, describe; AWS describe-*; log queries | No |
| **Analysis** | Metrics queries, cost analysis, dependency checks | No |
| **Safe mutations** | Scale replicas, restart pods, create PRs | No |
| **Config changes** | Update ConfigMaps, Secrets (non-prod) | No |
| **Prod mutations** | Deploy, scale prod, update prod secrets | Yes |
| **Infrastructure** | Terraform apply, cluster modifications | Yes (+ MFA) |

#### Context Injection

When starting an AI session, the agent receives context:

```typescript
interface AISessionContext {
  // User context
  user: {
    id: string;
    email: string;
    roles: string[];
    permissions: Permission[];
  };

  // Target context (if specified)
  target?: {
    type: 'service' | 'environment' | 'incident';
    service?: Service;
    environment?: Environment;
    incident?: Incident;
  };

  // Relevant runbooks
  runbooks: Runbook[];

  // Recent events
  recentDeployments: Deployment[];
  recentIncidents: Incident[];
  recentAlerts: Alert[];

  // Tool configuration
  tools: {
    kubectl: { contexts: string[]; namespaces: string[] };
    aws: { role: string; regions: string[] };
    github: { repos: string[]; permissions: string[] };
  };
}
```

#### System Prompt Template

```
You are an AI operations assistant for the Apollo platform. You help engineers
debug issues, perform deployments, and maintain infrastructure.

## Current Context
- User: {{user.email}} (roles: {{user.roles}})
- Target: {{target.type}} - {{target.name}}
- Environment: {{target.environment}}

## Available Tools
{{#each tools}}
- {{name}}: {{description}}
  Approval required: {{requiresApproval}}
{{/each}}

## Relevant Runbooks
{{#each runbooks}}
### {{title}}
Trigger: {{trigger}}
{{content}}
{{/each}}

## Guidelines
1. Always explain what you're about to do before doing it
2. For destructive operations, ask for confirmation
3. If an operation requires approval, request it through the approval flow
4. Log all actions to the audit trail
5. If you're unsure, ask clarifying questions
6. Prefer safe, reversible operations
7. For production issues, prioritize mitigation over root cause analysis

## Recent Context
- Last deployment: {{recentDeployments[0].service}} at {{recentDeployments[0].timestamp}}
- Active incidents: {{activeIncidents.length}}
- Recent alerts: {{recentAlerts | summarize}}
```

#### AI Commands

Built-in commands users can invoke:

| Command | Description |
|---------|-------------|
| `debug <env> <service>` | Analyze service health, recent errors, suggest fixes |
| `deploy <env> <service> <version>` | Deploy specific version with safety checks |
| `rollback <env> <service>` | Rollback to last known good version |
| `scale <env> <service> <replicas>` | Scale service replicas |
| `logs <env> <service> [--since=1h]` | Fetch and analyze recent logs |
| `costs <service>` | Analyze service costs and suggest optimizations |
| `upgrade <env> <service>` | Check for dependency updates, create upgrade PR |
| `incident <id>` | Load incident context, suggest remediation |
| `postmortem <incident-id>` | Generate postmortem from incident data |
| `explain <resource>` | Explain what a K8s resource does |

#### Safety Mechanisms

1. **Scoped credentials** — Each agent has minimal IAM/RBAC permissions
2. **Approval workflows** — Destructive ops require human approval
3. **Audit logging** — Every action logged with full context
4. **Rate limiting** — Prevent runaway automation
5. **Kill switch** — Admins can terminate any session instantly
6. **Sandbox mode** — New users start in read-only mode
7. **Action replay** — All actions can be replayed for review

#### API Endpoints

```
POST   /api/v1/ai/sessions                 # Start new AI session
GET    /api/v1/ai/sessions/:id             # Get session details
DELETE /api/v1/ai/sessions/:id             # Terminate session
POST   /api/v1/ai/sessions/:id/message     # Send message to agent
GET    /api/v1/ai/sessions/:id/stream      # WebSocket for streaming

POST   /api/v1/ai/sessions/:id/approve     # Approve pending action
POST   /api/v1/ai/sessions/:id/reject      # Reject pending action

GET    /api/v1/ai/sessions/active          # List active sessions
GET    /api/v1/ai/audit                    # AI action audit log
```

---

## Data Architecture

### Database Schema

```sql
-- PostgreSQL schema for Apollo

-- Service catalog
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    repository VARCHAR(500),
    team VARCHAR(100),
    tier VARCHAR(20) NOT NULL DEFAULT 'standard',
    language VARCHAR(50),
    framework VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES services(id),
    name VARCHAR(50) NOT NULL,
    cluster VARCHAR(100) NOT NULL,
    namespace VARCHAR(100) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(service_id, name)
);

-- Deployments
CREATE TABLE deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES services(id),
    environment_id UUID NOT NULL REFERENCES environments(id),
    image_tag VARCHAR(200) NOT NULL,
    git_commit VARCHAR(40),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    initiated_by VARCHAR(200) NOT NULL,
    initiated_via VARCHAR(50) NOT NULL, -- 'ui', 'api', 'ai', 'gitops'
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

-- Incidents
CREATE TABLE incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'triggered',
    source_type VARCHAR(50) NOT NULL,
    source_alert_id VARCHAR(200),
    affected_services UUID[] DEFAULT '{}',
    affected_environments VARCHAR(50)[] DEFAULT '{}',
    assignee VARCHAR(200),
    acknowledged_at TIMESTAMP,
    resolved_at TIMESTAMP,
    postmortem JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE incident_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES incidents(id),
    event_type VARCHAR(50) NOT NULL,
    actor VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- AI Sessions
CREATE TABLE ai_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(200) NOT NULL,
    context_type VARCHAR(50),
    context_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    model VARCHAR(50) NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

CREATE TABLE ai_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES ai_sessions(id),
    action_type VARCHAR(100) NOT NULL,
    tool_name VARCHAR(100) NOT NULL,
    input JSONB NOT NULL,
    output JSONB,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by VARCHAR(200),
    approved_at TIMESTAMP,
    executed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Audit log (append-only)
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor VARCHAR(200) NOT NULL,
    actor_type VARCHAR(20) NOT NULL, -- 'user', 'ai', 'system'
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(200),
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Cost data (populated from AWS Cost Explorer)
CREATE TABLE cost_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    environment VARCHAR(50) NOT NULL,
    service_id UUID REFERENCES services(id),
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(200),
    cost_usd DECIMAL(10, 4) NOT NULL,
    usage_quantity DECIMAL(20, 6),
    usage_unit VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    UNIQUE(date, environment, resource_type, resource_id)
);
```

### Caching Strategy

| Data | Cache | TTL | Invalidation |
|------|-------|-----|--------------|
| Service catalog | Redis | 5 min | On mutation |
| Health status | Redis | 30 sec | On health check |
| Cost data | Redis | 1 hour | On daily refresh |
| Log queries | None | - | Real-time |
| AI sessions | Redis | Session lifetime | On session end |

---

## Security Model

### Authentication

1. **SSO Integration** — SAML/OIDC with corporate IdP (Okta, Google Workspace, etc.)
2. **Service accounts** — API keys for CI/CD and automation
3. **MFA enforcement** — Required for production operations

### Authorization (RBAC)

```yaml
roles:
  viewer:
    description: Read-only access to all data
    permissions:
      - services:read
      - environments:read
      - deployments:read
      - incidents:read
      - costs:read
      - logs:read
      - ai:read

  developer:
    description: Can deploy to non-prod, start AI sessions
    inherits: viewer
    permissions:
      - deployments:create:non-prod
      - ai:sessions:create
      - ai:sessions:execute:safe

  operator:
    description: Can deploy to prod, manage incidents
    inherits: developer
    permissions:
      - deployments:create:prod
      - incidents:manage
      - ai:sessions:execute:dangerous

  admin:
    description: Full access including secrets and infrastructure
    inherits: operator
    permissions:
      - secrets:read
      - secrets:write
      - infrastructure:modify
      - ai:sessions:execute:all
      - users:manage
```

### Audit Requirements

All actions logged with:
- Timestamp
- Actor (user ID or service account)
- Action type
- Resource affected
- Request details
- Source IP
- User agent
- AI session ID (if applicable)

Audit logs are:
- Append-only (no deletions)
- Shipped to separate S3 bucket
- Retained for 7 years (compliance)

---

## Technology Choices

### Backend

| Component | Technology | Rationale |
|-----------|------------|-----------|
| API Server | **Go** | Performance, low latency for real-time ops |
| WebSocket Server | **Go** | Native goroutines for concurrent sessions |
| Task Queue | **Temporal** | Durable workflows for deployments |
| Database | **PostgreSQL** | JSONB for flexible schemas |
| Cache | **Redis** | Session state, rate limiting |
| Search | **Elasticsearch** | Full-text search on logs/services |

### Frontend

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Framework | **React 18** | Consistency with other apps |
| State | **Zustand** + **TanStack Query** | Existing pattern |
| Terminal | **xterm.js** | Industry standard web terminal |
| Charts | **Recharts** | Existing pattern |
| UI | **Blueprint.js** | Existing pattern |

### Infrastructure

| Component | Technology | Rationale |
|-----------|------------|-----------|
| Container | **EKS** | Existing infrastructure |
| CI/CD | **GitHub Actions** + **ArgoCD** | Existing pattern |
| Secrets | **AWS Secrets Manager** | Existing pattern |
| Monitoring | **Axiom** + **CloudWatch** | Existing pattern |

---

## Implementation Phases

### Phase 1: Foundation (4-6 weeks)

- [ ] Core API scaffolding (Go)
- [ ] Database schema and migrations
- [ ] Authentication (SSO integration)
- [ ] Basic UI shell
- [ ] Service catalog (manual registration)
- [ ] Health status aggregation

**Deliverable:** Can view all services and their health status

### Phase 2: Deployment Management (4-6 weeks)

- [ ] ArgoCD integration
- [ ] Deployment triggering
- [ ] Rollback functionality
- [ ] Deployment history
- [ ] Environment promotion

**Deliverable:** Can deploy any service to any environment from UI

### Phase 3: Observability & Incidents (4-6 weeks)

- [ ] Log query proxy (Axiom integration)
- [ ] Metrics dashboard
- [ ] PagerDuty integration
- [ ] Incident lifecycle management
- [ ] Runbook viewer

**Deliverable:** Can manage incidents end-to-end, view logs/metrics

### Phase 4: Secrets & Costs (3-4 weeks)

- [ ] Secrets Manager UI
- [ ] Secret rotation workflows
- [ ] AWS Cost Explorer integration
- [ ] Kubecost integration
- [ ] Cost allocation dashboard

**Deliverable:** Can manage secrets, view costs per service

### Phase 5: AI Operations Console (6-8 weeks)

- [ ] Agent runtime infrastructure
- [ ] WebSocket terminal streaming
- [ ] Tool registry and execution
- [ ] Approval workflow
- [ ] Audit logging
- [ ] Context injection
- [ ] Built-in commands

**Deliverable:** Full AI-assisted operations capability

### Phase 6: Polish & Scale (4-6 weeks)

- [ ] Performance optimization
- [ ] Advanced RBAC
- [ ] API rate limiting
- [ ] Documentation
- [ ] Onboarding flow
- [ ] Mobile-responsive UI

**Deliverable:** Production-ready platform

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **MTTR** (Mean Time to Resolve) | -50% | Incident resolution time |
| **Deployment frequency** | +100% | Deploys per week |
| **Failed deployment rate** | <5% | Rollbacks / total deploys |
| **Secret rotation compliance** | 100% | Secrets rotated on schedule |
| **AI session resolution rate** | >60% | Issues resolved via AI |
| **Cost visibility** | 100% | Services with cost attribution |
| **Platform adoption** | >80% | Engineers using Apollo weekly |

---

## Open Questions

1. **Multi-cloud support** — Do we need to support GCP/Azure, or AWS-only?
2. **On-prem deployments** — Will any customers need on-prem Apollo?
3. **White-labeling** — Should Apollo be brandable for different business units?
4. **AI model selection** — Opus for complex ops, Sonnet for simple queries?
5. **Approval escalation** — How to handle after-hours approval requests?

---

## Appendix A: Competitive Analysis

| Feature | Apollo | Backstage | Port | Cortex |
|---------|--------|-----------|------|--------|
| Service catalog | ✅ | ✅ | ✅ | ✅ |
| Deployment management | ✅ | Plugin | ✅ | ❌ |
| Secrets management | ✅ | Plugin | ❌ | ❌ |
| Cost tracking | ✅ | Plugin | ✅ | ✅ |
| Incident management | ✅ | Plugin | ✅ | ❌ |
| AI operations | ✅ | ❌ | ❌ | ❌ |
| Self-hosted | ✅ | ✅ | ❌ | ❌ |
| Customizable | ✅ | ✅ | Limited | Limited |

**Key differentiator:** AI Operations Console with Claude integration

---

## Appendix B: Example AI Session Transcript

```
User: debug cobalt-prod core-service

AI: I'll analyze the core-service in the cobalt-prod environment.

📊 **Service Health Overview**
- Status: Degraded
- Replicas: 2/2 running
- CPU: 78% (elevated)
- Memory: 65% (normal)
- Error rate: 2.3% (elevated, threshold: 1%)

📋 **Recent Errors (last 15 minutes)**
| Count | Error |
|-------|-------|
| 47 | `HikariPool-1 - Connection is not available, request timed out after 30000ms` |
| 12 | `SocketTimeoutException: Read timed out` |
| 3 | `PSQLException: FATAL: too many connections for role "cobalt"` |

🔍 **Analysis**
The connection pool is exhausted. Current HikariCP config:
- `maximum-pool-size`: 10
- `minimum-idle`: 5
- Active connections: 10/10

RDS metrics show 45 active connections across all services, approaching the
max_connections limit of 100.

💡 **Recommendations**
1. **Immediate**: Increase `maximum-pool-size` to 15 (safe headroom)
2. **Short-term**: Add connection pool metrics to alerting
3. **Long-term**: Consider RDS instance upgrade or connection pooler (PgBouncer)

Would you like me to:
1. Create a PR to increase the pool size
2. Scale up the service replicas temporarily
3. Show me the full connection pool metrics
4. Investigate the slow queries causing connection hold

User: 1

AI: I'll create a PR to increase the HikariCP pool size.

🔧 **Creating PR...**
- Repository: cobalt/cobalt
- Branch: fix/increase-hikari-pool-size
- Target: main

**Changes:**
```yaml
# backend/core-service/src/main/resources/application.yml
spring:
  datasource:
    hikari:
-     maximum-pool-size: ${HIKARI_MAX_POOL:10}
+     maximum-pool-size: ${HIKARI_MAX_POOL:15}
-     minimum-idle: ${HIKARI_MIN_IDLE:5}
+     minimum-idle: ${HIKARI_MIN_IDLE:7}
```

✅ **PR Created**: https://github.com/cobalt/cobalt/pull/1234

**Title**: fix(core): increase HikariCP pool size to address connection exhaustion

**Description**:
Increases the default connection pool size from 10 to 15 to address
connection exhaustion errors in production. Also increases minimum idle
connections to 7 for better responsiveness under load.

Related incident: INC-567

Would you like me to:
1. Request review from the on-call engineer
2. Enable auto-merge after CI passes
3. Deploy to staging first for validation

User: 2

AI: ✅ Auto-merge enabled for PR #1234

The PR will automatically merge once:
- CI checks pass (typically 8-10 minutes)
- No merge conflicts

After merge, ArgoCD will automatically deploy to production within 5 minutes.

I'll monitor the deployment. Would you like me to notify you when:
1. The PR is merged
2. The deployment completes
3. The error rate returns to normal

User: 3

AI: ✅ I'll monitor and notify you when the error rate returns to normal.

Setting up monitoring:
- Metric: `http_server_errors_total` for core-service
- Threshold: < 1% error rate
- Check interval: 1 minute
- Timeout: 30 minutes

You'll receive a notification in this session and via Slack (#incidents)
when the error rate normalizes.

Current status: 2.3% error rate
Target: < 1% error rate

Is there anything else you'd like me to investigate while we wait?
```

---

## Appendix C: Repository Structure

```
apollo/
├── cmd/
│   └── apollo/
│       └── main.go              # API server entrypoint
├── internal/
│   ├── api/
│   │   ├── handlers/            # HTTP handlers
│   │   ├── middleware/          # Auth, logging, etc.
│   │   └── routes.go
│   ├── services/
│   │   ├── catalog/             # Service catalog logic
│   │   ├── deploy/              # Deployment orchestration
│   │   ├── secrets/             # Secrets management
│   │   ├── costs/               # Cost tracking
│   │   ├── incidents/           # Incident management
│   │   ├── logs/                # Log aggregation proxy
│   │   └── ai/                  # AI agent orchestration
│   ├── integrations/
│   │   ├── argocd/
│   │   ├── aws/
│   │   ├── github/
│   │   ├── pagerduty/
│   │   └── axiom/
│   ├── models/                  # Database models
│   └── config/                  # Configuration loading
├── pkg/
│   ├── k8s/                     # Kubernetes client utilities
│   └── anthropic/               # Claude API client
├── migrations/                  # SQL migrations
├── web/                         # React frontend (separate build)
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── hooks/
│   │   └── stores/
│   └── package.json
├── deploy/
│   ├── docker/
│   ├── k8s/
│   └── terraform/
├── docs/
│   ├── api/                     # OpenAPI specs
│   ├── runbooks/
│   └── architecture/
├── Dockerfile
├── docker-compose.yml
├── Makefile
└── README.md
```
