# Cobalt Platform — Coding Guidelines & Architecture Reference

## Project Overview

**Cobalt** is a multi-tenant business management platform for HVAC and plumbing professionals. It provides job scheduling, customer relationship management, invoicing, permit tracking, NYC DOB violations monitoring, and notification capabilities.

### Core Architecture
- **Backend**: Java 21 / Spring Boot 3.4.x monorepo with 3 services
- **Frontend**: React 18+ / TypeScript / Vite monorepo with 1 app
- **Database**: PostgreSQL 15+ with per-service schemas
- **Cache**: Redis 7+
- **Infrastructure**: AWS (EKS, RDS, ElastiCache, S3, ECR)

### Services
| Service | Port | Schema | Purpose |
|---|---|---|---|
| `core-service` | 8080 | `core` | Jobs, scheduling, CRM, invoicing, estimates |
| `notification-service` | 8081 | `notification` | Email/SMS delivery, templates, preferences |
| `violations-service` | 8082 | `violations` | NYC DOB violations data via Socrata OData API |

### Frontend Apps
| App | Port | Purpose |
|---|---|---|
| `web` | 3000 | Business management app for HVAC/plumbing professionals |

---

## Tech Stack

### Backend
- **Language**: Java 21 (use records, sealed interfaces, pattern matching, text blocks)
- **Framework**: Spring Boot 3.4.x with Spring Security, Spring Data JPA
- **Build**: Gradle 8.x with Kotlin DSL
- **Database**: PostgreSQL 15+ with Flyway migrations
- **Mapping**: MapStruct 1.5.x (compile-time, never runtime reflection)
- **Auth**: JWT (access + refresh tokens)
- **API Style**: REST with URL versioning (`/api/v1/...`)
- **Testing**: JUnit 5, TestContainers, Spring Boot Test, GreenMail
- **Code Quality**: Checkstyle, JaCoCo (80% overall, 95% service layer)

### Frontend
- **Language**: TypeScript 5.x (strict mode, no `any`)
- **Framework**: React 18+ with functional components only
- **Build**: Vite 5.x with pnpm workspaces and Turborepo
- **UI Library**: Blueprint.js 5.x
- **State Management**: Zustand (client state), TanStack Query v5 (server state)
- **Routing**: React Router v6
- **Charts**: Recharts
- **DnD**: dnd-kit
- **Testing**: Vitest (unit), Playwright (E2E)
- **Code Quality**: ESLint flat config, Prettier

### Infrastructure
- **Container**: Docker with multi-stage builds
- **Orchestration**: Docker Compose (dev), Kubernetes/EKS (prod)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Gateway**: Nginx (dev), AWS ALB (prod)

---

## Multi-Tenancy Requirements

### CRITICAL: Every feature MUST be tenant-scoped

1. **Every table** has a `tenant_id UUID NOT NULL` column
2. **Every query** includes `WHERE tenant_id = :tenantId`
3. **Every API endpoint** resolves tenant from JWT claims
4. **Every test** creates and uses a specific tenant context
5. **No data leakage** — cross-tenant access is a security vulnerability

### Tenant Resolution
```java
// Extract from JWT in SecurityContext
UUID tenantId = SecurityContextHelper.getCurrentTenantId();

// Pass to repository methods
@Query("SELECT j FROM Job j WHERE j.tenantId = :tenantId AND j.id = :id")
Optional<Job> findByTenantIdAndId(@Param("tenantId") UUID tenantId, @Param("id") UUID id);
```

