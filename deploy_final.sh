#!/bin/bash
set -e

echo "Deploying test agent to Watsonx Orchestrate..."

# --- Config -----------------------------------------------------------------
WO_ENV_NAME="hackathon"
WO_INSTANCE_URL="https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146"
WO_IAM_URL="https://iam.cloud.ibm.com"   # IBM Cloud production IAM base (no /identity/token suffix)
WO_AUTH_TYPE="ibm_iam"
# API key is read from $WO_INSTANCE_API_KEY in the environment so it does not
# live in this file. Export it before running, e.g.:
#   export WO_INSTANCE_API_KEY="k1:..."   (or your IBM Cloud API key)
: "${WO_INSTANCE_API_KEY:?Set WO_INSTANCE_API_KEY in your environment first}"

cd "$(dirname "$0")"

# --- Auth (the part bob was missing) ---------------------------------------
# The CLI does NOT read WO_* env vars for auth. You must register the env and
# activate it with --api-key (non-interactive). 'env add' is idempotent; pipe
# 'Y' to confirm the overwrite prompt. The explicit --iam-url matters: a stale
# or wrong IAM URL yields "Error getting IBM_IAM Token / 404".
echo -e "\n0. Registering + activating env '$WO_ENV_NAME'..."
printf 'Y\n' | uv run orchestrate env add \
    --name "$WO_ENV_NAME" --url "$WO_INSTANCE_URL" \
    --type "$WO_AUTH_TYPE" --iam-url "$WO_IAM_URL"
uv run orchestrate env activate "$WO_ENV_NAME" --api-key "$WO_INSTANCE_API_KEY"
uv run orchestrate env list | grep active

# --- Import: connections -> tools -> agents --------------------------------
echo -e "\n1. Importing connection..."
uv run orchestrate connections import --file connections/test_app.yaml || echo "⚠ Connection import had issues (may already exist)"

echo -e "\n2. Importing tool..."
uv run orchestrate tools import --kind python --file tools/hello_world.py || echo "✗ Tool import failed"

echo -e "\n3. Importing agent..."
uv run orchestrate agents import --file agents/test_agent.yaml || echo "✗ Agent import failed"

echo -e "\n✅ Deployment script completed!"
echo "Visit: $WO_INSTANCE_URL"
