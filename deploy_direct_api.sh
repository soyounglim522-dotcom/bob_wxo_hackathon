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

echo "Token obtained successfully"

# Step 1: Create/update connection via API
echo -e "\n1. Creating connection 'test_app'..."
CONN_RESPONSE=$(curl -s -X POST "$BASE_URL/v2/connections" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test_app",
    "description": "Simple test application",
    "datasource_type": "test_app",
    "properties": {
      "server_url": "https://api.example.com"
    }
  }')
echo "Connection response: $CONN_RESPONSE"

# Step 2: Upload Python tool
echo -e "\n2. Uploading tool 'hello_world'..."
cd /Users/colehurwitz/bob_wxo_hackathon

# Create a multipart form data request
TOOL_RESPONSE=$(curl -s -X POST "$BASE_URL/v2/tools" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@tools/hello_world.py" \
  -F "kind=python" \
  -F "app_id=test_app")
echo "Tool response: $TOOL_RESPONSE"

# Step 3: Import agent
echo -e "\n3. Importing agent 'test_agent'..."
AGENT_RESPONSE=$(curl -s -X POST "$BASE_URL/v2/agents" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @agents/test_agent.yaml)
echo "Agent response: $AGENT_RESPONSE"

echo -e "\n✅ Deployment complete!"
echo "Visit: $BASE_URL"
