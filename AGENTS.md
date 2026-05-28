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
pytest tools/                    # unit tests for all tools
pytest tools/my_tool_test.py     # single tool test

# Deploy (order is mandatory: connections → tools → agents)
orchestrate env list             # verify active environment first (missing step = silent fail)
orchestrate connections add --file connections/my_app.yaml
orchestrate connections configure --connection-name my_app --env draft
orchestrate connections set-credentials --connection-name my_app --env draft
orchestrate tools import --file tools/my_tool.py --app-id my_app --requirements-file requirements.txt
orchestrate agents import --file agents/my_agent.yaml

# Promote Draft → Live
# Use the web UI at $WO_INSTANCE_URL/manage/connectors — no CLI command for this
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