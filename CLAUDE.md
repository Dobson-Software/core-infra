# Core Infrastructure — Coding Guidelines & Architecture Reference

## Project Overview

**Core Infrastructure** is a shared repository containing platform-level services and reusable modules for the Dobson Software ecosystem. The primary project is **Solomon**, an internal Platform Control Plane for managing deployments, services, costs, and incidents across all infrastructure.

### Projects
| Project | Language | Purpose |
|---|---|---|
| `solomon/` | Go 1.22+ / React 18+ | Platform Control Plane with AI-powered debugging |

---

## Tech Stack

### Solomon Backend (Go)
- **Language**: Go 1.22+ (use generics, error wrapping, context propagation)
- **Framework**: Chi router with middleware
- **Database**: PostgreSQL 15+ with golang-migrate
- **Cache**: Redis 7+ with go-redis
- **Auth**: JWT + OIDC
- **API Style**: REST with URL versioning (`/api/v1/...`)
- **Testing**: Go testing + testcontainers-go
- **Code Quality**: golangci-lint, gofmt

### Solomon Frontend (React)
- **Language**: TypeScript 5.x (strict mode, no `any`)
- **Framework**: React 18+ with functional components only
- **Build**: Vite 5.x with pnpm
- **UI Library**: Blueprint.js 5.x
- **State Management**: Zustand (client state), TanStack Query v5 (server state)
- **Terminal**: xterm.js for AI Console
- **Charts**: Recharts
- **Testing**: Vitest (unit), Playwright (E2E)
- **Code Quality**: ESLint flat config, Prettier

### Infrastructure
- **Container**: Docker with multi-stage builds
- **Orchestration**: Docker Compose (dev), Kubernetes/EKS (prod)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Gateway**: Nginx (dev), AWS ALB (prod)

---

## API Design Principles

### URL Structure
```
/api/v1/{resource}          — collection
/api/v1/{resource}/{id}     — single resource
/api/v1/{resource}/{id}/{sub-resource}  — nested resource
```

### Standard Response Envelope
```json
{
  "data": { },
  "meta": {
    "timestamp": "2025-01-01T00:00:00Z",
    "requestId": "uuid"
  }
}
```

### Pagination (cursor-based preferred, offset supported)
```json
{
  "data": [],
  "pagination": {
    "page": 0,
    "size": 20,
    "totalElements": 150,
    "totalPages": 8
  }
}
```

### Error Responses (RFC 7807)
```json
{
  "type": "https://solomon.internal/errors/validation",
  "title": "Validation Failed",
  "status": 400,
  "detail": "The request body contains invalid fields",
  "instance": "/api/v1/services",
  "errors": [
    { "field": "name", "message": "name is required" }
  ]
}
```

### HTTP Status Codes
| Code | Usage |
|---|---|
| 200 | Successful GET, PUT, PATCH |
| 201 | Successful POST (resource created) |
| 204 | Successful DELETE |
| 400 | Validation error |
| 401 | Authentication required |
| 403 | Insufficient permissions |
| 404 | Resource not found |
| 409 | Conflict (duplicate, version mismatch) |
| 422 | Business rule violation |
| 500 | Internal server error |

---

## Go Backend Patterns

### Service Layer
```go
type CatalogService struct {
    db     *pgxpool.Pool
    redis  *redis.Client
    logger *slog.Logger
}

func NewCatalogService(db *pgxpool.Pool, redis *redis.Client, logger *slog.Logger) *CatalogService {
    return &CatalogService{db: db, redis: redis, logger: logger}
}

func (s *CatalogService) GetService(ctx context.Context, id uuid.UUID) (*models.Service, error) {
    var svc models.Service
    err := s.db.QueryRow(ctx, `
        SELECT id, name, display_name, description, repository, team, tier,
               language, framework, metadata, created_at, updated_at
        FROM services WHERE id = $1
    `, id).Scan(
        &svc.ID, &svc.Name, &svc.DisplayName, &svc.Description, &svc.Repository,
        &svc.Team, &svc.Tier, &svc.Language, &svc.Framework, &svc.Metadata,
        &svc.CreatedAt, &svc.UpdatedAt,
    )
    if err != nil {
        if errors.Is(err, pgx.ErrNoRows) {
            return nil, ErrNotFound
        }
        return nil, fmt.Errorf("query service: %w", err)
    }
    return &svc, nil
}
```

