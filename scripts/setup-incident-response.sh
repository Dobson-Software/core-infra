#!/usr/bin/env bash
set -euo pipefail

# Setup script for the AI Incident Response pipeline.
#
# Creates an AWS Secrets Manager secret with the required API keys.
# After running this, set enable_incident_response = true in Terraform.
#
# Usage:
#   ./scripts/setup-incident-response.sh <environment>
#
# Required environment variables:
#   ANTHROPIC_API_KEY   — Claude API key from console.anthropic.com
#   AXIOM_API_TOKEN     — Axiom API token from axiom.co/settings/tokens
#   GITHUB_TOKEN        — GitHub PAT with repo:issues scope
#   SLACK_WEBHOOK_URL   — (optional) Slack incoming webhook URL

ENVIRONMENT="${1:?Usage: $0 <environment> (dev|prod)}"
SECRET_NAME="cobalt-${ENVIRONMENT}-incident-response"
REGION="${AWS_REGION:-us-east-1}"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ERROR: ANTHROPIC_API_KEY is required"
  echo "  Get one from https://console.anthropic.com/settings/keys"
  exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "ERROR: GITHUB_TOKEN is required"
  echo "  Create a PAT with repo scope at https://github.com/settings/tokens"
  exit 1
fi

SECRET_JSON=$(cat <<EOF
{
  "anthropic_api_key": "${ANTHROPIC_API_KEY}",
  "axiom_api_token": "${AXIOM_API_TOKEN:-}",
  "github_token": "${GITHUB_TOKEN}",
  "slack_webhook_url": "${SLACK_WEBHOOK_URL:-}"
}
EOF
)

echo "Creating/updating secret: ${SECRET_NAME} in ${REGION}..."

if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" > /dev/null 2>&1; then
  aws secretsmanager put-secret-value \
    --secret-id "${SECRET_NAME}" \
    --secret-string "${SECRET_JSON}" \
    --region "${REGION}"
  echo "Secret updated."
else
  aws secretsmanager create-secret \
    --name "${SECRET_NAME}" \
    --description "API keys for Cobalt AI incident response pipeline" \
    --secret-string "${SECRET_JSON}" \
    --region "${REGION}"
  echo "Secret created."
fi

echo ""
echo "Next steps:"
echo "  1. Set enable_incident_response = true in infrastructure/terraform/environments/${ENVIRONMENT}/main.tf"
echo "  2. Run: cd infrastructure/terraform/environments/${ENVIRONMENT} && terraform apply"
echo "  3. Test: aws lambda invoke --function-name cobalt-${ENVIRONMENT}-incident-responder /dev/stdout"
