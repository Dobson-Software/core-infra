# Cobalt Platform Roadmap

Machine-readable product roadmap. The nightly audit verifies that features marked `[DONE]` have all listed implementation artifacts.

Status tags: `[DONE]`, `[IN PROGRESS]`, `[PLANNED]`, `[BACKLOG]`

---

## Authentication & Authorization `[DONE]`

- [x] JWT access + refresh token flow
- [x] User registration and login
- [x] Tenant-scoped authentication
- [x] Role-based access control (ADMIN, MANAGER, TECHNICIAN)
- [x] Rate limiting and security filters
- [x] Demo data seeder

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Migration | `backend/core-service/src/main/resources/db/migration/V1__create_core_schema.sql` | Done |
| Migration | `backend/core-service/src/main/resources/db/migration/V3__add_global_email_unique.sql` | Done |
| Entity — Tenant | `backend/core-service/src/main/java/com/cobalt/core/entity/Tenant.java` | Done |
| Entity — User | `backend/core-service/src/main/java/com/cobalt/core/entity/User.java` | Done |
| Repo — TenantRepository | `backend/core-service/src/main/java/com/cobalt/core/repository/TenantRepository.java` | Done |
| Repo — UserRepository | `backend/core-service/src/main/java/com/cobalt/core/repository/UserRepository.java` | Done |
| Service — AuthService | `backend/core-service/src/main/java/com/cobalt/core/service/AuthService.java` | Done |
| Controller — AuthController | `backend/core-service/src/main/java/com/cobalt/core/controller/AuthController.java` | Done |
| DTO — LoginRequest | `backend/core-service/src/main/java/com/cobalt/core/dto/auth/LoginRequest.java` | Done |
| DTO — RegisterRequest | `backend/core-service/src/main/java/com/cobalt/core/dto/auth/RegisterRequest.java` | Done |
| DTO — RefreshRequest | `backend/core-service/src/main/java/com/cobalt/core/dto/auth/RefreshRequest.java` | Done |
| DTO — AuthResponse | `backend/core-service/src/main/java/com/cobalt/core/dto/auth/AuthResponse.java` | Done |
| Config — DemoDataSeeder | `backend/core-service/src/main/java/com/cobalt/core/config/DemoDataSeeder.java` | Done |
| Config — SecurityConfig | `backend/platform-common/src/main/java/com/cobalt/common/config/SecurityConfig.java` | Done |
| Security — JwtAuthFilter | `backend/platform-common/src/main/java/com/cobalt/common/security/JwtAuthenticationFilter.java` | Done |
| Security — RateLimitFilter | `backend/platform-common/src/main/java/com/cobalt/common/security/RateLimitFilter.java` | Done |
| Test — AuthServiceIntegration | `backend/core-service/src/test/java/com/cobalt/core/service/AuthServiceIntegrationTest.java` | Done |
| Test — AuthIntegration | `backend/core-service/src/test/java/com/cobalt/core/integration/AuthIntegrationTest.java` | Done |
| Test — TenantRepoIntegration | `backend/core-service/src/test/java/com/cobalt/core/repository/TenantRepositoryIntegrationTest.java` | Done |
| Test — UserRepoIntegration | `backend/core-service/src/test/java/com/cobalt/core/repository/UserRepositoryIntegrationTest.java` | Done |
| Test — JwtTokenProvider | `backend/platform-common/src/test/java/com/cobalt/common/security/JwtTokenProviderTest.java` | Done |
| Test — SecurityContextHelper | `backend/platform-common/src/test/java/com/cobalt/common/security/SecurityContextHelperTest.java` | Done |
| Test — RateLimitFilter | `backend/platform-common/src/test/java/com/cobalt/common/security/RateLimitFilterIntegrationTest.java` | Done |
| Frontend — LoginPage | `frontend/apps/web/src/pages/LoginPage.tsx` | Done |
| Frontend — RegisterPage | `frontend/apps/web/src/pages/RegisterPage.tsx` | Done |
| Frontend — AuthProvider | `frontend/apps/web/src/auth/AuthProvider.tsx` | Done |
| Frontend — RequireAuth | `frontend/apps/web/src/auth/RequireAuth.tsx` | Done |
| Frontend — RequireRole | `frontend/apps/web/src/auth/RequireRole.tsx` | Done |
| Frontend — useLogin hook | `frontend/apps/web/src/hooks/useLogin.ts` | Done |
| Frontend — useRegister hook | `frontend/apps/web/src/hooks/useRegister.ts` | Done |
| Frontend — API client | `frontend/packages/api-client/src/auth.ts` | Done |
| Frontend Test — LoginPage | `frontend/apps/web/src/pages/__tests__/LoginPage.test.tsx` | Done |
| Frontend Test — RegisterPage | `frontend/apps/web/src/pages/__tests__/RegisterPage.test.tsx` | Done |
| Frontend Test — AuthProvider | `frontend/apps/web/src/auth/__tests__/AuthProvider.test.tsx` | Done |
| Frontend Test — RequireAuth | `frontend/apps/web/src/auth/__tests__/RequireAuth.test.tsx` | Done |
| Frontend Test — useLogin | `frontend/apps/web/src/hooks/__tests__/useLogin.test.tsx` | Done |
| Frontend Test — useRegister | `frontend/apps/web/src/hooks/__tests__/useRegister.test.tsx` | Done |