### Handler Layer
```go
func (h *Handlers) GetService(w http.ResponseWriter, r *http.Request) {
    id, err := uuid.Parse(chi.URLParam(r, "id"))
    if err != nil {
        h.respondError(w, r, http.StatusBadRequest, "invalid service ID")
        return
    }

    svc, err := h.catalog.GetService(r.Context(), id)
    if err != nil {
        if errors.Is(err, catalog.ErrNotFound) {
            h.respondError(w, r, http.StatusNotFound, "service not found")
            return
        }
        h.logger.Error("failed to get service", "error", err)
        h.respondError(w, r, http.StatusInternalServerError, "internal error")
        return
    }

    h.respondJSON(w, r, http.StatusOK, svc)
}
```

### Middleware Pattern
```go
func AuthMiddleware(jwtSecret string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            token := extractToken(r)
            claims, err := validateToken(token, jwtSecret)
            if err != nil {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }
            ctx := context.WithValue(r.Context(), userContextKey, claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

### Error Handling
```go
var (
    ErrNotFound     = errors.New("not found")
    ErrConflict     = errors.New("conflict")
    ErrUnauthorized = errors.New("unauthorized")
)

// Always wrap errors with context
if err != nil {
    return fmt.Errorf("create service %s: %w", name, err)
}
```

---

## Frontend Patterns

### TanStack Query Hooks
```typescript
// hooks/useServices.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { servicesApi } from '../api';

export const serviceKeys = {
  all: ['services'] as const,
  lists: () => [...serviceKeys.all, 'list'] as const,
  list: (filters: ServiceFilters) => [...serviceKeys.lists(), filters] as const,
  details: () => [...serviceKeys.all, 'detail'] as const,
  detail: (id: string) => [...serviceKeys.details(), id] as const,
};

export function useServices(filters: ServiceFilters) {
  return useQuery({
    queryKey: serviceKeys.list(filters),
    queryFn: () => servicesApi.getServices(filters),
  });
}

export function useService(id: string) {
  return useQuery({
    queryKey: serviceKeys.detail(id),
    queryFn: () => servicesApi.getService(id),
    enabled: !!id,
  });
}
```

### Zustand Store (Client State Only)
```typescript
// stores/useAppStore.ts
import { create } from 'zustand';

interface AppState {
  sidebarCollapsed: boolean;
  activeSessionId: string | null;
  toggleSidebar: () => void;
  setActiveSessionId: (id: string | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  sidebarCollapsed: false,
  activeSessionId: null,
  toggleSidebar: () => set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),
  setActiveSessionId: (id) => set({ activeSessionId: id }),
}));
```

### Component Pattern
```typescript
// components/ServiceCard.tsx
import { Card, Tag, Text } from '@blueprintjs/core';
import type { Service } from '../types';

interface ServiceCardProps {
  service: Service;
  onSelect: (id: string) => void;
}

