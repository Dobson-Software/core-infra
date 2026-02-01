# Feature Audit Skill

## Purpose
Audit the Cobalt codebase for feature completeness against the implementation checklist defined in CLAUDE.md.

## Key Reference Files

- **CLAUDE.md** — Coding standards, architecture patterns, and implementation checklist
- **ROADMAP.md** — Machine-readable product roadmap with feature status and expected artifacts
- **audit/audit-config.yml** — Audit rules, categories, severity thresholds, and pattern definitions
- **Nightly Audit Workflow** — `.github/workflows/nightly-audit.yml` runs this audit automatically at 3 AM UTC

## When to Use
- Before opening a PR for a new feature
- When reviewing another developer's feature branch
- During sprint retrospectives to check coverage
- To preview what the nightly audit would find

## Audit Categories

The audit covers 5 categories (configured in `audit/audit-config.yml`):

| Category | What it checks |
|----------|---------------|
| **Roadmap** | Features marked `[DONE]` in ROADMAP.md have all implementation artifacts |
| **Testing** | Source files have corresponding test files |
| **Quality** | tenant_id, no mocks, MapStruct, @Transactional, no `any`, RFC 7807, audit fields |
| **Security** | No hardcoded secrets, @Valid, auth on endpoints, no SQL injection |
| **Architecture** | No logic in controllers, no repo calls from controllers, proper abstractions |

## Audit Checklist

For each feature, verify:

### Backend
- [ ] Flyway migration exists in `db/migration/`
- [ ] Entity has `tenant_id` and audit fields (`created_at`, `updated_at`, `created_by`, `updated_by`)
- [ ] Repository methods include `tenantId` parameter
- [ ] Service layer has `@Transactional` annotations
- [ ] MapStruct mapper exists (no manual mapping)
- [ ] Controller returns proper HTTP status codes
- [ ] Error responses follow RFC 7807
- [ ] Integration tests use TestContainers (no mocks)
- [ ] Service layer coverage >= 95%

### Frontend
- [ ] API client function in `@cobalt/api-client`
- [ ] TanStack Query hook with proper query keys
- [ ] React component uses Blueprint.js
- [ ] Client state (if any) uses Zustand
- [ ] Unit tests exist (Vitest)
- [ ] E2E test covers happy path (Playwright)
- [ ] No `any` types in TypeScript

### Cross-cutting
- [ ] All database queries are tenant-scoped
- [ ] No mock imports in test files
- [ ] Checkstyle passes
- [ ] ESLint passes
- [ ] TypeScript strict mode passes

## How to Run

```bash
# Quick check — scan for common issues
./scripts/check-no-mocks.sh

# Full backend check
cd backend && ./gradlew check

# Full frontend check
cd frontend && pnpm lint && pnpm typecheck && pnpm test:run

# Trigger nightly audit manually
gh workflow run nightly-audit.yml

# Check audit issues
gh issue list --label audit-finding
```

## Nightly Audit Pipeline

The automated pipeline (`.github/workflows/nightly-audit.yml`) runs this audit nightly:

1. **Audit** (Opus, 30 turns) — scans codebase across all 5 categories
2. **Verify** (Sonnet, 20 turns) — independently confirms each finding
3. **Create Issues** (gh CLI) — deduplicates and creates GitHub Issues

To fix an audit finding:
1. Review issues labeled `audit-finding`
2. Apply `audit-approved` label to trigger automated fix (`.github/workflows/fix-audit-issue.yml`)
3. Review the generated PR

## Output Format

Report should list:
1. Feature name
2. Status (PASS / FAIL / PARTIAL)
3. Missing items from checklist
4. Recommendations
