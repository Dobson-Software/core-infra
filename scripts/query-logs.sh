#!/usr/bin/env bash
#
# query-logs.sh — Query Axiom logs for Cobalt services
#
# Usage:
#   ./scripts/query-logs.sh errors [service] [timerange]
#   ./scripts/query-logs.sh search "pattern" [service] [timerange]
#   ./scripts/query-logs.sh tenant <tenant-id> [timerange]
#   ./scripts/query-logs.sh request <request-id>
#   ./scripts/query-logs.sh recent [service] [limit]
#
# Examples:
#   ./scripts/query-logs.sh errors core-service 1h
#   ./scripts/query-logs.sh search "NullPointerException" "" 24h
#   ./scripts/query-logs.sh tenant 550e8400-e29b-41d4-a716-446655440000 6h
#   ./scripts/query-logs.sh request abc-123-def
#   ./scripts/query-logs.sh recent violations-service 50
#
# Environment:
#   AXIOM_API_TOKEN  — Axiom API token (required)
#   AXIOM_DATASET    — Axiom dataset name (default: cobalt-prod)
#

set -euo pipefail

AXIOM_DATASET="${AXIOM_DATASET:-cobalt-prod}"
AXIOM_API_URL="https://api.axiom.co/v1/datasets/${AXIOM_DATASET}/query"

if [[ -z "${AXIOM_API_TOKEN:-}" ]]; then
    echo "Error: AXIOM_API_TOKEN environment variable is required" >&2
    echo "Get a token at https://app.axiom.co/settings/api-tokens" >&2
    exit 1
fi

command="${1:-help}"
shift || true

query_axiom() {
    local apl="$1"
    local start_time="$2"
    local end_time
    end_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    curl -s -X POST "$AXIOM_API_URL" \
        -H "Authorization: Bearer ${AXIOM_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"apl\": \"${apl}\",
            \"startTime\": \"${start_time}\",
            \"endTime\": \"${end_time}\"
        }" | python3 -m json.tool 2>/dev/null || cat
}

parse_timerange() {
    local range="${1:-1h}"
    local seconds=3600

    if [[ "$range" =~ ^([0-9]+)m$ ]]; then
        seconds=$(( ${BASH_REMATCH[1]} * 60 ))
    elif [[ "$range" =~ ^([0-9]+)h$ ]]; then
        seconds=$(( ${BASH_REMATCH[1]} * 3600 ))
    elif [[ "$range" =~ ^([0-9]+)d$ ]]; then
        seconds=$(( ${BASH_REMATCH[1]} * 86400 ))
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        date -u -v-${seconds}S +%Y-%m-%dT%H:%M:%SZ
    else
        date -u -d "${seconds} seconds ago" +%Y-%m-%dT%H:%M:%SZ
    fi
}

case "$command" in
    errors)
        service="${1:-}"
        timerange="${2:-1h}"
        start=$(parse_timerange "$timerange")
        svc_filter=""
        if [[ -n "$service" ]]; then
            svc_filter="| where kubernetes.labels.app == '${service}' "
        fi
        query_axiom "['${AXIOM_DATASET}'] ${svc_filter}| where level == 'ERROR' or log_processed.level == 'ERROR' | sort by _time desc | take 100" "$start"
        ;;
    search)
        pattern="${1:?Pattern required}"
        service="${2:-}"
        timerange="${3:-1h}"
        start=$(parse_timerange "$timerange")
        svc_filter=""
        if [[ -n "$service" ]]; then
            svc_filter="| where kubernetes.labels.app == '${service}' "
        fi
        query_axiom "['${AXIOM_DATASET}'] ${svc_filter}| search '${pattern}' | sort by _time desc | take 100" "$start"
        ;;
    tenant)
        tenant_id="${1:?Tenant ID required}"
        timerange="${2:-1h}"
        start=$(parse_timerange "$timerange")
        query_axiom "['${AXIOM_DATASET}'] | where log_processed.tenantId == '${tenant_id}' | sort by _time desc | take 100" "$start"
        ;;
    request)
        request_id="${1:?Request ID required}"
        start=$(parse_timerange "24h")
        query_axiom "['${AXIOM_DATASET}'] | where log_processed.requestId == '${request_id}' | sort by _time asc | take 200" "$start"
        ;;
    recent)
        service="${1:-}"
        limit="${2:-50}"
        start=$(parse_timerange "1h")
        svc_filter=""
        if [[ -n "$service" ]]; then
            svc_filter="| where kubernetes.labels.app == '${service}' "
        fi
        query_axiom "['${AXIOM_DATASET}'] ${svc_filter}| sort by _time desc | take ${limit}" "$start"
        ;;
    help|*)
        echo "Usage: query-logs.sh <command> [args]"
        echo ""
        echo "Commands:"
        echo "  errors [service] [timerange]         Show ERROR-level logs"
        echo "  search \"pattern\" [service] [timerange]  Full-text search"
        echo "  tenant <tenant-id> [timerange]       Show logs for a tenant"
        echo "  request <request-id>                 Trace a request by ID"
        echo "  recent [service] [limit]             Show recent logs"
        echo ""
        echo "Timerange formats: 15m, 1h, 6h, 1d, 7d (default: 1h)"
        echo ""
        echo "Environment variables:"
        echo "  AXIOM_API_TOKEN  Axiom API token (required)"
        echo "  AXIOM_DATASET    Dataset name (default: cobalt-prod)"
        ;;
esac
