#!/usr/bin/env bash
# ===========================================
# Core Infrastructure — NO-MOCK Policy Enforcement
# ===========================================
# Scans all test files for forbidden mock patterns.
# Used by CI/CD and pre-commit hooks.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

VIOLATIONS=0

# Go patterns
GO_PATTERNS=(
  "github.com/golang/mock"
  "github.com/stretchr/testify/mock"
  "go.uber.org/mock"
  "github.com/vektra/mockery"
  "mockgen"
  "MockController"
  "EXPECT()"
  "bxcodec/faker"
  "agiledragon/gomonkey"
)

# Backend patterns (Java) - for any Java projects
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

# Check Go projects (solomon, etc.)
for go_project in solomon; do
  if [ -d "$go_project" ]; then
    echo "Scanning Go project: $go_project"
    for pattern in "${GO_PATTERNS[@]}"; do
      while IFS= read -r line; do
        if [ -n "$line" ]; then
          echo -e "  ${RED}VIOLATION${NC}: $line — pattern: $pattern"
          ((VIOLATIONS++))
        fi
      done < <(grep -rn "$pattern" "$go_project" --include="*_test.go" 2>/dev/null || true)
    done
  fi
done

# Check backend (Java)
if [ -d "backend" ]; then
  echo "Scanning Java backend..."
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
  echo "Scanning frontend..."
  for pattern in "${JS_PATTERNS[@]}"; do
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        echo -e "  ${RED}VIOLATION${NC}: $line — pattern: $pattern"
        ((VIOLATIONS++))
      fi
    done < <(grep -rn "$pattern" frontend --include="*.test.*" --include="*.spec.*" 2>/dev/null || true)
  done
fi

# Check Solomon web
if [ -d "solomon/web" ]; then
  echo "Scanning Solomon web..."
  for pattern in "${JS_PATTERNS[@]}"; do
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        echo -e "  ${RED}VIOLATION${NC}: $line — pattern: $pattern"
        ((VIOLATIONS++))
      fi
    done < <(grep -rn "$pattern" solomon/web/src --include="*.test.*" --include="*.spec.*" 2>/dev/null || true)
  done
fi

echo "================================"

if [ "$VIOLATIONS" -gt 0 ]; then
  echo -e "${RED}Found $VIOLATIONS mock violation(s).${NC}"
  echo ""
  echo "Use real implementations instead:"
  echo "  Go:       testcontainers-go, httptest.Server, WireMock"
  echo "  Java:     TestContainers, GreenMail, WireMock"
  echo "  Frontend: MSW (Mock Service Worker) for API boundaries only"
  exit 1
else
  echo -e "${GREEN}NO-MOCK check passed — no violations found.${NC}"
  exit 0
fi