---

## NYC DOB Violations Sync `[IN PROGRESS]`

- [x] Violation entity and schema
- [x] Watch and alert entities
- [x] Repository layer with tenant scoping
- [x] Flyway migrations
- [x] Integration tests for repositories
- [ ] Socrata sync service (scheduled fetch)
- [ ] Violation search/filter controller
- [ ] Watch management controller
- [ ] Alert generation service
- [ ] MapStruct mappers
- [ ] API client functions
- [ ] Frontend violations list page
- [ ] Frontend watch management page
- [ ] Frontend alert dashboard
- [ ] E2E tests

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Migration | `backend/violations-service/src/main/resources/db/migration/V1__create_violations_schema.sql` | Done |
| Migration | `backend/violations-service/src/main/resources/db/migration/V2__fix_unique_constraint_add_fts.sql` | Done |
| Migration | `backend/violations-service/src/main/resources/db/migration/V3__rename_read_column.sql` | Done |
| Migration | `backend/violations-service/src/main/resources/db/migration/V4__add_sync_metadata_tenant_id.sql` | Done |
| Entity — DobViolation | `backend/violations-service/src/main/java/com/cobalt/violations/entity/DobViolation.java` | Done |
| Entity — Watch | `backend/violations-service/src/main/java/com/cobalt/violations/entity/Watch.java` | Done |
| Entity — Alert | `backend/violations-service/src/main/java/com/cobalt/violations/entity/Alert.java` | Done |
| Entity — SyncMetadata | `backend/violations-service/src/main/java/com/cobalt/violations/entity/SyncMetadata.java` | Done |
| Repo — DobViolationRepository | `backend/violations-service/src/main/java/com/cobalt/violations/repository/DobViolationRepository.java` | Done |
| Repo — WatchRepository | `backend/violations-service/src/main/java/com/cobalt/violations/repository/WatchRepository.java` | Done |
| Repo — AlertRepository | `backend/violations-service/src/main/java/com/cobalt/violations/repository/AlertRepository.java` | Done |
| Repo — SyncMetadataRepository | `backend/violations-service/src/main/java/com/cobalt/violations/repository/SyncMetadataRepository.java` | Done |
| Test — DobViolationRepoIntegration | `backend/violations-service/src/test/java/com/cobalt/violations/repository/DobViolationRepositoryIntegrationTest.java` | Done |
| Test — WatchRepoIntegration | `backend/violations-service/src/test/java/com/cobalt/violations/repository/WatchRepositoryIntegrationTest.java` | Done |
| Test — AlertRepoIntegration | `backend/violations-service/src/test/java/com/cobalt/violations/repository/AlertRepositoryIntegrationTest.java` | Done |
| Test — SyncMetadataRepoIntegration | `backend/violations-service/src/test/java/com/cobalt/violations/repository/SyncMetadataRepositoryIntegrationTest.java` | Done |
| Test — WireMock external API | `backend/violations-service/src/test/java/com/cobalt/violations/integration/ExternalApiWireMockTest.java` | Done |
| Service — SocrataSync | `backend/violations-service/src/main/java/com/cobalt/violations/service/SyncService.java` | Planned |
| Service — ViolationSearch | `backend/violations-service/src/main/java/com/cobalt/violations/service/ViolationService.java` | Planned |
| Service — AlertGeneration | `backend/violations-service/src/main/java/com/cobalt/violations/service/AlertService.java` | Planned |
| Controller — ViolationController | `backend/violations-service/src/main/java/com/cobalt/violations/controller/ViolationController.java` | Planned |
| Controller — WatchController | `backend/violations-service/src/main/java/com/cobalt/violations/controller/WatchController.java` | Planned |
| Mapper — ViolationMapper | `backend/violations-service/src/main/java/com/cobalt/violations/mapper/ViolationMapper.java` | Planned |
| Mapper — WatchMapper | `backend/violations-service/src/main/java/com/cobalt/violations/mapper/WatchMapper.java` | Planned |
| Mapper — AlertMapper | `backend/violations-service/src/main/java/com/cobalt/violations/mapper/AlertMapper.java` | Planned |
| Frontend — ViolationsPage | `frontend/apps/web/src/pages/ViolationsPage.tsx` | Planned |
| Frontend — WatchesPage | `frontend/apps/web/src/pages/WatchesPage.tsx` | Planned |
| Frontend — useViolations hook | `frontend/apps/web/src/hooks/useViolations.ts` | Planned |
| Frontend — API violations client | `frontend/packages/api-client/src/violations.ts` | Planned |