export function ServiceCard({ service, onSelect }: ServiceCardProps) {
  return (
    <Card interactive onClick={() => onSelect(service.id)}>
      <Text tagName="h4">{service.displayName}</Text>
      <Tag intent={tierIntent(service.tier)}>{service.tier}</Tag>
      <Text>{service.team}</Text>
    </Card>
  );
}
```

---

## Testing Requirements

### CRITICAL: NO-MOCK POLICY

**NEVER use mocking libraries.** This is enforced by:
1. Pre-commit hooks that scan for mock imports
2. ESLint rules that flag mock usage
3. golangci-lint custom rules
4. CI/CD pipeline checks

#### What is banned:

**Go:**
- `gomock`, `mockgen`, `testify/mock`
- Any `*Mock*` struct patterns for interfaces
- `monkey` patching libraries

**TypeScript/JavaScript:**
- `jest.mock()`, `jest.spyOn()`, `vi.mock()`, `vi.spyOn()`
- `jest.fn()`, `vi.fn()`
- Any mocking library or framework

#### What to use instead:
| Instead of | Use |
|---|---|
| `mock database` | testcontainers-go PostgreSQL |
| `mock redis` | testcontainers-go Redis |
| `mock HTTP client` | httptest.Server or WireMock |
| `jest.mock(fetch)` | MSW (Mock Service Worker) for API boundaries only |

### Go Testing
```go
func TestCatalogService_GetService(t *testing.T) {
    // Use testcontainers for real database
    ctx := context.Background()
    postgres, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image:        "postgres:15-alpine",
            ExposedPorts: []string{"5432/tcp"},
            Env: map[string]string{
                "POSTGRES_DB":       "test",
                "POSTGRES_USER":     "test",
                "POSTGRES_PASSWORD": "test",
            },
            WaitingFor: wait.ForListeningPort("5432/tcp"),
        },
        Started: true,
    })
    require.NoError(t, err)
    defer postgres.Terminate(ctx)

    // Run actual test with real database
    db := connectToContainer(t, postgres)
    svc := NewCatalogService(db, nil, slog.Default())

    // Test real behavior
    created, err := svc.CreateService(ctx, &models.Service{Name: "test-svc"})
    require.NoError(t, err)

    fetched, err := svc.GetService(ctx, created.ID)
    require.NoError(t, err)
    assert.Equal(t, "test-svc", fetched.Name)
}
```

### Frontend Unit Testing (Vitest)
```typescript
// __tests__/ServiceCard.test.tsx
import { render, screen } from '@testing-library/react';
import { ServiceCard } from '../ServiceCard';