### Database Pattern
```sql
CREATE TABLE core.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    -- domain columns...
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by UUID,
    updated_by UUID
);

CREATE INDEX idx_jobs_tenant ON core.jobs(tenant_id);
```

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
  "type": "https://cobalt.com/errors/validation",
  "title": "Validation Failed",
  "status": 400,
  "detail": "The request body contains invalid fields",
  "instance": "/api/v1/jobs",
  "errors": [
    { "field": "scheduledDate", "message": "must be a future date" }
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

## HVAC/Plumbing Supplier Integration

### Strategy: Abstraction Layer
HVAC/plumbing parts suppliers do not yet have standardized APIs. Cobalt implements an abstraction layer to support future integrations.

### PartsSupplierService Pattern
```java
public interface PartsSupplierService {
    List<PartSearchResult> searchParts(PartSearchCriteria criteria);
    Optional<PartDetails> getPartDetails(String partNumber, String supplierCode);
    PartAvailability checkAvailability(String partNumber, String supplierCode, String zipCode);
    PurchaseOrder submitOrder(OrderRequest request);
    OrderStatus getOrderStatus(String orderId, String supplierCode);
}

// Current implementation: manual catalog / CSV import
@Service
@Profile("default")
public class ManualPartsSupplierService implements PartsSupplierService {
    // Uses local catalog database
}

// Future: supplier-specific implementations
@Service
@Profile("supplier-fergusons")
public class FergusonsPartsSupplierService implements PartsSupplierService {
    // API integration when available
}
```

### Supplier Domain Entities
- `Part` — catalog item (partNumber, description, category, manufacturer)
- `PartCategory` — HVAC/plumbing classification (enum: COMPRESSOR, CONDENSER, VALVE, PIPE_FITTING, etc.)
- `PartAvailability` — stock status, lead time, warehouse location
- `PurchaseOrder` — order placed with supplier
- `SupplierCatalog` — imported catalog data (CSV, manual entry)

---

## NYC DOB Violations Integration

### Socrata Open Data API (SODA)
The violations-service syncs and serves NYC Department of Buildings violation data.

### API Endpoints
- **SODA JSON**: `https://data.cityofnewyork.us/resource/3h2n-5cm9.json`
- **OData v4**: `https://data.cityofnewyork.us/api/odata/v4/3h2n-5cm9`

### Key Fields
| Field | Description |
|---|---|
| `isn_dob_bis_viol` | Unique violation ID |
| `boro` | Borough code |
| `bin` | Building identification number |
| `block` | Tax block |
| `lot` | Tax lot |
| `issue_date` | Date violation issued |
| `violation_type_code` | Type classification |
| `violation_number` | Violation number |
| `house_number` | Street number |
| `street` | Street name |
| `disposition_date` | Resolution date |
| `disposition_comments` | Resolution details |
| `device_number` | Associated device |
| `description` | Violation description |
| `ecb_number` | ECB case number |
| `number` | Internal number |
| `violation_category` | Category classification |
| `violation_type` | Detailed type |

### Pagination
- **SODA**: `$limit` + `$offset` (default 1000, max 50000 per request)
- **OData**: `$top` + `$skip`

### Sync Strategy
```java
@Scheduled(cron = "0 0 2 * * *")  // Daily at 2 AM
public void syncViolations() {
    // 1. Get last sync timestamp
    // 2. Fetch violations modified since last sync
    // 3. Upsert into local database
    // 4. Update sync metadata
}
```

### Filtering (SoQL)
```
$where=boro='MANHATTAN' AND issue_date > '2024-01-01'
$where=bin='1234567'
$where=violation_type='PLUMBING' OR violation_type='BOILER'
```

---

## Backend Patterns

### Service Layer
```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class JobService {
    private final JobRepository jobRepository;
    private final JobMapper jobMapper;
    private final EventPublisher eventPublisher;

    public JobResponse getJob(UUID tenantId, UUID jobId) {
        Job job = jobRepository.findByTenantIdAndId(tenantId, jobId)
            .orElseThrow(() -> new ResourceNotFoundException("Job", jobId));
        return jobMapper.toResponse(job);
    }

    @Transactional
    public JobResponse createJob(UUID tenantId, CreateJobRequest request) {
        Job job = jobMapper.toEntity(request);
        job.setTenantId(tenantId);
        job = jobRepository.save(job);
        eventPublisher.publish(new JobCreatedEvent(job));
        return jobMapper.toResponse(job);
    }
}
```

### Controller Layer
```java
@RestController
@RequestMapping("/api/v1/jobs")
@RequiredArgsConstructor
public class JobController {
    private final JobService jobService;

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<JobResponse>> getJob(@PathVariable UUID id) {
        UUID tenantId = SecurityContextHelper.getCurrentTenantId();
        JobResponse job = jobService.getJob(tenantId, id);
        return ResponseEntity.ok(ApiResponse.of(job));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<JobResponse>> createJob(
            @Valid @RequestBody CreateJobRequest request) {
        UUID tenantId = SecurityContextHelper.getCurrentTenantId();
        JobResponse job = jobService.createJob(tenantId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.of(job));
    }
}
```

### Repository Layer
```java
public interface JobRepository extends JpaRepository<Job, UUID> {
    Optional<Job> findByTenantIdAndId(UUID tenantId, UUID id);

    Page<Job> findByTenantIdAndStatus(UUID tenantId, JobStatus status, Pageable pageable);

    @Query("""
        SELECT j FROM Job j
        WHERE j.tenantId = :tenantId
        AND j.scheduledDate BETWEEN :start AND :end
        ORDER BY j.scheduledDate ASC
        """)
    List<Job> findScheduledJobs(
        @Param("tenantId") UUID tenantId,
        @Param("start") LocalDateTime start,
        @Param("end") LocalDateTime end
    );
}
```

### Entity Pattern
```java
@Entity
@Table(name = "jobs", schema = "core")
@Getter @Setter
@NoArgsConstructor
public class Job {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "tenant_id", nullable = false)
    private UUID tenantId;

    @Column(nullable = false)
    private String title;

    @Column(length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private JobStatus status;

    @Column(name = "scheduled_date")
    private LocalDateTime scheduledDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

### MapStruct Mapper
```java
@Mapper(componentModel = "spring")
public interface JobMapper {
    JobResponse toResponse(Job job);
    Job toEntity(CreateJobRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntity(UpdateJobRequest request, @MappingTarget Job job);
}
```

### Flyway Migrations
```
backend/{service}/src/main/resources/db/migration/
  V1__create_initial_schema.sql
  V2__add_indexes.sql
  V3__add_audit_fields.sql
```

Naming: `V{version}__{description}.sql` (double underscore)

---

## Frontend Patterns

### TanStack Query Hooks
```typescript
// hooks/useJobs.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { jobsApi } from '@cobalt/api-client';

export const jobKeys = {
  all: ['jobs'] as const,
  lists: () => [...jobKeys.all, 'list'] as const,
  list: (filters: JobFilters) => [...jobKeys.lists(), filters] as const,
  details: () => [...jobKeys.all, 'detail'] as const,
  detail: (id: string) => [...jobKeys.details(), id] as const,
};

export function useJobs(filters: JobFilters) {
  return useQuery({
    queryKey: jobKeys.list(filters),
    queryFn: () => jobsApi.getJobs(filters),
  });
}

export function useJob(id: string) {
  return useQuery({
    queryKey: jobKeys.detail(id),
    queryFn: () => jobsApi.getJob(id),
    enabled: !!id,
  });
}

export function useCreateJob() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: jobsApi.createJob,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: jobKeys.lists() });
    },
  });
}
```

### Zustand Store (Client State Only)
```typescript
// stores/useAppStore.ts
import { create } from 'zustand';

