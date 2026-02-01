#!/usr/bin/env bash
# ===========================================
# Cobalt — NO-MOCK Policy Enforcement
# ===========================================
# Scans all test files for forbidden mock patterns.
# Used by CI/CD and pre-commit hooks.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

VIOLATIONS=0

# Backend patterns (Java)
JAVA_PATTERNS=(
  "import org.mockito"
  "import static org.mockito"
  "@Mock"
  "@MockBean"
  "@SpyBean"
  "Mockito\.mock("
  "Mockito\.when("
  "Mockito\.verify("
  "import io.mockk"
  "@MockK"
)

# Frontend patterns (TypeScript/JavaScript)
JS_PATTERNS=(
  "jest\.mock("
  "jest\.spyOn("
  "vi\.mock("
  "vi\.spyOn("
  "jest\.fn("
  "vi\.fn("
  "from 'jest-mock'"
)

echo "Running NO-MOCK policy check..."
echo "================================"

# Check backend
if [ -d "backend" ]; then
  for pattern in "${JAVA_PATTERNS[@]}"; do
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        echo -e "  ${RED}VIOLATION${NC}: $line — pattern: $pattern"
        ((VIOLATIONS++))
      fi
    done < <(grep -rn "$pattern" backend/*/src/test backend/*/src/integrationTest 2>/dev/null || true)
  done
fi

# Check frontend
if [ -d "frontend" ]; then
  for pattern in "${JS_PATTERNS[@]}"; do
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        echo -e "  ${RED}VIOLATION${NC}: $line — pattern: $pattern"
        ((VIOLATIONS++))
      fi
    done < <(grep -rn "$pattern" frontend/apps frontend/packages --include="*.test.*" --include="*.spec.*" 2>/dev/null || true)
  done
fi

echo "================================"

if [ "$VIOLATIONS" -gt 0 ]; then
  echo -e "${RED}Found $VIOLATIONS mock violation(s).${NC}"
  echo "Use TestContainers, GreenMail, WireMock (backend) or MSW (frontend) instead."
  exit 1
else
  echo -e "${GREEN}NO-MOCK check passed — no violations found.${NC}"
  exit 0
fi