---

## Notification Service `[IN PROGRESS]`

- [x] Notification template entity and schema
- [x] Notification log entity
- [x] Notification preference entity
- [x] Repository layer with tenant scoping
- [x] Integration tests for repositories
- [ ] Email sending service (SMTP)
- [ ] SMS sending service (Twilio)
- [ ] Template rendering engine
- [ ] Notification controller
- [ ] Preference management controller
- [ ] MapStruct mappers
- [ ] Frontend notification preferences page

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Migration | `backend/notification-service/src/main/resources/db/migration/V1__create_notification_schema.sql` | Done |
| Entity — NotificationTemplate | `backend/notification-service/src/main/java/com/cobalt/notification/entity/NotificationTemplate.java` | Done |
| Entity — NotificationLog | `backend/notification-service/src/main/java/com/cobalt/notification/entity/NotificationLog.java` | Done |
| Entity — NotificationPreference | `backend/notification-service/src/main/java/com/cobalt/notification/entity/NotificationPreference.java` | Done |
| Repo — NotificationTemplateRepository | `backend/notification-service/src/main/java/com/cobalt/notification/repository/NotificationTemplateRepository.java` | Done |
| Repo — NotificationLogRepository | `backend/notification-service/src/main/java/com/cobalt/notification/repository/NotificationLogRepository.java` | Done |
| Repo — NotificationPreferenceRepository | `backend/notification-service/src/main/java/com/cobalt/notification/repository/NotificationPreferenceRepository.java` | Done |
| Test — TemplateRepoIntegration | `backend/notification-service/src/test/java/com/cobalt/notification/repository/NotificationTemplateRepositoryIntegrationTest.java` | Done |
| Test — LogRepoIntegration | `backend/notification-service/src/test/java/com/cobalt/notification/repository/NotificationLogRepositoryIntegrationTest.java` | Done |
| Test — PreferenceRepoIntegration | `backend/notification-service/src/test/java/com/cobalt/notification/repository/NotificationPreferenceRepositoryIntegrationTest.java` | Done |
| Test — HealthIntegration | `backend/notification-service/src/test/java/com/cobalt/notification/integration/NotificationHealthIntegrationTest.java` | Done |
| Test — MailConfigIntegration | `backend/notification-service/src/test/java/com/cobalt/notification/integration/MailConfigIntegrationTest.java` | Done |
| Service — EmailService | `backend/notification-service/src/main/java/com/cobalt/notification/service/EmailService.java` | Planned |
| Service — SmsService | `backend/notification-service/src/main/java/com/cobalt/notification/service/SmsService.java` | Planned |
| Controller — NotificationController | `backend/notification-service/src/main/java/com/cobalt/notification/controller/NotificationController.java` | Planned |
| Mapper — NotificationMapper | `backend/notification-service/src/main/java/com/cobalt/notification/mapper/NotificationMapper.java` | Planned |

---

## Infrastructure & CI/CD `[DONE]`

