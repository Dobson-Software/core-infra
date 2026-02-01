# Core-Infra Template

A production-ready template for building and deploying multi-tenant business applications.

## What's Included

- **Backend**: Java 21 / Spring Boot 3.4.x monorepo with 3 services (core, notification, violations)
- **Frontend**: React 18+ / TypeScript / Vite monorepo with Blueprint.js UI
- **Database**: PostgreSQL 15+ with Flyway migrations, per-service schemas
- **Cache**: Redis 7+
- **Infrastructure**: Terraform modules for AWS (EKS, RDS, ElastiCache, S3, ECR, CloudFront, WAF)
- **CI/CD**: GitHub Actions workflows for build, test, deploy, security scanning
- **Kubernetes**: Full K8s manifests (deployments, services, ingress, monitoring, network policies)
- **Security**: OWASP, Trivy, Checkov, TruffleHog scanning built into CI

## Getting Started

### 1. Create Your Repository

Click **"Use this template"** on GitHub, or:

```bash
gh repo create your-org/your-project --template Dobson-Software/core-infra --public
git clone https://github.com/your-org/your-project.git
cd your-project
```

### 2. Rename the Project

Run the rename script to replace all "cobalt" references with your project name:

```bash
./scripts/rename-project.sh <project-name> <org-name>
```

- `project-name`: Lowercase kebab-case (e.g. `acme-hvac`). Used for Docker containers, npm scope, Terraform resources, K8s namespaces.
- `org-name`: Lowercase single word (e.g. `acme`). Used for Java packages (`com.<org-name>`).

Example:
```bash
./scripts/rename-project.sh acme-hvac acme
```

### 3. Regenerate Frontend Lock File

```bash
cd frontend
rm pnpm-lock.yaml
pnpm install
cd ..
```

### 4. Verify the Rename

```bash
# Backend
cd backend && ./gradlew build

# Frontend
cd frontend && pnpm build
```

### 5. Configure GitHub Actions Secrets

Set these secrets in your repository settings:

| Secret | Description |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | IAM role ARN for GitHub Actions OIDC deployment |
| `INFRACOST_API_KEY` | Infracost API key for cost estimation |
| `SLACK_WEBHOOK_URL` | (Optional) Slack webhook for deployment notifications |

### 6. Configure AWS Infrastructure

Update Terraform variables for your AWS environment:

```bash
cd infrastructure/terraform/environments/dev
```

Edit `main.tf` and `backend.tf`:
- Set your AWS account ID
- Set your desired AWS region
- Set your S3 backend bucket for Terraform state
- Set your domain name in the DNS module

### 7. Configure Domain Names

Update these locations with your actual domain:
- `infrastructure/terraform/modules/dns-and-tls/` — Route53 hosted zone and ACM certificates
- `.github/workflows/deploy.yml` — deployment target URLs
- `infrastructure/terraform/k8s/ingress/ingress-rules.yaml` — ALB ingress host rules

## Project Structure

```
.
├── backend/                  # Java Spring Boot services
│   ├── platform-common/      # Shared security, DTOs, exceptions
│   ├── core-service/         # Jobs, scheduling, CRM, invoicing
│   ├── notification-service/ # Email/SMS delivery
│   └── violations-service/   # NYC DOB violations sync
├── frontend/                 # React/TypeScript monorepo
│   ├── apps/web/             # Main web application
│   └── packages/             # Shared UI and API client
├── infrastructure/
│   └── terraform/
│       ├── environments/     # Dev and prod configs
│       ├── modules/          # Reusable Terraform modules
│       └── k8s/              # Kubernetes manifests
├── .github/workflows/        # CI/CD pipelines
├── nginx/                    # Dev reverse proxy config
├── runbooks/                 # Operational runbooks
└── scripts/                  # Utility scripts
```

## Local Development

```bash
# Start all services (requires Docker)
docker compose up

# Default ports:
#   Frontend:             http://localhost:3000
#   Core Service API:     http://localhost:8080
#   Notification Service: http://localhost:8081
#   Violations Service:   http://localhost:8082
#   MailHog UI:           http://localhost:8025
```

## Key Conventions

- **Multi-tenancy**: Every table has `tenant_id`, every query is tenant-scoped
- **No mocking**: Tests use TestContainers, GreenMail, WireMock, and MSW
- **MapStruct**: All object mapping is compile-time via MapStruct
- **RFC 7807**: Error responses follow the Problem Details standard
- **REST versioning**: URL-based (`/api/v1/...`)

See `CLAUDE.md` for the full architecture reference and coding guidelines.
