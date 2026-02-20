# Solomon Platform Control Plane — MVP Implementation

## Overview

Solomon is a well-architected skeleton with complete routing, models, and database schema, but **zero business logic**. All service methods are TODOs and handlers return empty responses. This plan implements the core functionality to make Solomon a functional MVP.

## Current State

| Component | Status |
|---|---|
| Database schema | ✅ Complete (10+ tables with proper indexes) |
| API routing | ✅ Complete (50+ endpoints defined) |
| Models | ✅ Complete (all domain entities) |
| Config system | ✅ Complete (8 integrations configured) |
| Service implementations | ❌ All stubbed (0%) |
| API handlers | ❌ All return empty JSON |
| Frontend UI | ✅ Complete (11 pages) |
| Frontend-Backend integration | ❌ Not connected |

## MVP Scope

Focus on making the **Service Catalog** and **AI Console** functional first — these are the core value propositions.

### Phase 1: Database Layer (Service Catalog)

Implement CRUD operations for the Catalog Service.

**Files to modify:**
- `internal/services/catalog/service.go` — Implement all methods

**Methods to implement:**
```go
func (s *CatalogService) List(ctx context.Context, filters ServiceFilters) ([]models.Service, error)
func (s *CatalogService) Get(ctx context.Context, id uuid.UUID) (*models.Service, error)
func (s *CatalogService) GetByName(ctx context.Context, name string) (*models.Service, error)
func (s *CatalogService) Create(ctx context.Context, svc *models.Service) error
func (s *CatalogService) Update(ctx context.Context, svc *models.Service) error
func (s *CatalogService) Delete(ctx context.Context, id uuid.UUID) error
func (s *CatalogService) ListEnvironments(ctx context.Context, serviceID uuid.UUID) ([]models.Environment, error)
func (s *CatalogService) GetDependencies(ctx context.Context, serviceID uuid.UUID) ([]models.Dependency, error)
func (s *CatalogService) ListRunbooks(ctx context.Context, serviceID uuid.UUID) ([]models.Runbook, error)
```

### Phase 2: API Handlers (Service Catalog)

Wire up handlers to call the catalog service.

**Files to modify:**
- `internal/api/handlers/handlers.go` — Implement catalog handlers

**Endpoints:**
- `GET /api/v1/services` — List services with filtering
- `POST /api/v1/services` — Create service
- `GET /api/v1/services/{id}` — Get service by ID
- `PUT /api/v1/services/{id}` — Update service
- `DELETE /api/v1/services/{id}` — Delete service
- `GET /api/v1/services/{id}/environments` — List environments
- `GET /api/v1/services/{id}/runbooks` — List runbooks

### Phase 3: Dashboard Stats

Implement dashboard aggregation queries.

**Files to modify:**
- `internal/services/catalog/service.go` — Add GetHealth method
- `internal/api/handlers/handlers.go` — Implement dashboard handlers

**Endpoints:**
- `GET /api/v1/dashboard/stats` — Aggregate stats
- `GET /api/v1/dashboard/service-health` — Service health status
- `GET /api/v1/dashboard/recent-deployments` — Recent deployments
- `GET /api/v1/dashboard/active-incidents` — Active incidents

### Phase 4: Claude API Integration

Implement the AI Console with real Claude API calls.

**Files to modify:**
- `internal/services/ai/session.go` — Line 211: Replace placeholder with actual Claude API
- `pkg/claude/client.go` — New file: Claude API client

**Implementation:**
1. Create Claude API client using Anthropic SDK patterns
2. Implement tool execution framework
3. Add WebSocket streaming for real-time responses
4. Implement tool approval workflow

### Phase 5: Basic Integrations

Implement minimal integration stubs that return mock data.

**ArgoCD (deployment sync):**
- `internal/integrations/argocd/client.go` — Implement GetApplication, SyncApplication

**AWS (cost data):**
- `internal/integrations/aws/costs.go` — Implement GetCostAndUsage

---

## Implementation Order

1. **Catalog Service** (Phase 1) — Core CRUD, enables service management
2. **Catalog Handlers** (Phase 2) — API endpoints for frontend
3. **Dashboard** (Phase 3) — Makes homepage functional
4. **AI Integration** (Phase 4) — Core differentiator
5. **Integrations** (Phase 5) — External system connectivity

---

## Files Summary

| Phase | File | Changes |
|---|---|---|
| 1 | `internal/services/catalog/service.go` | Implement 9 methods with pgx queries |
| 2 | `internal/api/handlers/handlers.go` | Implement 7 catalog handlers |
| 3 | `internal/api/handlers/handlers.go` | Implement 4 dashboard handlers |
| 4 | `internal/services/ai/session.go` | Claude API integration |
| 4 | `pkg/claude/client.go` | New Claude API client |
| 5 | `internal/integrations/argocd/client.go` | ArgoCD API calls |
| 5 | `internal/integrations/aws/costs.go` | AWS Cost Explorer |

---

## Verification

1. **Backend compiles:** `cd solomon && go build ./...`
2. **Start services:** `docker-compose up -d && make run`
3. **Test Catalog API:**
   ```bash
   # Create service
   curl -X POST http://localhost:8080/api/v1/services \
     -H "Content-Type: application/json" \
     -d '{"name":"test-svc","displayName":"Test Service","tier":"standard"}'

   # List services
   curl http://localhost:8080/api/v1/services

   # Get dashboard stats
   curl http://localhost:8080/api/v1/dashboard/stats
   ```
4. **Frontend loads data:** Open http://localhost:3000, verify Services page shows data
5. **AI Console:** Start session, verify Claude responds (requires ANTHROPIC_API_KEY)

---

## Scope Decision

**Implementing Phase 1-3** (Service Catalog + Dashboard).

For integrations (Claude, ArgoCD, AWS): Build the infrastructure and leave TODOs where credentials are needed. No mocking — real implementations that gracefully handle missing credentials.

---

## Detailed Implementation

### Phase 1: Catalog Service (`internal/services/catalog/service.go`)

```go
// Add pgxpool dependency
type CatalogService struct {
    db     *pgxpool.Pool
    logger *slog.Logger
}

// Implement each method with real SQL queries
// Example: List services with optional filters
func (s *CatalogService) List(ctx context.Context, filters ServiceFilters) ([]models.Service, error) {
    query := `SELECT id, name, display_name, description, repository, team, tier,
                     language, framework, metadata, created_at, updated_at
              FROM services WHERE 1=1`
    // Add filter clauses dynamically
    // Return scanned results
}
```

### Phase 2: Catalog Handlers (`internal/api/handlers/handlers.go`)

```go
// Replace stub with real implementation
func (h *Handlers) ListServices(w http.ResponseWriter, r *http.Request) {
    filters := parseServiceFilters(r)
    services, err := h.catalog.List(r.Context(), filters)
    if err != nil {
        h.respondError(w, r, http.StatusInternalServerError, err.Error())
        return
    }
    h.respondJSON(w, r, http.StatusOK, map[string]interface{}{
        "data": services,
        "pagination": pagination,
    })
}
```

### Phase 3: Dashboard Handlers

```go
func (h *Handlers) GetDashboardStats(w http.ResponseWriter, r *http.Request) {
    // Aggregate queries:
    // - COUNT(*) FROM services
    // - COUNT(*) FROM services WHERE health = 'healthy'
    // - COUNT(*) FROM deployments WHERE status = 'in_progress'
    // - COUNT(*) FROM incidents WHERE status != 'resolved'
    // - AVG time to resolve from incidents
    // - SUM(cost_usd) FROM cost_records WHERE date >= now() - 30 days
}
```
