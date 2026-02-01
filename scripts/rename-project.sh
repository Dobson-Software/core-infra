#!/usr/bin/env bash
set -euo pipefail

# ===========================================
# Core-Infra Template — Project Renaming Script
# ===========================================
# Renames all "cobalt" references throughout the codebase
# to your chosen project and organization names.
#
# Usage:
#   ./scripts/rename-project.sh <project-name> <org-name>
#
# Example:
#   ./scripts/rename-project.sh acme-hvac acme
#
# This will:
#   - Rename Java packages from com.cobalt → com.acme
#   - Rename npm scope from @cobalt/ → @acme-hvac/
#   - Rename Docker containers from cobalt-* → acme-hvac-*
#   - Rename Terraform resources from cobalt-* → acme-hvac-*
#   - Rename Kubernetes namespaces from cobalt-* → acme-hvac-*
#   - Update database names, env vars, CI/CD, and docs

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Argument validation ---
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <project-name> <org-name>"
    echo ""
    echo "  project-name  Lowercase kebab-case name (e.g. acme-hvac)"
    echo "  org-name      Lowercase single-word org for Java packages (e.g. acme)"
    echo ""
    echo "Example: $0 acme-hvac acme"
    exit 1
fi

readonly NEW_PROJECT="$1"
readonly NEW_ORG="$2"

# Validate inputs
if [[ ! "$NEW_PROJECT" =~ ^[a-z][a-z0-9-]*$ ]]; then
    echo "Error: project-name must be lowercase alphanumeric with hyphens (e.g. my-app)"
    exit 1
fi

if [[ ! "$NEW_ORG" =~ ^[a-z][a-z0-9]*$ ]]; then
    echo "Error: org-name must be lowercase alphanumeric, no hyphens (e.g. myorg)"
    exit 1
fi

echo "============================================"
echo "  Renaming project: cobalt → $NEW_PROJECT"
echo "  Renaming org:     com.cobalt → com.$NEW_ORG"
echo "  NPM scope:        @cobalt/ → @$NEW_PROJECT/"
echo "============================================"
echo ""

cd "$PROJECT_ROOT"

# --- Helper: portable sed in-place ---
_sed_i() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# --- Helper: find text files, skip .git and binary dirs ---
_find_text_files() {
    find . \
        -not -path './.git/*' \
        -not -path '*/node_modules/*' \
        -not -path '*/.gradle/*' \
        -not -path '*/build/*' \
        -not -path '*/pnpm-lock.yaml' \
        -not -name '*.jar' \
        -not -name '*.class' \
        -not -name '*.png' \
        -not -name '*.jpg' \
        -not -name '*.ico' \
        -not -name '*.woff' \
        -not -name '*.woff2' \
        -not -name '*.ttf' \
        -not -name '*.eot' \
        -type f
}

# ======================================================
# 1. Rename Java package directories: com/cobalt → com/<org>
# ======================================================
echo "[1/9] Renaming Java package directories..."

find ./backend -type d -path '*/com/cobalt' | sort -r | while read -r dir; do
    new_dir="${dir/com\/cobalt/com\/$NEW_ORG}"
    mkdir -p "$(dirname "$new_dir")"
    mv "$dir" "$new_dir"
done

# Also handle test directories
find ./backend -type d -path '*/com/cobalt' | sort -r | while read -r dir; do
    new_dir="${dir/com\/cobalt/com\/$NEW_ORG}"
    mkdir -p "$(dirname "$new_dir")"
    mv "$dir" "$new_dir"
done

echo "  Done."

# ======================================================
# 2. Replace file contents: com.cobalt → com.<org>
# ======================================================
echo "[2/9] Replacing Java package references in file contents..."

_find_text_files | while read -r file; do
    if grep -q 'com\.cobalt' "$file" 2>/dev/null; then
        _sed_i "s/com\.cobalt/com.$NEW_ORG/g" "$file"
    fi
    if grep -q 'com/cobalt' "$file" 2>/dev/null; then
        _sed_i "s|com/cobalt|com/$NEW_ORG|g" "$file"
    fi
done

echo "  Done."

# ======================================================
# 3. Replace Gradle project name
# ======================================================
echo "[3/9] Updating Gradle project name..."

_sed_i "s/cobalt-platform/$NEW_PROJECT-platform/g" ./backend/settings.gradle.kts

echo "  Done."

# ======================================================
# 4. Replace frontend npm scope: @cobalt/ → @<project>/
# ======================================================
echo "[4/9] Renaming frontend npm scope and package names..."

_find_text_files | while read -r file; do
    if grep -q '@cobalt/' "$file" 2>/dev/null; then
        _sed_i "s|@cobalt/|@$NEW_PROJECT/|g" "$file"
    fi
done

# Root frontend package name
_sed_i "s/\"cobalt-frontend\"/\"$NEW_PROJECT-frontend\"/g" ./frontend/package.json

echo "  Done."

# ======================================================
# 5. Replace Docker/Compose references
# ======================================================
echo "[5/9] Renaming Docker container and network names..."

for f in docker-compose.yml docker-compose.test.yml; do
    if [[ -f "$f" ]]; then
        _sed_i "s/cobalt-/$NEW_PROJECT-/g" "$f"
        _sed_i "s/POSTGRES_DB=cobalt/POSTGRES_DB=$NEW_PROJECT/g" "$f"
        _sed_i "s/POSTGRES_USER=cobalt/POSTGRES_USER=$NEW_PROJECT/g" "$f"
        _sed_i "s/POSTGRES_PASSWORD=cobalt_dev/POSTGRES_PASSWORD=${NEW_PROJECT}_dev/g" "$f"
        _sed_i "s|cobalt_test|${NEW_PROJECT}_test|g" "$f"
    fi
