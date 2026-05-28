# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

Python 3.11–3.13 **only** (NOT 3.14 — `ibm-watsonx-orchestrate` pins `<3.14,>=3.11`)

## Commands

Prefix every python related command with `uv run` to make sure that the correct python env is loaded e.g.

- `uv run orchestrate`
- `uv run pytest`
- `uv run ruff check`

```bash
# Test
uv run pytest tools/                    # unit tests for all tools
uv run pytest tools/my_tool_test.py     # single tool test

# Auth — CLI does NOT read WO_* env vars; you must activate explicitly
source .env   # load WO_* vars into shell
uv run orchestrate env add \
    --name "$WO_ENV_NAME" --url "$WO_INSTANCE_URL" \
    --type "$WO_AUTH_TYPE" --iam-url "$WO_IAM_URL"   # idempotent
uv run orchestrate env activate "$WO_ENV_NAME" --api-key "$WO_INSTANCE_API_KEY"
uv run orchestrate env list      # confirm active before any import

# Deploy (order is mandatory: connections → tools → agents)
uv run orchestrate connections import --file connections/my_app.yaml
uv run orchestrate tools import --kind python --file tools/my_tool.py \
    --app-id my_app --requirements-file requirements.txt
uv run orchestrate agents import --file agents/my_agent.yaml

# Promote Draft → Live
# Use the web UI at $WO_INSTANCE_URL/manage/connectors — no CLI command for this

# Or run the generic deploy script (handles auth + import automatically):
# bash scripts/deploy.sh
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

## Journey Success Tests

Test cases in `tests/*.json` — see [`evaluation_template.json`](skills/wxo-adk-agent/references/evaluation_template.json). Each `goal_details` entry is either `type: tool_call` (arg matching: `strict`/`fuzzy`/`optional`) or `type: text` (keyword matching). All goals must pass.