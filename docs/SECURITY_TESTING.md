# Security Testing Guide

## Overview

Cobalt uses multiple security scanning tools across the CI pipeline to detect vulnerabilities in dependencies, container images, infrastructure-as-code, and secrets.

## Tools

| Tool | Scope | Threshold | CI Job |
|---|---|---|---|
| Trivy (filesystem) | Backend/frontend dependencies | CRITICAL, HIGH | `build.yml` > `security-scan` |
| Trivy (image) | Docker container images | CRITICAL, HIGH | `build.yml` > `docker-images` |
| OWASP Dependency-Check | Java dependencies (CVE database) | CVSS >= 7.0 | `build.yml` > `security-scan` |
| Checkov | Terraform IaC misconfigurations | Default rules | `build.yml` > `security-scan` |
| TruffleHog | Secrets in git history | Verified secrets only | `lint.yml` > `secret-scan` |
| TFLint | Terraform best practices (AWS) | All enabled rules | `lint.yml` > `terraform-validation` |
| pnpm audit | npm package vulnerabilities | high | `build.yml` > `security-scan` |
| Terraform test | Module correctness | All assertions | `terraform-test.yml` |

## Running Locally

### OWASP Dependency-Check
```bash
cd backend
./gradlew dependencyCheckAggregate
# Report: backend/build/reports/dependency-check-report.html
```

### Trivy (filesystem scan)
```bash
trivy fs --severity CRITICAL,HIGH ./backend
trivy fs --severity CRITICAL,HIGH ./frontend
```

### Trivy (container image scan)
```bash
docker build -t cobalt/core-service:local -f backend/Dockerfile.core ./backend
trivy image --severity CRITICAL,HIGH cobalt/core-service:local
```

### Checkov (Terraform)
```bash
checkov -d infrastructure/terraform
```

### TruffleHog (secrets)
```bash
trufflehog git file://. --only-verified
```

### TFLint
```bash
cd infrastructure/terraform
tflint --init --config=.tflint.hcl
tflint --config=.tflint.hcl
```

### Terraform format and validate
```bash
cd infrastructure/terraform
terraform fmt -check -recursive
cd environments/dev && terraform init -backend=false && terraform validate
cd ../prod && terraform init -backend=false && terraform validate
```

### Terraform module tests
```bash
cd infrastructure/terraform/modules/networking && terraform init -backend=false && terraform test
cd ../database && terraform init -backend=false && terraform test
cd ../security && terraform init -backend=false && terraform test
cd ../eks && terraform init -backend=false && terraform test
```

### pnpm audit
```bash
cd frontend
pnpm audit --audit-level=high
```

## Suppressing False Positives

### OWASP Dependency-Check
Add entries to `backend/config/owasp-suppressions.xml`:
```xml
<suppress>
    <notes><![CDATA[Reason for suppression]]></notes>
    <packageUrl regex="true">^pkg:maven/com\.example/.*$</packageUrl>
    <cve>CVE-2024-XXXXX</cve>
</suppress>
```

### Trivy
Add CVE IDs to `.trivyignore` (one per line):
```
CVE-2024-XXXXX  # Reason for suppression
```

### Checkov
Add inline skip comments in Terraform files:
```hcl
resource "aws_s3_bucket" "example" {
  #checkov:skip=CKV_AWS_XXX:Reason for suppression
  bucket = "example"
}
```

## Incident Response

If a security scan finds a genuine vulnerability:

1. **CRITICAL severity**: Fix immediately, do not merge the PR
2. **HIGH severity**: Fix before merging, or create a follow-up ticket with a 48-hour SLA
3. **MEDIUM/LOW**: Create a backlog ticket, address in the next sprint

For dependency vulnerabilities, check if an updated version is available. If not, assess whether the vulnerability is exploitable in Cobalt's context and document the decision in the suppressions file.
