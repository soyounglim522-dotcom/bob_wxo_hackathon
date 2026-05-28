# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

This is the **watsonx Orchestrate Hackathon Bundle** - a comprehensive toolkit for building and deploying enterprise AI agents to IBM watsonx Orchestrate using the Agent Development Kit (ADK). The bundle enables developers to use coding agents (Bob/Bob Shell) to rapidly build production-ready agents with Python tools, YAML configurations, and direct deployment to hosted Orchestrate instances.

### Core Technologies

- **Python 3.11-3.13** (NOT 3.14 - the ADK package explicitly requires <3.14)
- **ibm-watsonx-orchestrate** CLI - ADK command-line interface
- **pytest** - Unit testing framework
- **Pydantic** - Data validation and schema definition
- **requests** - HTTP client for external API integration

### Architecture

The ADK follows a three-primitive model:

1. **Tools** - Python functions decorated with `@tool`, containing business logic
2. **Agents** - YAML specifications defining LLM behavior, instructions, and tool/collaborator bindings
3. **Connections** - YAML configurations for external API authentication (OAuth, API keys, basic auth)

Agents come in two flavors:
- **Collaborator agents** - Workers that execute tools directly
- **Manager agents** - Pure routers that delegate to collaborator agents (no tools of their own)

## Building and Running

### Initial Setup

```bash
# Install Python 3.12 (recommended version)
brew install python@3.12  # macOS
# or: sudo apt install python3.12 python3.12-venv  # Linux

# Create virtual environment
python3.12 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install ADK CLI
pip install ibm-watsonx-orchestrate
orchestrate --version

# Configure environment (one-time)
orchestrate env add --name hackathon \
    --url $WO_INSTANCE_URL \
    --iam-url $WO_IAM_URL \
    --type $WO_AUTH_TYPE
orchestrate env activate hackathon --api-key $WO_INSTANCE_API_KEY
```

**Critical**: For non-production instances (staging/test), you MUST specify `--iam-url` and `--type`. The CLI defaults only work for production. See `wxo-adk-agent/references/remote_setup.md` for tier-specific values.

### Development Workflow

```bash
# 1. Verify active environment before ANY import
orchestrate env list

# 2. Run unit tests locally (fast feedback loop)
pytest tools/

# 3. Deploy to hosted instance (in order!)
orchestrate connections add --app-id my_app
orchestrate connections configure --app-id my_app --env draft --type team --kind key_value
orchestrate connections set-credentials --app-id my_app --env draft -e token=$TOKEN
orchestrate tools import --kind python --file tools/my_tool.py \
    --app-id my_app --requirements-file requirements.txt
orchestrate agents import --file agents/my_agent.yaml

# 4. Promote connection Draft → Live in UI
# Open $WO_INSTANCE_URL/manage/connectors and click "Paste Draft Credentials"

# 5. Test in hosted chat
# Navigate to $WO_INSTANCE_URL/chat and interact with your agent
```

**No local server required** - The ADK CLI talks directly to the hosted instance. Skip `orchestrate server start` entirely.

### Testing

- **Unit tests**: `pytest tools/` - Mock HTTP boundaries, test ToolResponse shapes
- **Integration tests**: Hosted chat UI - Where LLM behavior actually runs
- **Journey Success tests**: JSON test cases uploaded via HTTP API, graded by the platform

## Development Conventions

### Naming Convention (Critical)

**Filename stem == @tool function name == agent YAML name == tools: list entry**

```
tools/get_weather.py           # filename stem
  └─ def get_weather(...)      # function name
agents/weather_agent.yaml
  ├─ name: weather_agent       # YAML name field
  └─ tools: [get_weather]      # exact match required
connections/openweather.yaml
  └─ app_id: openweather       # matches ExpectedCredentials
```

This three-way match eliminates the #1 pitfall (name drift). Renaming one requires renaming all.

### Project Structure

```
my-agent/
  agents/           # One YAML per agent
    my_agent.yaml
  tools/            # One @tool per file, co-located tests
    my_tool.py
    my_tool_test.py
  connections/      # One YAML per external app
    my_app.yaml
  tests/            # Journey Success test cases (JSON)
    scenario.json
  .env              # Never commit - copy from starter/env.example
  requirements.txt  # Pinned dependencies
```

### Tool Development Rules

1. **Always return `ToolResponse[T]`** - Never raise exceptions. Wrap errors in `ErrorDetails` so agent instructions can handle them gracefully.

2. **Google-style docstrings required** - The LLM reads these to decide when to call tools:
   ```python
   """
   One-line summary.

   Args:
       param: Description (required for every parameter).

   Returns:
       Description of ToolResponse contents.
   """
   ```

3. **Declare credentials** - Even if empty: `@tool(expected_credentials=[...])`

4. **Snake_case function names** - Must match filename stem and YAML references

### Agent YAML Guidelines