describe('ServiceCard', () => {
  it('renders service name and tier', () => {
    const service = {
      id: '1',
      displayName: 'Payment Service',
      tier: 'critical',
      team: 'payments',
    };

    render(<ServiceCard service={service} onSelect={() => {}} />);

    expect(screen.getByText('Payment Service')).toBeInTheDocument();
    expect(screen.getByText('critical')).toBeInTheDocument();
  });
});
```

### Coverage Requirements
| Scope | Minimum |
|---|---|
| Go overall | 80% |
| Go service layer | 90% |
| Frontend components | 80% |
| E2E critical paths | 100% of happy paths |

---

## File Organization

### Solomon
```
solomon/
├── cmd/solomon/
│   └── main.go              # Entrypoint
├── internal/
│   ├── api/
│   │   ├── server.go        # Router setup
│   │   ├── handlers/        # HTTP handlers
│   │   └── middleware/      # Auth, logging, CORS
│   ├── config/
│   │   └── config.go        # Configuration with Viper
│   ├── models/
│   │   └── models.go        # Data models
│   └── services/
│       ├── catalog/         # Service catalog
│       ├── deploy/          # Deployment management
│       ├── incidents/       # Incident management
│       ├── costs/           # Cost tracking
│       ├── secrets/         # Secrets management
│       └── ai/              # AI session management
├── pkg/
│   ├── k8s/                 # Kubernetes client utilities
│   └── claude/              # Claude API client
├── migrations/              # golang-migrate SQL files
├── web/                     # React frontend
│   ├── src/
│   │   ├── api/             # API client
│   │   ├── components/      # Shared components
│   │   ├── pages/           # Page components
│   │   ├── hooks/           # TanStack Query hooks
│   │   ├── stores/          # Zustand stores
│   │   └── types/           # TypeScript types
│   └── package.json
├── Dockerfile
├── docker-compose.yml
├── config.yaml
├── Makefile
└── README.md
```

---

## Review Criteria

### Every PR must:
1. Include database migration scripts (no manual DDL)
2. Have integration tests using testcontainers (no mocks)
3. Follow REST conventions with proper status codes
4. Handle errors with RFC 7807 responses
5. Include frontend tests (unit + E2E for new flows)
6. Pass golangci-lint, ESLint, and TypeScript strict checks
7. Meet coverage thresholds (80% overall, 90% service layer)
8. Not introduce any mock imports or spy patterns

### Implementation Checklist (for every feature)
- [ ] Database migration created
- [ ] Go service with error handling
- [ ] HTTP handler with proper status codes
- [ ] Integration tests (testcontainers)
- [ ] API client function
- [ ] TanStack Query hook
- [ ] React component
- [ ] E2E test for critical path
- [ ] All lint/type checks pass

---

## Solomon Domain Entities

### Service Catalog
- `Service` — registered service (name, repository, team, tier, language, framework)
- `Environment` — deployment target (name, cluster, namespace, config)
- `Dependency` — service dependency (type: runtime, build, optional)
- `Runbook` — operational runbook (title, trigger, content, AI prompt)

### Deployments
- `Deployment` — deployment record (service, environment, image tag, status, initiator)
- `DeploymentStatus` — enum: pending, in_progress, succeeded, failed, rolled_back

### Incidents
- `Incident` — incident record (title, severity, status, affected services)
- `IncidentTimeline` — timeline event (type, actor, content)
- `IncidentSeverity` — enum: critical, high, medium, low
- `IncidentStatus` — enum: triggered, acknowledged, investigating, identified, monitoring, resolved

### AI Sessions
- `AISession` — AI console session (user, context, status, model)
- `AIAction` — tool execution record (tool, input, output, approval status)
- `AIActionStatus` — enum: pending, approved, rejected, executed, failed

### Cost Tracking
- `CostRecord` — daily cost record (date, environment, service, resource, cost)

### Audit
- `AuditLog` — immutable audit entry (actor, action, resource, details)

---

## Environment Variables

### Solomon Backend
```
SOLOMON_SERVER_PORT=8080
SOLOMON_DATABASE_HOST=localhost
SOLOMON_DATABASE_PORT=5432
SOLOMON_DATABASE_USER=solomon
SOLOMON_DATABASE_PASSWORD=solomon_dev
SOLOMON_DATABASE_DATABASE=solomon
SOLOMON_REDIS_HOST=localhost
SOLOMON_REDIS_PORT=6379
SOLOMON_AUTH_JWT_SECRET=<base64-encoded-secret>
SOLOMON_AUTH_OIDC_ISSUER=https://auth.example.com
SOLOMON_ANTHROPIC_API_KEY=<api-key>
SOLOMON_ARGOCD_SERVER_URL=https://argocd.example.com
SOLOMON_PAGERDUTY_API_KEY=<api-key>
SOLOMON_AWS_REGION=us-east-1
```

### Solomon Frontend
```
VITE_API_BASE_URL=http://localhost:8080
```

---

## Git Conventions

### Branch Naming
```
feature/{ticket}-{short-description}
bugfix/{ticket}-{short-description}
hotfix/{ticket}-{short-description}
```

### Commit Messages
```
feat(solomon): add service catalog endpoint
fix(solomon): handle nil pointer in deployment status
refactor(solomon): extract AI tool registry
test(solomon): add integration tests for incidents
docs: update API documentation
chore: upgrade Go to 1.22
```

### PR Title Format
```
feat(solomon): add service catalog endpoint
```

---

## Security Testing

### Tools & Thresholds

| Tool | Scope | Threshold | Suppressions |
|---|---|---|---|
| Trivy (fs) | Go deps, frontend deps | CRITICAL,HIGH | `.trivyignore` |
| Trivy (image) | Docker images | CRITICAL,HIGH | `.trivyignore` |
| gosec | Go security scan | High severity | Inline comments |
| TruffleHog | Secrets in git history | Verified only | N/A |
| Checkov | Terraform IaC | Default rules | Inline `#checkov:skip` |

### Local Commands
```bash
# Go security scan
cd solomon && golangci-lint run --enable gosec ./...

# Trivy filesystem scan
trivy fs --severity CRITICAL,HIGH ./solomon

# TruffleHog secret scan
trufflehog git file://. --only-verified

# Terraform format check
cd infrastructure/terraform && terraform fmt -check -recursive
```

---

## Quick Start

```bash
# Start infrastructure
cd solomon
docker-compose -f docker-compose.dev.yml up -d

# Run migrations
DATABASE_URL="postgres://solomon:solomon_dev@localhost:5434/solomon?sslmode=disable" make migrate-up

# Start backend
make run

# In another terminal, start frontend
make web-install
make web-dev
```

The API will be at `http://localhost:8080` and web UI at `http://localhost:3000`.
