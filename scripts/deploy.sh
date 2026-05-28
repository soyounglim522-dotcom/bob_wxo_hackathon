#!/bin/bash
# deploy.sh — Deploy a watsonx Orchestrate agent to the hackathon instance.
#
# Usage:
#   bash scripts/deploy.sh \
#       --connection connections/my_app.yaml \
#       --tool       tools/my_tool.py \
#       --app-id     my_app \
#       --agent      agents/my_agent.yaml
#
# All flags are optional; omit any you don't need (e.g. no connection for
# tools that don't use one, no --requirements-file if there are no deps).
#
# Required env vars (load from .env before running):
#   WO_INSTANCE_API_KEY  — IBM Cloud API key
#   WO_INSTANCE_URL      — instance base URL
#   WO_IAM_URL           — IAM base URL (default: https://iam.cloud.ibm.com)
#   WO_AUTH_TYPE         — auth type (default: ibm_iam)
#   WO_ENV_NAME          — environment name (default: hackathon)
#
# Example:
#   source .env && bash scripts/deploy.sh \
#       --connection connections/my_app.yaml \
#       --tool tools/get_weather.py \
#       --app-id my_app \
#       --agent agents/weather_agent.yaml

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────────────────
WO_IAM_URL="${WO_IAM_URL:-https://iam.cloud.ibm.com}"
WO_AUTH_TYPE="${WO_AUTH_TYPE:-ibm_iam}"
WO_ENV_NAME="${WO_ENV_NAME:-hackathon}"

CONNECTION_FILE=""
TOOL_FILE=""
APP_ID=""
AGENT_FILE=""
REQUIREMENTS_FILE="requirements.txt"

# ── Arg parsing ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --connection)        CONNECTION_FILE="$2"; shift 2 ;;
    --tool)              TOOL_FILE="$2";       shift 2 ;;
    --app-id)            APP_ID="$2";          shift 2 ;;
    --agent)             AGENT_FILE="$2";      shift 2 ;;
    --requirements-file) REQUIREMENTS_FILE="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

# ── Validate required env vars ───────────────────────────────────────────────
: "${WO_INSTANCE_API_KEY:?Set WO_INSTANCE_API_KEY (source .env first)}"
: "${WO_INSTANCE_URL:?Set WO_INSTANCE_URL (source .env first)}"

cd "$(git rev-parse --show-toplevel)"

# ── 0. Auth ──────────────────────────────────────────────────────────────────
echo "▶ Registering env '$WO_ENV_NAME'..."
printf 'Y\n' | uv run orchestrate env add \
    --name "$WO_ENV_NAME" \
    --url  "$WO_INSTANCE_URL" \
    --type "$WO_AUTH_TYPE" \
    --iam-url "$WO_IAM_URL" 2>&1 | grep -v "^$" || true

echo "▶ Activating env..."
uv run orchestrate env activate "$WO_ENV_NAME" --api-key "$WO_INSTANCE_API_KEY"
uv run orchestrate env list | grep -E "active|$WO_ENV_NAME"

# ── 1. Connection ─────────────────────────────────────────────────────────────
if [[ -n "$CONNECTION_FILE" ]]; then
  echo "▶ Importing connection: $CONNECTION_FILE"
  uv run orchestrate connections import --file "$CONNECTION_FILE" \
    || echo "⚠  Connection import had issues (may already exist — continuing)"
fi

# ── 2. Tool ───────────────────────────────────────────────────────────────────
if [[ -n "$TOOL_FILE" ]]; then
  echo "▶ Importing tool: $TOOL_FILE"
  TOOL_ARGS=(--kind python --file "$TOOL_FILE")
  [[ -n "$APP_ID" ]] && TOOL_ARGS+=(--app-id "$APP_ID")
  [[ -f "$REQUIREMENTS_FILE" ]] && TOOL_ARGS+=(--requirements-file "$REQUIREMENTS_FILE")
  uv run orchestrate tools import "${TOOL_ARGS[@]}"
fi

# ── 3. Agent ──────────────────────────────────────────────────────────────────
if [[ -n "$AGENT_FILE" ]]; then
  echo "▶ Importing agent: $AGENT_FILE"
  uv run orchestrate agents import --file "$AGENT_FILE"
fi

echo ""
echo "✅ Deploy complete."
echo "   Chat:       $WO_INSTANCE_URL/chat"
echo "   Connectors: $WO_INSTANCE_URL/manage/connectors  ← promote Draft → Live here"