interface AppState {
  sidebarOpen: boolean;
  selectedDate: Date | null;
  toggleSidebar: () => void;
  setSelectedDate: (date: Date | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  sidebarOpen: true,
  selectedDate: null,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
  setSelectedDate: (date) => set({ selectedDate: date }),
}));
```

### API Client
```typescript
// packages/api-client/src/jobs.ts
import { apiClient } from './client';
import type { Job, CreateJobRequest, PaginatedResponse } from './types';

export const jobsApi = {
  getJobs: (filters: JobFilters): Promise<PaginatedResponse<Job>> =>
    apiClient.get('/api/v1/jobs', { params: filters }),

  getJob: (id: string): Promise<Job> =>
    apiClient.get(`/api/v1/jobs/${id}`),

  createJob: (data: CreateJobRequest): Promise<Job> =>
    apiClient.post('/api/v1/jobs', data),

  updateJob: (id: string, data: UpdateJobRequest): Promise<Job> =>
    apiClient.put(`/api/v1/jobs/${id}`, data),

  deleteJob: (id: string): Promise<void> =>
    apiClient.delete(`/api/v1/jobs/${id}`),
};
```

### Component Pattern
```typescript
// components/JobCard.tsx
import { Card, Tag, Text } from '@blueprintjs/core';
import type { Job } from '@cobalt/api-client';

