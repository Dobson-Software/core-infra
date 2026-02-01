#!/usr/bin/env bash
# ===========================================
# Cobalt — Port Availability Checker
# ===========================================
# Checks that all required ports are available before starting services.

set -euo pipefail

PORTS=(
  "3000:Frontend (React/Vite)"
  "8080:Core Service"
  "8081:Notification Service"
  "8082:Violations Service"
  "5432:PostgreSQL"
  "6379:Redis"
  "1025:MailHog SMTP"
  "8025:MailHog UI"
  "80:Nginx Gateway"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

has_issues=false

echo "Checking port availability for Cobalt..."
echo "========================================="

for entry in "${PORTS[@]}"; do
  port="${entry%%:*}"
  name="${entry#*:}"

  if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
    pid=$(lsof -Pi ":$port" -sTCP:LISTEN -t 2>/dev/null | head -1)
    process=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
    echo -e "  ${RED}BUSY${NC}  :$port — $name (PID $pid: $process)"
    has_issues=true
  else
    echo -e "  ${GREEN}FREE${NC}  :$port — $name"
  fi
done

echo "========================================="

if [ "$has_issues" = true ]; then
  echo -e "${RED}Some ports are in use. Stop conflicting services before starting Cobalt.${NC}"
  exit 1
else
  echo -e "${GREEN}All ports are available.${NC}"
  exit 0
fi
