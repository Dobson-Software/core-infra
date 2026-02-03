# Solomon — Platform Control Plane

Solomon is an internal platform control plane for managing deployments, services, costs, and incidents across your infrastructure. It provides a unified interface with AI-powered debugging capabilities.

## Features

- **Service Catalog** — Register and manage services with environments, dependencies, and runbooks
- **Deployments** — Track and trigger deployments across environments via ArgoCD integration
- **Incident Management** — PagerDuty integration with timeline tracking and AI-assisted debugging
- **Cost Explorer** — AWS Cost Explorer integration with per-service cost attribution
- **AI Console** — Claude-powered terminal for debugging, deployments, and runbook execution
- **Audit Log** — Comprehensive logging of all actions (user, AI, and system)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Solomon Web UI                              │
│                    (React + Blueprint.js + xterm.js)                │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Solomon API Server                           │
│                          (Go + Chi Router)                          │
├──────────────┬──────────────┬──────────────┬───────────────────────┤
│   Catalog    │   Deploy     │   Incidents  │        AI             │
│   Service    │   Service    │   Service    │      Service          │
└──────────────┴──────────────┴──────────────┴───────────────────────┘
         │              │              │                │
         ▼              ▼              ▼                ▼
┌──────────────┬──────────────┬──────────────┬───────────────────────┐
│  PostgreSQL  │   ArgoCD     │  PagerDuty   │     Anthropic         │
│              │   GitHub     │              │     (Claude)          │
│              │   AWS        │              │                       │
└──────────────┴──────────────┴──────────────┴───────────────────────┘
```

## Prerequisites

- Go 1.22+
- Node.js 20+ and pnpm
- Docker and Docker Compose
- PostgreSQL 15+ (or use Docker)
- Redis 7+ (or use Docker)

## Quick Start

```bash
# Start infrastructure
docker-compose up -d postgres redis

# Run database migrations
make migrate-up

# Start the API server
make run

# In another terminal, start the web UI
make web-install
make web-dev
```

The API will be available at `http://localhost:8080` and the web UI at `http://localhost:3000`.

## Configuration

Configuration is loaded from `config.yaml` with environment variable overrides.

| Variable | Description | Default |
|---|---|---|
| `SOLOMON_SERVER_PORT` | API server port | 8080 |
| `SOLOMON_DATABASE_HOST` | PostgreSQL host | localhost |
| `SOLOMON_DATABASE_PORT` | PostgreSQL port | 5432 |
| `SOLOMON_REDIS_HOST` | Redis host | localhost |
| `SOLOMON_REDIS_PORT` | Redis port | 6379 |
| `SOLOMON_AUTH_JWT_SECRET` | JWT signing secret | (required) |
| `SOLOMON_AUTH_OIDC_ISSUER` | OIDC issuer URL | (optional) |
| `SOLOMON_ANTHROPIC_API_KEY` | Anthropic API key | (required for AI) |
| `SOLOMON_ARGOCD_SERVER_URL` | ArgoCD server URL | (optional) |
| `SOLOMON_PAGERDUTY_API_KEY` | PagerDuty API key | (optional) |
| `SOLOMON_AWS_REGION` | AWS region | us-east-1 |

## Development

```bash
# Run tests
make test

# Run linter
make lint

# Build binary
make build

# Create a new migration
make migrate-create

# Build Docker image
make docker-build
```

## API Endpoints

### Services
- `GET /api/v1/services` — List services
- `POST /api/v1/services` — Create service
- `GET /api/v1/services/:id` — Get service
- `PUT /api/v1/services/:id` — Update service
- `DELETE /api/v1/services/:id` — Delete service
- `GET /api/v1/services/:id/environments` — List environments
- `GET /api/v1/services/:id/runbooks` — List runbooks

### Deployments
- `GET /api/v1/deployments` — List deployments
- `POST /api/v1/deployments` — Trigger deployment
- `GET /api/v1/deployments/:id` — Get deployment
- `POST /api/v1/deployments/:id/rollback` — Rollback deployment

### Incidents
- `GET /api/v1/incidents` — List incidents
- `POST /api/v1/incidents` — Create incident
- `GET /api/v1/incidents/:id` — Get incident
- `POST /api/v1/incidents/:id/acknowledge` — Acknowledge
- `POST /api/v1/incidents/:id/resolve` — Resolve
- `GET /api/v1/incidents/:id/timeline` — Get timeline

### AI Sessions
- `GET /api/v1/ai/sessions` — List sessions
- `POST /api/v1/ai/sessions` — Create session
- `GET /api/v1/ai/sessions/:id` — Get session
- `POST /api/v1/ai/sessions/:id/end` — End session
- `WS /ws/ai/:sessionId` — WebSocket for streaming

### Costs
- `GET /api/v1/costs/summary` — Cost summary
- `GET /api/v1/costs/trend` — Cost trend
- `GET /api/v1/costs/by-service` — Costs by service
- `POST /api/v1/costs/sync` — Trigger cost sync

## AI Console Tools

The AI Console provides Claude with access to the following tools:

| Tool | Description | Requires Approval |
|---|---|---|
| `kubectl_get` | Get Kubernetes resources | No |
| `kubectl_describe` | Describe Kubernetes resources | No |
| `kubectl_logs` | View pod logs | No |
| `kubectl_exec` | Execute commands in pods | Yes |
| `kubectl_apply` | Apply Kubernetes manifests | Yes |
| `kubectl_delete` | Delete Kubernetes resources | Yes |
| `kubectl_scale` | Scale deployments | Yes |
| `argocd_sync` | Sync ArgoCD application | Yes |
| `argocd_rollback` | Rollback ArgoCD application | Yes |
| `github_pr` | Create/merge pull requests | Yes |
| `aws_logs` | Query CloudWatch logs | No |
| `aws_describe` | Describe AWS resources | No |
| `runbook_execute` | Execute a runbook | Yes |

## Deployment

### Docker

```bash
docker build -t solomon:latest .
docker run -p 8080:8080 \
  -e SOLOMON_DATABASE_HOST=postgres \
  -e SOLOMON_AUTH_JWT_SECRET=your-secret \
  solomon:latest
```

### Kubernetes

See the `deploy/k8s/` directory for Kubernetes manifests.

## License

Internal use only.