- [x] Docker Compose local development
- [x] Terraform modules (networking, database, EKS, cache, storage, monitoring, security, CDN, DNS, load-balancer)
- [x] GitHub Actions CI/CD (build, test, lint, deploy, promote, quality gate)
- [x] Kubernetes manifests (services, ingress, secrets, monitoring)
- [x] Security scanning (Trivy, OWASP, Checkov, TruffleHog)
- [x] Infracost analysis
- [x] Incident response runbooks

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Workflow — Build | `.github/workflows/build.yml` | Done |
| Workflow — Deploy | `.github/workflows/deploy.yml` | Done |
| Workflow — Quality Gate | `.github/workflows/quality-gate.yml` | Done |
| Workflow — Lint | `.github/workflows/lint.yml` | Done |
| Workflow — Frontend Tests | `.github/workflows/frontend-tests.yml` | Done |
| Workflow — Backend Tests | `.github/workflows/backend-tests.yml` | Done |
| Workflow — Promote | `.github/workflows/promote.yml` | Done |
| Workflow — Infracost | `.github/workflows/infracost.yml` | Done |
| Workflow — Terraform Test | `.github/workflows/terraform-test.yml` | Done |
| TF Module — Networking | `infrastructure/terraform/modules/networking/` | Done |
| TF Module — Database | `infrastructure/terraform/modules/database/` | Done |
| TF Module — EKS | `infrastructure/terraform/modules/eks/` | Done |
| TF Module — Cache | `infrastructure/terraform/modules/cache/` | Done |
| TF Module — Storage | `infrastructure/terraform/modules/storage/` | Done |
| TF Module — Monitoring | `infrastructure/terraform/modules/monitoring/` | Done |
| TF Module — Security Base | `infrastructure/terraform/modules/security-base/` | Done |
| TF Module — Load Balancer | `infrastructure/terraform/modules/load-balancer/` | Done |
| TF Module — Incident Response | `infrastructure/terraform/modules/incident-response/` | Done |
| K8s — Services | `infrastructure/terraform/k8s/services/` | Done |
| K8s — Ingress | `infrastructure/terraform/k8s/ingress/` | Done |
| K8s — Monitoring | `infrastructure/terraform/k8s/monitoring/` | Done |
| K8s — External Secrets | `infrastructure/terraform/k8s/base/external-secrets.yaml` | Done |
| Runbooks | `runbooks/` | Done |

---

## Dashboard & App Shell `[DONE]`

- [x] Dashboard page with layout
- [x] Sidebar navigation
- [x] Theme toggle (dark/light)
- [x] Error boundary
- [x] 404 page
- [x] Query client configuration

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Frontend — DashboardPage | `frontend/apps/web/src/pages/DashboardPage.tsx` | Done |
| Frontend — DashboardLayout | `frontend/apps/web/src/layouts/DashboardLayout.tsx` | Done |
| Frontend — ErrorBoundary | `frontend/apps/web/src/components/ErrorBoundary.tsx` | Done |
| Frontend — NotFoundPage | `frontend/apps/web/src/pages/NotFoundPage.tsx` | Done |
| Frontend — useThemeStore | `frontend/apps/web/src/stores/useThemeStore.ts` | Done |
| Frontend — QueryClient | `frontend/apps/web/src/lib/query-client.ts` | Done |
| Frontend — App | `frontend/apps/web/src/App.tsx` | Done |
| Frontend Test — DashboardPage | `frontend/apps/web/src/pages/__tests__/DashboardPage.test.tsx` | Done |
| Frontend Test — ErrorBoundary | `frontend/apps/web/src/components/__tests__/ErrorBoundary.test.tsx` | Done |
| Frontend Test — RoleGate | `frontend/apps/web/src/components/__tests__/RoleGate.test.tsx` | Done |
| Frontend Test — API client | `frontend/apps/web/src/api/__tests__/client.test.ts` | Done |

---

## Job Management `[PLANNED]`

- [ ] Job entity (title, description, status, scheduled_date, assigned_to)
- [ ] Job status workflow (DRAFT -> SCHEDULED -> IN_PROGRESS -> COMPLETED/CANCELLED)
- [ ] Job CRUD endpoints
- [ ] Job assignment to technicians
- [ ] Job search and filtering
- [ ] Service address association
- [ ] Equipment tracking per location
- [ ] Frontend job list page
- [ ] Frontend job detail page
- [ ] Frontend job creation form
- [ ] Calendar/schedule view

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Migration | `backend/core-service/src/main/resources/db/migration/V*__create_jobs.sql` | Planned |
| Entity — Job | `backend/core-service/src/main/java/com/cobalt/core/entity/Job.java` | Planned |
| Entity — ServiceAddress | `backend/core-service/src/main/java/com/cobalt/core/entity/ServiceAddress.java` | Planned |
| Entity — Equipment | `backend/core-service/src/main/java/com/cobalt/core/entity/Equipment.java` | Planned |
| Repo — JobRepository | `backend/core-service/src/main/java/com/cobalt/core/repository/JobRepository.java` | Planned |
| Service — JobService | `backend/core-service/src/main/java/com/cobalt/core/service/JobService.java` | Planned |
| Mapper — JobMapper | `backend/core-service/src/main/java/com/cobalt/core/mapper/JobMapper.java` | Planned |
| Controller — JobController | `backend/core-service/src/main/java/com/cobalt/core/controller/JobController.java` | Planned |
| Frontend — JobsPage | `frontend/apps/web/src/pages/JobsPage.tsx` | Planned |
| Frontend — JobDetailPage | `frontend/apps/web/src/pages/JobDetailPage.tsx` | Planned |
| Frontend — useJobs hook | `frontend/apps/web/src/hooks/useJobs.ts` | Planned |
| Frontend — API jobs client | `frontend/packages/api-client/src/jobs.ts` | Planned |