done

# Dockerfiles: user/group names and comments
for f in $(find ./backend ./frontend -name 'Dockerfile*' -type f 2>/dev/null); do
    _sed_i "s/cobalt/$NEW_PROJECT/g" "$f"
done

echo "  Done."

# ======================================================
# 6. Replace Terraform resource names
# ======================================================
echo "[6/9] Renaming Terraform resource prefixes..."

find ./infrastructure/terraform -name '*.tf' -o -name '*.tftest.hcl' -o -name '*.tfvars' | while read -r file; do
    if grep -q 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

# Infracost usage file
if [[ -f ./infrastructure/terraform/infracost-usage.yml ]]; then
    _sed_i "s/cobalt/$NEW_PROJECT/g" ./infrastructure/terraform/infracost-usage.yml
fi

echo "  Done."

# ======================================================
# 7. Replace Kubernetes manifest references
# ======================================================
echo "[7/9] Renaming Kubernetes resources..."

find ./infrastructure/terraform/k8s -name '*.yaml' -o -name '*.yml' | while read -r file; do
    if grep -q 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

echo "  Done."

# ======================================================
# 8. Replace CI/CD workflow references
# ======================================================
echo "[8/9] Renaming CI/CD workflow references..."

find ./.github -name '*.yml' -o -name '*.yaml' | while read -r file; do
    if grep -q 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

echo "  Done."

# ======================================================
# 9. Replace remaining references in config/docs
# ======================================================
echo "[9/9] Updating config files, env vars, and documentation..."

# .env.example
if [[ -f .env.example ]]; then
    _sed_i "s/POSTGRES_DB=cobalt/POSTGRES_DB=$NEW_PROJECT/g" .env.example
    _sed_i "s/POSTGRES_USER=cobalt/POSTGRES_USER=$NEW_PROJECT/g" .env.example
    _sed_i "s/POSTGRES_PASSWORD=cobalt_dev/POSTGRES_PASSWORD=${NEW_PROJECT}_dev/g" .env.example
    _sed_i "s/cobalt-uploads/$NEW_PROJECT-uploads/g" .env.example
    # Update header comment
    _sed_i "s/Cobalt Platform/${NEW_PROJECT^} Platform/g" .env.example
fi

# init-db.sql
if [[ -f backend/init-db.sql ]]; then
    _sed_i "s/Cobalt Platform/${NEW_PROJECT^} Platform/g" backend/init-db.sql
fi

# application.yml files
find ./backend -name 'application*.yml' -o -name 'application*.yaml' | while read -r file; do
    if grep -q 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

# Nginx config
find ./nginx -type f | while read -r file; do
    if grep -q 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

# CLAUDE.md
if [[ -f CLAUDE.md ]]; then
    _sed_i "s/Cobalt/${NEW_PROJECT^}/g" CLAUDE.md
    _sed_i "s/cobalt/$NEW_PROJECT/g" CLAUDE.md
    # Fix Java package references back to org name (CLAUDE.md has com.cobalt examples)
    _sed_i "s/com\.$NEW_PROJECT/com.$NEW_ORG/g" CLAUDE.md
fi

# README.md
if [[ -f README.md ]]; then
    _sed_i "s/Cobalt/${NEW_PROJECT^}/g" README.md
    _sed_i "s/cobalt/$NEW_PROJECT/g" README.md
fi

# ROADMAP.md
if [[ -f ROADMAP.md ]]; then
    _sed_i "s/Cobalt/${NEW_PROJECT^}/g" ROADMAP.md
    _sed_i "s/cobalt/$NEW_PROJECT/g" ROADMAP.md
fi

# Runbooks
find ./runbooks -type f -name '*.md' 2>/dev/null | while read -r file; do
    if grep -q -i 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/Cobalt/${NEW_PROJECT^}/g" "$file"
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

# Audit scripts
find ./audit -type f 2>/dev/null | while read -r file; do
    if grep -q -i 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

# Scripts (except this one)
find ./scripts -type f -not -name 'rename-project.sh' | while read -r file; do
    if grep -q -i 'cobalt' "$file" 2>/dev/null; then
        _sed_i "s/cobalt/$NEW_PROJECT/g" "$file"
    fi
done

echo "  Done."

# ======================================================
# Summary
# ======================================================
echo ""
echo "============================================"
echo "  Rename complete!"
echo "============================================"
echo ""
echo "What was changed:"
echo "  - Java packages:    com.cobalt → com.$NEW_ORG"
echo "  - Gradle project:   cobalt-platform → $NEW_PROJECT-platform"
echo "  - NPM scope:        @cobalt/* → @$NEW_PROJECT/*"
echo "  - Docker:           cobalt-* → $NEW_PROJECT-*"
echo "  - Terraform:        cobalt-* → $NEW_PROJECT-*"
echo "  - Kubernetes:       cobalt-* → $NEW_PROJECT-*"
echo "  - CI/CD workflows:  cobalt → $NEW_PROJECT"
echo "  - Config & docs:    cobalt → $NEW_PROJECT"
echo ""
echo "Next steps:"
echo "  1. Review changes:  git diff"
echo "  2. Delete pnpm-lock.yaml and run: cd frontend && pnpm install"
echo "  3. Test backend:    cd backend && ./gradlew build"
echo "  4. Test frontend:   cd frontend && pnpm build"
echo "  5. Commit:          git add -A && git commit -m 'chore: rename project to $NEW_PROJECT'"
echo ""