- **Default LLM**: `groq/openai/gpt-oss-120b` (used by 278/285 production agents)
- **Default style**: `default` (not `react` unless you need explicit chain-of-thought)
- **Manager agents**: Always `tools: []` and non-empty `collaborators:`
- **Collaborator agents**: Non-empty `tools:` and empty `collaborators: []`
- **Instructions structure**: Lead with `## Role`, then sections like `## Tool Usage Guidelines`, `## How To Use Tools`, `## Handling ToolResponse`, `## Scope Control`

### Import Order (Critical)

Always: **connections → tools → agents**

Wrong order causes silent failures where agents load but tool calls 404.

### Common Pitfalls to Avoid

1. **Name drift** - Keep filename/function/YAML names synchronized
2. **Manager with tools** - Managers route only, never own tools
3. **Missing docstrings** - Every arg needs documentation under `Args:`
4. **Raising exceptions** - Always return ToolResponse with error_details
5. **LLM typos** - Stick to validated model strings
6. **Wrong import order** - Connections first, agents last
7. **Forgetting env check** - Run `orchestrate env list` before every import
8. **Wrong IAM URL** - Non-production instances need explicit `--iam-url` and `--type`

See `wxo-adk-agent/references/pitfalls.md` for detailed wrong/right examples.

## Key Files and Their Purpose

### Starter Files (Copy to New Projects)
- `starter/INSTALL.md` - Platform-specific installation instructions
- `starter/requirements.txt` - Pinned dependencies (Python 3.11-3.13 only)
- `starter/env.example` - Environment variable template
- `starter/project_layout.md` - Recommended directory structure

### wxo-adk-agent Skill (Drop into ~/.bob/skills/)
- `SKILL.md` - Skill entry point, auto-loaded by Bob
- `references/tool_template.py` - Runnable @tool skeleton with ToolResponse inlined
- `references/tool_test_template.py` - pytest template with mocks
- `references/agent_collaborator.yaml` - Worker agent template
- `references/agent_manager.yaml` - Router agent template
- `references/connection_basic_auth.yaml` - key_value/basic auth configs
- `references/connection_oauth.yaml` - OAuth flow configuration
- `references/yaml_schema.md` - Complete field reference
- `references/deploy_recipe.md` - End-to-end deployment commands
- `references/evaluation_template.json` - Journey Success test case skeleton
- `references/evaluation_recipe.md` - Test case upload and grading rules
- `references/pitfalls.md` - Seven common mistakes with solutions
- `references/remote_setup.md` - Environment registration and IAM configuration

## Hackathon Use Cases (Tiered by Complexity)

### Tier 1 - Single Tool (~2 hours)
- PTO balance lookup
- GitHub PR digest
- Next meeting finder
- Expense lookup
- Weather travel reminder

### Tier 2 - Multi-Tool Agent (~½ day)
- IT helpdesk (KB → ticket → status)
- Sales lead enricher
- RFP tracker
- Document summarizer

### Tier 3 - Manager + Collaborators (full day)
- Employee onboarding orchestrator
- Customer support triage
- Finance close assistant

## Journey Success Evaluation

Test cases are JSON files that define:
- User prompt that starts the conversation
- Required tool calls in order (DAG structure)
- Argument matching rules (strict/fuzzy/optional)
- Keywords the final response must contain

Judges run tests from the agent's "Tests" tab in the Orchestrate UI. The platform executes the full trajectory and grades:
1. Tool call coverage
2. Tool call ordering
3. Per-argument matching
4. Text response keywords

Upload via HTTP API (no CLI command):
```bash
TOKEN=$(curl -X POST "$WO_IAM_URL/siusermgr/api/1.0/apikeys/token" \
    -H "Content-Type: application/json" \
    -d "{\"apikey\":\"$WO_INSTANCE_API_KEY\"}" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

AGENT_ID=$(curl -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agents" \
    | python3 -c "import sys,json; print(next(a['id'] for a in json.load(sys.stdin) if a['name']=='my_agent'))")

curl -X POST -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agent/$AGENT_ID/test_case/v2" \
    -F "file=@tests/my_test.json;type=application/json"
```

## Security and Best Practices

- Never commit `.env` files - use `.gitignore`
- Store API keys in environment variables, not code
- Use Draft environment for development, promote to Live for production
- Always specify `--requirements-file` when importing tools
- Run `pytest` before every deployment
- Verify active environment with `orchestrate env list` before imports
- Keep tool functions focused and single-purpose
- Mock external APIs in tests at the HTTP boundary
- Use `ToolResponse` error handling instead of exceptions

## Getting Help

- Full documentation in `wxo-adk-agent/references/`
- Hackathon flow overview in `HACKATHON.md`
- Installation troubleshooting in `starter/INSTALL.md`
- Common failures table in `references/deploy_recipe.md`
- Pitfall examples in `references/pitfalls.md`
