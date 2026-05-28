# Test Agent Deployment Instructions

## What Was Created

I've set up a complete test agent with the following files:

1. **Tool**: `tools/hello_world.py` - A simple greeting tool
2. **Connection**: `connections/test_app.yaml` - Connection configuration
3. **Agent**: `agents/test_agent.yaml` - Agent configuration
4. **Deploy Script**: `deploy_final.sh` - Automated deployment script

## Prerequisites

- Python 3.11–3.13 environment (✅ Already set up with uv)
- All dependencies installed (✅ Already done via `uv sync`)
- Environment variables set (see below)

## Environment Setup

**IMPORTANT**: Set these environment variables before deploying:

```bash
export WO_INSTANCE_URL="https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146"
export WO_INSTANCE_API_KEY="<YOUR_API_KEY>"
export WO_IAM_URL="https://iam.cloud.ibm.com"
export WO_AUTH_TYPE="ibm_iam"
```

> **Security Note**: Never commit API keys to git. Use environment variables or a `.env` file (which is gitignored).

## Deployment Steps

### Step 1: Register and Activate Environment

The orchestrate CLI **does support non-interactive authentication** using the `--api-key` flag:

```bash
cd /Users/colehurwitz/bob_wxo_hackathon

# Register the environment (idempotent - safe to run multiple times)
printf 'Y\n' | uv run orchestrate env add \
  --name hackathon \
  --url "$WO_INSTANCE_URL" \
  --type ibm_iam \
  --iam-url "https://iam.cloud.ibm.com"

# Activate with API key (non-interactive)
uv run orchestrate env activate hackathon --api-key "$WO_INSTANCE_API_KEY"

# Verify
uv run orchestrate env list
```

**Key Facts About Authentication:**

1. **Non-interactive auth works**: Use `orchestrate env activate <env> --api-key "$KEY"`. The interactive prompt only appears when you omit `--api-key`.

2. **Environment variables are ignored**: The CLI does NOT read `WO_*` environment variables for authentication. You must use the `--api-key` flag or respond to the interactive prompt.

3. **IAM URL must be the base URL**: Use `https://iam.cloud.ibm.com` (no `/identity/token` suffix). The CLI appends the correct path internally.

### Step 2: Deploy in Order

**Mandatory deployment order**: connections → tools → agents

```bash
# 1. Import connection
uv run orchestrate connections import --file connections/test_app.yaml

# 2. Import tool
uv run orchestrate tools import \
  --kind python \
  --file tools/hello_world.py \
  --app-id test_app

# 3. Import agent
uv run orchestrate agents import --file agents/test_agent.yaml
```

### Step 3: Use the Automated Script

Or run the complete deployment with the provided script:

```bash
chmod +x deploy_final.sh
./deploy_final.sh
```

The script handles environment activation and deploys all components in the correct order.

## Testing the Agent

Once deployed, visit the Orchestrate UI:
```
https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146
```

Try these prompts:
- "Hello!"
- "Greet me as John"
- "Say hello to Alice"

## Common Issues and Solutions

### Issue 1: "The token found for environment 'hackathon' is missing or expired"

**Cause**: Environment not activated or token expired.

**Solution**: Re-activate with the API key:
```bash
uv run orchestrate env activate hackathon --api-key "$WO_INSTANCE_API_KEY"
```

### Issue 2: "Error getting IBM_IAM Token" or HTTP 404 on activate

**Cause**: Wrong or stale IAM URL registered with the environment.

**Solution**: Re-register the environment with the correct base IAM URL:
```bash
printf 'Y\n' | uv run orchestrate env add \
  --name hackathon \
  --url "$WO_INSTANCE_URL" \
  --type ibm_iam \
  --iam-url "https://iam.cloud.ibm.com"

uv run orchestrate env activate hackathon --api-key "$WO_INSTANCE_API_KEY"
```

**Important**: The IAM URL must be the base URL (`https://iam.cloud.ibm.com`) without any path suffix like `/identity/token`. The CLI handles the full path internally.

### Issue 3: "cannot import name 'tool' from 'ibm_watsonx_orchestrate'"

**Cause**: Wrong import path in your tool file.

**Solution**: Use the correct import:
```python
from ibm_watsonx_orchestrate.agent_builder.tools import tool
```

**NOT**:
```python
from ibm_watsonx_orchestrate import tool  # ❌ Wrong
```

See `skills/wxo-adk-agent/references/tool_template.py` for the correct pattern.

### Issue 4: Tool doesn't appear after import

**Cause**: Missing `--app-id` flag or tool name mismatch.

**Solution**: 
- Always specify `--app-id` matching your connection
- Ensure filename stem == function name == agent YAML `tools:` entry

### Issue 5: Agent doesn't call the tool

**Cause**: Connection not promoted to Live environment, or tool name mismatch.

**Solution**:
1. Open the Orchestrate UI → Manage → Connectors
2. Find your connection and promote Draft credentials to Live
3. Verify tool name matches exactly across all files

## Files Created

```
bob_wxo_hackathon/
├── tools/
│   └── hello_world.py          # Simple greeting tool
├── connections/
│   └── test_app.yaml           # Connection config
├── agents/
│   └── test_agent.yaml         # Agent config
└── deploy_final.sh             # Deployment script
```

## Reference

For more details, see:
- `AGENTS.md` - Project-specific deployment guidelines
- `skills/wxo-adk-agent/references/deploy_recipe.md` - Complete CLI reference
- `skills/wxo-adk-agent/references/pitfalls.md` - Common mistakes and fixes