interface JobCardProps {
  job: Job;
  onSelect: (id: string) => void;
}

export function JobCard({ job, onSelect }: JobCardProps) {
  return (
    <Card interactive onClick={() => onSelect(job.id)}>
      <Text tagName="h4">{job.title}</Text>
      <Tag intent={statusIntent(job.status)}>{job.status}</Tag>
      <Text>{job.customerName}</Text>
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
3. Gradle tasks that fail builds on mock detection
4. CI/CD pipeline checks

#### What is banned:
- `Mockito`, `@Mock`, `@MockBean`, `@SpyBean`, `mock()`, `when()`, `verify()`
- `jest.mock()`, `jest.spyOn()`, `vi.mock()`, `vi.spyOn()`
- Any mocking library or framework

#### What to use instead:
| Instead of | Use |
|---|---|
| `@MockBean DataSource` | TestContainers PostgreSQL |
| `@MockBean MailSender` | GreenMail test server |
| `@MockBean RedisTemplate` | TestContainers Redis |
| `jest.mock(fetch)` | MSW (Mock Service Worker) for API boundaries only |
| `@MockBean ExternalApi` | WireMock for HTTP contract testing |

### Backend Testing
```java
@SpringBootTest
@Testcontainers
class JobServiceIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");

    @Test
    void createJob_withValidData_createsAndReturnsJob() {
        // Given: real database, real service, real mapper
        CreateJobRequest request = new CreateJobRequest(
            "HVAC Repair", "Replace compressor unit", LocalDateTime.now().plusDays(1)
        );

        // When
        JobResponse response = jobService.createJob(tenantId, request);

        // Then
        assertThat(response.title()).isEqualTo("HVAC Repair");
        assertThat(jobRepository.findByTenantIdAndId(tenantId, response.id())).isPresent();
    }
}
```

### Frontend Unit Testing (Vitest)
```typescript
// __tests__/JobCard.test.tsx
import { render, screen } from '@testing-library/react';
import { JobCard } from '../JobCard';

describe('JobCard', () => {
  it('renders job title and status', () => {
    const job = {
      id: '1',
      title: 'HVAC Repair',
      status: 'SCHEDULED',
      customerName: 'John Smith',
    };

    render(<JobCard job={job} onSelect={() => {}} />);

    expect(screen.getByText('HVAC Repair')).toBeInTheDocument();
    expect(screen.getByText('SCHEDULED')).toBeInTheDocument();
  });
});
```

### Frontend E2E Testing (Playwright)
```typescript
// e2e/jobs.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Job Management', () => {
  test('should create a new job', async ({ page }) => {
    await page.goto('/jobs/new');
    await page.fill('[name="title"]', 'Boiler Inspection');
    await page.fill('[name="description"]', 'Annual boiler inspection');
    await page.click('button[type="submit"]');
    await expect(page.getByText('Boiler Inspection')).toBeVisible();
  });
});
```

### Coverage Requirements
| Scope | Minimum |
|---|---|
| Overall (backend) | 80% |
| Service layer | 95% |
| Frontend components | 80% |
| E2E critical paths | 100% of happy paths |

---

## File Organization

### Backend
```
backend/
  settings.gradle.kts
  build.gradle.kts
  platform-common/
    build.gradle.kts
    src/main/java/com/cobalt/common/
      config/          — shared Spring configs
      dto/             — shared DTOs (ApiResponse, PagedResponse)
      entity/          — base entities (BaseAuditEntity)
      exception/       — global exception handling
      security/        — JWT, SecurityContextHelper
  core-service/
    build.gradle.kts
    src/main/java/com/cobalt/core/
      config/          — service-specific config
      controller/      — REST controllers
      dto/             — request/response DTOs
      entity/          — JPA entities
      mapper/          — MapStruct mappers
      repository/      — Spring Data repositories
      service/         — business logic
      event/           — domain events
    src/main/resources/
      application.yml
      db/migration/    — Flyway migrations
    src/test/java/com/cobalt/core/
      integration/     — TestContainers integration tests
      controller/      — WebMvcTest controller tests
  notification-service/
    build.gradle.kts
    src/main/java/com/cobalt/notification/
      (same structure as core-service)
  violations-service/
    build.gradle.kts
    src/main/java/com/cobalt/violations/
      (same structure + sync/ for Socrata sync logic)
  config/
    checkstyle/
      checkstyle.xml
  init-db.sql
```

### Frontend
```
frontend/
  package.json         — root workspace config
  pnpm-workspace.yaml
  turbo.json
  eslint.config.js
  .prettierrc
  playwright.config.ts
  .env.example
  apps/
    web/
      package.json
      vite.config.ts
      index.html
      src/
        main.tsx
        App.tsx
        components/    — shared UI components
        features/      — feature modules
          jobs/        — job management
          schedule/    — calendar/scheduling
          customers/   — CRM
          invoices/    — invoicing
          violations/  — DOB violations viewer
        hooks/         — TanStack Query hooks
        stores/        — Zustand stores
        layouts/       — page layouts
        routes/        — route definitions
        utils/         — utility functions
      e2e/             — Playwright tests
  packages/
    ui/
      package.json
      src/             — shared Blueprint.js components
    api-client/
      package.json
      src/             — typed API client
```

---

## Review Criteria

### Every PR must:
1. Have tenant_id on all new tables and queries
2. Include migration scripts (no manual DDL)
3. Have integration tests using TestContainers (no mocks)
4. Follow REST conventions with proper status codes
5. Use MapStruct for all object mapping
6. Handle errors with RFC 7807 responses
7. Include frontend tests (unit + E2E for new flows)
8. Pass Checkstyle, ESLint, and TypeScript strict checks
9. Meet coverage thresholds (80% overall, 95% service)
10. Not introduce any mock imports or spy patterns

### Implementation Checklist (for every feature)
- [ ] Database migration created
- [ ] Entity with tenant_id and audit fields
- [ ] Repository with tenant-scoped queries
- [ ] Service with business logic
- [ ] MapStruct mapper
- [ ] REST controller with proper status codes
- [ ] Integration tests (TestContainers)
- [ ] API client function
- [ ] TanStack Query hook
- [ ] React component
- [ ] E2E test for critical path
- [ ] All lint/type checks pass

---

## Domain Entities Reference

### Core Service
- `Tenant` — business (company name, address, subscription)
- `User` — team member (name, email, role, tenant_id)
- `Customer` — client/property owner (name, phone, email, addresses)
- `Job` — service job (title, description, status, scheduled_date, assigned_to)
- `JobStatus` — enum: DRAFT, SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
- `Estimate` — price estimate (line items, labor, materials, tax)
- `Invoice` — billing document (line items, payment status, due date)
- `Payment` — payment record (amount, method, stripe_payment_id)
- `ServiceAddress` — job location (address, access notes, property type)
- `Equipment` — tracked equipment at location (make, model, serial, install date)
- `Part` — parts catalog entry (number, description, category, price)
- `PartCategory` — enum: COMPRESSOR, CONDENSER, EVAPORATOR, THERMOSTAT, VALVE, PIPE_FITTING, PUMP, BOILER_PART, FILTER, DUCTWORK, OTHER
- `Attachment` — file upload (S3 key, filename, content type)

### Notification Service
- `NotificationTemplate` — template (type, subject, body, variables)
- `NotificationLog` — sent notification (recipient, channel, status, sent_at)
- `NotificationPreference` — user preference (channel, frequency, opt-out)

### Violations Service
- `DobViolation` — synced violation record (all Socrata fields)
- `ViolationSync` — sync metadata (last_sync, records_processed, status)
- `ViolationWatch` — user-configured watch (BIN, address, or area filter)
- `ViolationAlert` — alert generated for watched violations

---

## Environment Variables

### Backend (per service)
```
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/cobalt
SPRING_DATASOURCE_USERNAME=cobalt
SPRING_DATASOURCE_PASSWORD=cobalt_dev
SPRING_REDIS_HOST=localhost
SPRING_REDIS_PORT=6379
JWT_SECRET=<base64-encoded-secret>
JWT_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=86400000
```

### Core Service Specific
```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=+1...
AWS_S3_BUCKET=cobalt-uploads
```

### Violations Service Specific
```
SOCRATA_APP_TOKEN=<app-token>
SOCRATA_BASE_URL=https://data.cityofnewyork.us
SOCRATA_DATASET_ID=3h2n-5cm9
SYNC_CRON=0 0 2 * * *
```

### Frontend
```
VITE_API_BASE_URL=http://localhost:8080
VITE_VIOLATIONS_API_URL=http://localhost:8082
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_...
VITE_WS_URL=ws://localhost:8080/ws
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
feat(core): add job scheduling endpoint
fix(violations): handle null disposition dates in sync
refactor(web): extract JobCard component
test(core): add integration tests for invoice service
docs: update API documentation
chore: upgrade Spring Boot to 3.4.1
```

### PR Title Format
```
[COBALT-123] feat(core): add job scheduling endpoint
```

---

## Demo Environment

### Credentials
| Role | Email | Password |
|---|---|---|
| Admin | admin@demo.com | password123 |
| Manager | manager@demo.com | password123 |
| Technician | tech@demo.com | password123 |

### Quick Start
```bash
# Start all services
docker compose up

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@demo.com","password":"password123"}'
```

### Reset Demo Data
Demo data is seeded automatically on first boot by `DemoDataSeeder`. To reset:
```bash
docker compose down -v  # removes volumes
docker compose up       # fresh start with new seed data
```

---

## Terraform Deployment

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0
- kubectl configured

### Deploy to Dev
```bash
cd infrastructure/terraform/environments/dev
terraform init
terraform plan -var="db_password=<secure-password>"
terraform apply -var="db_password=<secure-password>"
```

### Deploy to Prod
```bash
cd infrastructure/terraform/environments/prod
terraform init
terraform plan -var="db_password=<secure-password>"
terraform apply -var="db_password=<secure-password>"
```

### Post-Deploy
1. Update kubeconfig: `aws eks update-kubeconfig --name cobalt-<env> --region us-east-1`
2. Apply K8s manifests: `kubectl apply -f infrastructure/terraform/k8s/`
3. Verify: `kubectl get pods -n cobalt-services`

---

## RBAC Roles and Permissions

| Feature | ADMIN | MANAGER | TECHNICIAN |
|---|---|---|---|
| View Dashboard | Yes | Yes | Yes |
| Manage Jobs | Full CRUD | Full CRUD | View + Update assigned |
| Manage Customers | Full CRUD | Full CRUD | View only |
| Manage Estimates | Full CRUD | Full CRUD | View only |
| Manage Invoices | Full CRUD | Full CRUD | No access |
| View Revenue | Yes | Yes | No |
| Manage Users | Full CRUD | View only | No access |
| Manage Settings | Full access | View only | No access |
| View Violations | Yes | Yes | Yes |
| Manage Watches | Full CRUD | Full CRUD | Own only |

---

## Security Testing

### Tools & Thresholds

| Tool | Scope | Threshold | Suppressions |
|---|---|---|---|
| Trivy (fs) | Backend/frontend deps | CRITICAL,HIGH | `.trivyignore` |
| Trivy (image) | Docker images | CRITICAL,HIGH | `.trivyignore` |
| OWASP Dependency-Check | Java CVEs | CVSS >= 7.0 | `backend/config/owasp-suppressions.xml` |
| Checkov | Terraform IaC | Default rules | Inline `#checkov:skip` |
| TruffleHog | Secrets in git history | Verified only | N/A |
| TFLint | Terraform (AWS ruleset) | All rules | `.tflint.hcl` |
| Terraform test | Module plan assertions | All pass | N/A |

### Local Commands
```bash
# OWASP scan
cd backend && ./gradlew dependencyCheckAggregate

# Trivy filesystem scan
trivy fs --severity CRITICAL,HIGH ./backend

# Checkov IaC scan
checkov -d infrastructure/terraform

# TruffleHog secret scan
trufflehog git file://. --only-verified

# Terraform format check
cd infrastructure/terraform && terraform fmt -check -recursive

# Terraform validate
cd infrastructure/terraform/environments/dev && terraform init -backend=false && terraform validate

# Terraform module tests
cd infrastructure/terraform/modules/networking && terraform init -backend=false && terraform test
```
