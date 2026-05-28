#!/bin/bash
set -e

# Get fresh IAM token (with hackathon default)
echo "Getting IAM token..."
WO_INSTANCE_API_KEY="${WO_INSTANCE_API_KEY:-***REMOVED***}"
TOKEN=$(curl -s -X POST "https://iam.cloud.ibm.com/identity/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$WO_INSTANCE_API_KEY" | \
  python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

BASE_URL="https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146"

echo "Token obtained: ${TOKEN:0:50}..."

# Step 1: Create connection using orchestrate CLI with proper env setup
echo -e "\n1. Setting up orchestrate environment..."
export WO_INSTANCE_URL="${WO_INSTANCE_URL:-$BASE_URL}"
export WO_IAM_URL="${WO_IAM_URL:-https://iam.cloud.ibm.com}"
export WO_AUTH_TYPE="${WO_AUTH_TYPE:-ibm_iam}"

# Update config with fresh token
mkdir -p ~/.orchestrate
cat > ~/.orchestrate/config.yaml << EOF
environments:
  hackathon:
    url: $WO_INSTANCE_URL
    auth_type: $WO_AUTH_TYPE
    api_key: $WO_INSTANCE_API_KEY
    iam_url: $WO_IAM_URL
    token: $TOKEN
active_environment: hackathon
EOF

echo -e "\n2. Importing connection..."
cd /Users/colehurwitz/bob_wxo_hackathon
uv run orchestrate connections import --file connections/test_app.yaml || echo "Connection may already exist"

echo -e "\n3. Importing tool..."
uv run orchestrate tools import --kind python --file tools/hello_world.py --app-id test_app || echo "Tool import failed"

echo -e "\n4. Importing agent..."
uv run orchestrate agents import --file agents/test_agent.yaml || echo "Agent import failed"

echo -e "\n✅ Deployment complete!"
echo "Visit: $BASE_URL"
