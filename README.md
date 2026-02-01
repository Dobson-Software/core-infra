# Cobalt Platform

Multi-tenant business management platform for HVAC and plumbing professionals. Provides job scheduling, CRM, invoicing, permit tracking, NYC DOB violations monitoring, and notifications.

## Prerequisites

- Docker & Docker Compose
- Java 21+ (for local backend development)
- Node.js 20+ with pnpm 8+ (for local frontend development)
- PostgreSQL 15+ (managed by Docker Compose)

## Quick Start

```bash
# Clone the repository
git clone <repo-url> cobalt
cd cobalt

# Start all services
docker compose up

# Services available at:
# - Frontend:             http://localhost:3000
# - API Gateway (nginx):  http://localhost:80
# - Core Service:         http://localhost:8080
# - Notification Service: http://localhost:8081
# - Violations Service:   http://localhost:8082
# - MailHog UI:           http://localhost:8025
```

## Demo Credentials

| Role | Email | Password |
|---|---|---|
| Admin | admin@demo.com | password123 |
| Manager | manager@demo.com | password123 |
| Technician | tech@demo.com | password123 |

## Development

### Backend

```bash
cd backend
./gradlew build          # Build all services
./gradlew test           # Run unit tests
./gradlew integrationTest # Run integration tests (requires Docker)
```

### Frontend

```bash
cd frontend
pnpm install             # Install dependencies
pnpm dev                 # Start dev server (port 3000)
pnpm build               # Production build
pnpm test:run            # Run unit tests
pnpm test:e2e            # Run E2E tests (requires running backend)
```

## Architecture

| Service | Port | Purpose |
|---|---|---|
| core-service | 8080 | Jobs, scheduling, CRM, invoicing, auth |
| notification-service | 8081 | Email/SMS delivery, templates |
| violations-service | 8082 | NYC DOB violations monitoring |
| web | 3000 | React frontend application |

## Infrastructure

Production deployment uses AWS (EKS, RDS, ElastiCache, S3, CloudFront). See `infrastructure/terraform/` for IaC configuration.

```bash
cd infrastructure/terraform/environments/dev
terraform init && terraform apply
```

## Testing

- **Backend**: JUnit 5 + TestContainers (no mocks)
- **Frontend Unit**: Vitest + Testing Library + MSW
- **Frontend E2E**: Playwright
- **Coverage**: 80% overall, 95% service layer

## Nightly AI Audit

An automated pipeline audits the codebase every night at 3 AM UTC using Claude, creates GitHub Issues for findings, and can auto-fix approved issues.

### How It Works

```
3 AM UTC                              Morning                        On Label
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────────┐
│ Audit (Opus) │→ │Verify (Sonnet)│→ │Create Issues │→ │You review│→ │Claude: fix + │
│ 30 turns     │  │ 20 turns     │  │ (gh CLI)     │  │& approve │  │self-review PR│
└──────────────┘  └──────────────┘  └──────────────┘  └──────────┘  └──────────────┘
```

1. **Audit**: Claude (Opus) scans the codebase across 5 categories — roadmap compliance, testing gaps, code quality, security, and architecture.
2. **Verify**: Claude (Sonnet) independently reads each referenced file to eliminate hallucinated findings.
3. **Create Issues**: A bash job deduplicates against existing issues and creates up to 10 GitHub Issues per run with labels (`audit-finding`, category, severity, effort).
4. **Review**: You review issues labeled `audit-finding` each morning. Close false positives, apply the `audit-approved` label to real findings.
5. **Auto-fix**: The `audit-approved` label triggers Claude (Opus) to implement the fix with a 3-pass self-review (correctness, standards, completeness), then opens a PR that must pass the quality gate.

### Audit Categories

| Category | What It Checks | Severity |
|----------|---------------|----------|
| Roadmap | `[DONE]` features have all implementation artifacts listed in `ROADMAP.md` | high |
| Testing | Every service/repo/controller/component/hook has a corresponding test file | high-medium |
| Quality | tenant_id, no mocks, MapStruct, @Transactional, no TS `any`, RFC 7807, audit fields | critical-medium |
| Security | No hardcoded secrets, @Valid, auth on endpoints, no SQL injection | critical-high |
| Architecture | No business logic in controllers, no direct repo calls from controllers | medium |

### Configuration

Audit rules, severity thresholds, and issue creation settings are in `audit/audit-config.yml`. Model choices and turn limits for cost control are also configured there.

The product roadmap (`ROADMAP.md`) is machine-readable — the audit verifies that files listed under `[DONE]` features actually exist on disk.

### Manual Trigger

```bash
# Run the audit manually
gh workflow run nightly-audit.yml

# Check findings
gh issue list --label audit-finding

# Approve a finding for auto-fix
gh issue edit <number> --add-label audit-approved

# Check generated PRs
gh pr list --label audit-fix
```

### Setup

The workflows require an `ANTHROPIC_API_KEY` secret in your GitHub repository settings. See the [API key setup](#api-key-setup) section below.

### Cost Estimate

| Component | Model | Frequency | Est. Cost |
|-----------|-------|-----------|-----------|
| Audit job | Opus | Nightly | ~$3-6/run |
| Verify job | Sonnet | Nightly | ~$0.50-1.50/run |
| Issue creation | gh CLI | Nightly | $0 |
| Fix implementation | Opus | Per approved issue | ~$4-8/fix |

Monthly: ~$120-250 (nightly audits + ~10 fixes/month).

## API Key Setup

The nightly audit and auto-fix workflows use the Anthropic API via `claude-code-action`. You need to add an `ANTHROPIC_API_KEY` secret to your GitHub repository.

### Creating a Dedicated API Key

1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Navigate to **Settings** > **API Keys**
3. Click **Create Key**
4. Name it something identifiable (e.g. `cobalt-github-actions-audit`)
5. Copy the key (it starts with `sk-ant-`)

### Adding the Secret to GitHub

```bash
# Via CLI (recommended — avoids key in browser history)
gh secret set ANTHROPIC_API_KEY
# Paste the key when prompted

# Or via GitHub UI:
# Repo → Settings → Secrets and variables → Actions → New repository secret
# Name: ANTHROPIC_API_KEY
# Value: sk-ant-...
```

### Cost Controls

To limit spend, the Anthropic console provides:

- **Spend limits**: Set a monthly budget under **Settings** > **Limits** (e.g. $300/month)
- **Rate limits**: Default tier rate limits apply; the nightly audit runs once per day so this is not a concern
- **Usage tracking**: Monitor daily spend under **Settings** > **Usage**

There is no way to create a key scoped to specific models or with a per-key spend cap — all keys in a workspace share the same limits. If you want hard isolation, create a separate Anthropic workspace dedicated to CI/CD and set a spend limit on that workspace.

### Disabling the Audit

To temporarily stop the nightly audit without removing the key:

```bash
# Disable the workflow
gh workflow disable nightly-audit.yml

# Re-enable later
gh workflow enable nightly-audit.yml
```