---

## Customer Management (CRM) `[PLANNED]`

- [ ] Customer entity (name, phone, email, addresses)
- [ ] Customer CRUD endpoints
- [ ] Customer search with full-text search
- [ ] Service address management
- [ ] Job history per customer
- [ ] Frontend customer list page
- [ ] Frontend customer detail page

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Migration | `backend/core-service/src/main/resources/db/migration/V*__create_customers.sql` | Planned |
| Entity — Customer | `backend/core-service/src/main/java/com/cobalt/core/entity/Customer.java` | Planned |
| Repo — CustomerRepository | `backend/core-service/src/main/java/com/cobalt/core/repository/CustomerRepository.java` | Planned |
| Service — CustomerService | `backend/core-service/src/main/java/com/cobalt/core/service/CustomerService.java` | Planned |
| Mapper — CustomerMapper | `backend/core-service/src/main/java/com/cobalt/core/mapper/CustomerMapper.java` | Planned |
| Controller — CustomerController | `backend/core-service/src/main/java/com/cobalt/core/controller/CustomerController.java` | Planned |
| Frontend — CustomersPage | `frontend/apps/web/src/pages/CustomersPage.tsx` | Planned |
| Frontend — useCustomers hook | `frontend/apps/web/src/hooks/useCustomers.ts` | Planned |
| Frontend — API customers client | `frontend/packages/api-client/src/customers.ts` | Planned |

---

## Estimates & Invoicing `[PLANNED]`

- [ ] Estimate entity (line items, labor, materials, tax)
- [ ] Invoice entity (line items, payment status, due date)
- [ ] Payment entity (amount, method, Stripe integration)
- [ ] Estimate-to-invoice conversion
- [ ] PDF generation
- [ ] Stripe payment processing
- [ ] Frontend estimate builder
- [ ] Frontend invoice management page
- [ ] Frontend payment tracking

### Implementation Status

| Artifact | Path | Status |
|----------|------|--------|
| Migration | `backend/core-service/src/main/resources/db/migration/V*__create_estimates_invoices.sql` | Planned |
| Entity — Estimate | `backend/core-service/src/main/java/com/cobalt/core/entity/Estimate.java` | Planned |
| Entity — Invoice | `backend/core-service/src/main/java/com/cobalt/core/entity/Invoice.java` | Planned |
| Entity — Payment | `backend/core-service/src/main/java/com/cobalt/core/entity/Payment.java` | Planned |
| Service — EstimateService | `backend/core-service/src/main/java/com/cobalt/core/service/EstimateService.java` | Planned |
| Service — InvoiceService | `backend/core-service/src/main/java/com/cobalt/core/service/InvoiceService.java` | Planned |
| Service — PaymentService | `backend/core-service/src/main/java/com/cobalt/core/service/PaymentService.java` | Planned |
| Controller — EstimateController | `backend/core-service/src/main/java/com/cobalt/core/controller/EstimateController.java` | Planned |
| Controller — InvoiceController | `backend/core-service/src/main/java/com/cobalt/core/controller/InvoiceController.java` | Planned |

---

## Parts & Supplier Integration `[BACKLOG]`

- [ ] Parts catalog entity
- [ ] Supplier abstraction layer (PartsSupplierService interface)
- [ ] Manual catalog / CSV import implementation
- [ ] Parts search and availability check
- [ ] Purchase order management
- [ ] Frontend parts catalog page
- [ ] Frontend order tracking

---

## Scheduling & Calendar `[BACKLOG]`

- [ ] Calendar view with drag-and-drop (dnd-kit)
- [ ] Technician availability management
- [ ] Route optimization
- [ ] Recurring job scheduling
- [ ] Schedule conflict detection
