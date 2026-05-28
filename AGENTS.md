# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

Python 3.11–3.13 **only** (NOT 3.14 — `ibm-watsonx-orchestrate` pins `<3.14,>=3.11`)

## Commands

Prefix every python related command with `uv run` to make sure that the correct python env is loaded e.g.

- `uv run pytest`
- `uv run orchestrate`
- `uv run ruff check`

```bash
# Test
uv run pytest tools/                    # unit tests for all tools
uv run pytest tools/my_tool_test.py     # single tool test

# Deploy (order is mandatory: connections → tools → agents)
# 1. Register and activate environment (one-time setup)
printf 'Y\n' | uv run orchestrate env add \
  --name hackathon \
  --url "$WO_INSTANCE_URL" \
  --type ibm_iam \
  --iam-url "https://iam.cloud.ibm.com"

uv run orchestrate env activate hackathon --api-key "$WO_INSTANCE_API_KEY"
uv run orchestrate env list             # verify active environment

# 2. Deploy in order: connections → tools → agents
uv run orchestrate connections import --file connections/my_app.yaml
uv run orchestrate tools import --kind python --file tools/my_tool.py --app-id my_app
uv run orchestrate agents import --file agents/my_agent.yaml

# 3. Promote Draft → Live
# Use the web UI at $WO_INSTANCE_URL/manage/connectors — no CLI command for this
```

## Authentication Facts

**Non-interactive authentication works**: Use `orchestrate env activate <env> --api-key "$KEY"`. The interactive prompt only appears when you omit `--api-key`.

**Environment variables are ignored**: The CLI does NOT read `WO_*` environment variables for authentication. You must use the `--api-key` flag or respond to the interactive prompt.

**IAM URL must be the base URL**: Use `https://iam.cloud.ibm.com` (no `/identity/token` suffix). The CLI appends the correct path internally.

## Common Deployment Issues

### Issue 1: "Error getting IBM_IAM Token" or HTTP 404 on activate

**Cause**: Wrong or stale IAM URL registered with the environment.

**Fix**: Re-register with the correct base IAM URL:
```bash
printf 'Y\n' | uv run orchestrate env add \
  --name hackathon \
  --url "$WO_INSTANCE_URL" \
  --type ibm_iam \
  --iam-url "https://iam.cloud.ibm.com"

uv run orchestrate env activate hackathon --api-key "$WO_INSTANCE_API_KEY"
```

The IAM URL is the base (`https://iam.cloud.ibm.com`) with no `/identity/token` suffix. `env add` is idempotent — pipe `Y` to confirm the overwrite prompt.

### Issue 2: "cannot import name 'tool' from 'ibm_watsonx_orchestrate'"

**Cause**: Wrong import path in your tool file.

**Fix**: Use the correct import:
```python
from ibm_watsonx_orchestrate.agent_builder.tools import tool
```

See `skills/wxo-adk-agent/references/tool_template.py` for the correct pattern.

### Issue 3: "The token found for environment 'hackathon' is missing or expired"

**Cause**: Environment not activated or token expired.

**Fix**: Re-activate with the API key:
```bash
uv run orchestrate env activate hackathon --api-key "$WO_INSTANCE_API_KEY"
```

## Critical Naming Rule

**filename stem == `@tool` function name == agent YAML `name:` field == `tools:` list entry**

```
tools/get_weather.py  →  def get_weather(...)  →  agents/weather_agent.yaml tools: [get_weather]
```

Violating this causes silent tool binding failures (Pitfall #1).

## Code Style

- One `@tool` function per `.py` file; one agent per `.yaml`; one `app_id` per connection YAML
- snake_case everywhere; match stems across all three file types
- `ToolResponse[T]` wraps all returns — never raise exceptions inside `@tool`; return `ToolResponse(error_details=..., tool_output=None)` on failure
- `ErrorDetails` and `ToolResponse` must be **inlined** in each tool file (not imported from a shared module)
- Every `@tool` docstring requires one-line summary + `Args:` block (every param) + `Returns:` (LLM reads this)
- LLM field: `groq/openai/gpt-oss-120b` (default); `react` style only for explicit chain-of-thought
- Manager agents: `tools: []`, non-empty `collaborators:`; Collaborator agents: non-empty `tools:`, `collaborators: []`

## Shared Hackathon Instance

All participants share one hosted instance (do not create new instances):

```
WO_INSTANCE_URL=https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146
WO_INSTANCE_API_KEY=***REMOVED***
WO_IAM_URL=https://iam.cloud.ibm.com
WO_AUTH_TYPE=ibm_iam
WO_ENV_NAME=hackathon
```

## Journey Success Tests

Test cases in `tests/*.json` — see [`evaluation_template.json`](skills/wxo-adk-agent/references/evaluation_template.json). Each `goal_details` entry is either `type: tool_call` (arg matching: `strict`/`fuzzy`/`optional`) or `type: text` (keyword matching). All goals must pass.