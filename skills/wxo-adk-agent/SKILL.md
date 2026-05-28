---
name: wxo-adk-agent
description: Build and deploy a watsonx Orchestrate ADK native agent — Python @tool functions, agent YAML (collaborator or manager), connection configs, and shipping via the `orchestrate` CLI directly to a hosted Orchestrate instance (no local Docker server required). Use when the user mentions watsonx Orchestrate, wxo, WXO, Orchestrate ADK, ADK tool, ADK agent, collaborator agent, manager agent, @tool decorator, ToolResponse, agents import, tools import, env add, env activate, draft vs live, or a hackathon agent.
---

# Building a watsonx Orchestrate enterprise agent

You are helping the user build and deploy a native ADK agent for IBM watsonx
Orchestrate. The agent is composed of three primitives: **tools** (Python
functions), **agents** (YAML), and **connections** (YAML). You will author each
locally, run unit tests with `pytest`, then push the artifacts straight to a
shared hosted Orchestrate instance with the `orchestrate` CLI. No local Docker
server, no Lite stack — the CLI talks directly to the hosted instance.

## When this skill applies

- "Build me a watsonx Orchestrate agent that …"
- "Write an ADK tool for …"
- "I need a manager + collaborator setup for …"
- "How do I deploy this to Orchestrate?"
- Anything mentioning `@tool`, `ToolResponse`, `agents import`, Draft/Live connections, or `groq/openai/gpt-oss-120b`.

## Pick a target

If the user hasn't said what they're building, suggest one of these. Start with
**Tier 1** unless they explicitly want more.

### Tier 1 — Single-tool collaborator (≈ 2 hours)
1. **PTO balance lookup** (HR). One tool against a mock HR endpoint or a tiny FastAPI stub.
2. **GitHub PR digest** (dev tools). `list_open_prs(username)` against the GitHub REST API — free tokens, no enterprise auth.
3. **Next meeting** (Productivity). Google Calendar or a Notion DB stand-in.
4. **Expense lookup** (Finance). Mock Concur/SAP endpoint.
5. **Weather-aware travel reminder** (the fun one). OpenWeather — pure focus on instruction-writing.

### Tier 2 — Multi-tool collaborator (≈ half day)
6. **IT helpdesk ticket assistant**: `search_kb` → `create_ticket` → `get_ticket_status`.
7. **Sales lead enricher**: `lookup_account` → `get_recent_news` → `summarize_account`.
8. **Procurement RFP tracker**: `list_open_rfps` → `get_rfp_details` → `check_approval_status`.
9. **Document summarizer**: `list_documents` → `get_document_text` → `summarize` (Box / Drive / Dropbox).

### Tier 3 — Manager + collaborators (full day)
10. **Employee onboarding orchestrator**: HR manager → `hr_records_agent`, `it_provisioning_agent`, `facilities_agent`.
11. **Customer support triage**: support manager → `refund_agent`, `shipping_agent`, `kb_agent`.
12. **Finance close assistant**: finance manager → `journal_entries_agent`, `reconciliation_agent`, `variance_explainer_agent`.

When the upstream API is rate-limited or needs enterprise SSO, suggest mocking
it with a 20-line FastAPI server — focus on agent + tool + deploy mechanics,
not auth handshakes. Bias toward use cases that demo in a single chat turn.

## Workflow

This skill assumes the hackathon provides **a shared hosted Orchestrate
instance** that all hackers deploy to. You iterate as follows:

1. **Write code locally** — `@tool` functions in `tools/`, agent specs in
   `agents/`, connection configs in `connections/`. Tests live next to tools.
2. **Test with `pytest`** — `pytest tools/` exercises the tool's HTTP logic
   against mocks. This is your only fast feedback loop, so make it good.
3. **`orchestrate env list`** before every import — confirm the hosted env is
   the active one. Skipping this is pitfall #7.
4. **Import → hosted instance** — `connections add` → `tools import` →
   `agents import`, in that order, directly against the hosted env.
5. **Test in the hosted chat UI** — that's where the agent's LLM behavior
   actually runs.

No local server. No Docker. No Lite UI. The ADK CLI talks directly to whatever
env is active; the only "deploy target" is the hosted instance.

## Mental model

- **Tool** = a Python `@tool`-decorated function. The decorator's docstring is
  what the agent's LLM reads to decide whether to call it.
- **Agent** = a YAML spec with a `name`, an `llm`, `instructions`, a list of
  `tools` (function-name strings), and a list of `collaborators` (other agents).
- **Connection** = a YAML config naming an `app_id` and an auth kind. Tools
  declare which `app_id` they need; the ADK injects credentials at runtime.
- **Manager vs collaborator** = pure-router vs worker. Managers have empty
  `tools:` and a non-empty `collaborators:`. Collaborators are the opposite.
- **Draft vs Live** = the hosted instance keeps two credential slots per
  connection. You configure Draft during iteration; you promote to Live before
  end users see it.

## Recommended project layout

See `starter/project_layout.md` for the full picture. The one rule:

**Filename stem == `@tool` function name == agent YAML `name:` == string in `tools:`.**

Renaming one means renaming all four. The discipline kills pitfall #1 by construction.

```
my-wxo-agent/
  agents/my_agent.yaml          # name: my_agent
  tools/my_tool.py              # def my_tool(...)
  tools/my_tool_test.py
  connections/my_app.yaml       # app_id: my_app
  .env                          # copy from starter/env.example
  requirements.txt              # copy from starter/requirements.txt
```

## Step 1 — Author the tool

Copy `references/tool_template.py` and modify. Critical rules:

1. **`@tool(expected_credentials=[...])`** — always list the connections your
   tool needs. Even if it's just `[]` (no external API), keep the argument.
2. **Return `ToolResponse[T]`** — never raise. Wrap every error in
   `ErrorDetails` so the agent's "Error Handling" instructions can surface it.
3. **Google-style docstring** — one-line summary + blank line + `Args:` (every
   parameter, non-empty description) + `Returns:`. The ADK builds the LLM's
   tool schema from this; missing args mean the LLM can't call the tool.
4. **Snake_case function name** — this exact string goes in the agent YAML
   under `tools:`. Match the filename stem.

The template inlines `ToolResponse` and `ErrorDetails` so the starter has no
shared-utils dependency. The shapes are identical to the wxo-domains repo —
your code ports back unchanged if you later contribute upstream.

## Step 2 — Write a co-located test

Copy `references/tool_test_template.py` and adjust. Mock `requests` at the HTTP
boundary; assert on the `ToolResponse` shape. Two tests minimum: happy path
(200) and error path (5xx). Run with `pytest tools/`.

If `result.tool_output` raises `AttributeError`, your ADK version wraps the
return in `.content` — try `result.content.tool_output`. The template handles both.

## Step 3 — Configure a connection (only if your tool calls an external API)

Pick the right auth kind:

- `key_value` — single token or arbitrary key/value pairs. Simplest. → `references/connection_basic_auth.yaml` variant A.
- `basic` — username + password. → `references/connection_basic_auth.yaml` variant B.
- `bearer` — opaque bearer token.
- `api_key` — standard API-key header.
- `oauth_auth_code_flow` — per-user OAuth dance. → `references/connection_oauth.yaml`.
- `oauth_auth_client_credentials_flow` — machine-to-machine, no user.

Full schema in `references/yaml_schema.md`. `app_id` in the YAML must match the
`app_id` in your tool's `ExpectedCredentials(...)` and the `--app-id` you'll
pass to `orchestrate connections add`.

## Step 4 — Write the agent YAML

Two starting points:

- **Collaborator** (a worker that calls tools): copy `references/agent_collaborator.yaml`.
- **Manager** (a pure router that delegates to other agents): copy `references/agent_manager.yaml`.

Default to a single collaborator unless the agent spans multiple distinct task
types. Managers add an extra LLM hop — only worth it for ~5+ tools across
clearly separate concerns.

For instructions: lead with a `## Role` paragraph, then sections like
`## Tool Usage Guidelines`, `## How To Use Tools`, `## Handling ToolResponse`,
`## Scope Control`. Be specific about *when* to call each tool, not just *what*
it does. The function docstring already covers the *what*.

## Step 5 — Deploy to the hosted instance

One-time setup details in `references/remote_setup.md`; full deploy commands
in `references/deploy_recipe.md`. Short version:

```bash
# One-time: register the hosted env. Don't use --activate (it prompts for the
# key interactively, which breaks in non-TTY shells). Split into add + activate.
# For non-production instances you MUST set --iam-url and --type — see
# remote_setup.md for the tier-by-tier table. Defaults are correct only for prod.
orchestrate env add --name $WO_ENV_NAME --url $WO_INSTANCE_URL \
    --iam-url $WO_IAM_URL --type $WO_AUTH_TYPE
orchestrate env activate $WO_ENV_NAME --api-key $WO_INSTANCE_API_KEY

# Every deploy:
orchestrate env list                                                          # confirm hosted env is active
pytest tools/                                                                 # final local check
orchestrate connections add --app-id my_app                                   # if your tool calls an API
orchestrate connections configure --app-id my_app --env draft --type team --kind key_value
orchestrate connections set-credentials --app-id my_app --env draft -e token=$MY_APP_TOKEN
orchestrate tools import --kind python --file tools/my_tool.py \
    --app-id my_app --requirements-file requirements.txt
orchestrate agents import --file agents/my_agent.yaml

# Then open $WO_INSTANCE_URL/manage/connectors and promote Draft → Live.
# Then open $WO_INSTANCE_URL/chat and demo.
```

**Sanity check before every import**: run `orchestrate env list`. Without an
active env, the import silently goes nowhere useful — pitfall #7.

**If `env activate` fails with `Scope not found`** — your `--iam-url` is wrong
for the instance tier. That's pitfall #8, not a bad key.

## Step 6 — Upload a Journey Success test case

Once your agent answers correctly in the hosted chat, write a test case that
encodes the *correct* trajectory (which tools must be called, in what order,
with what args, leading to what kind of response). Judges will run it from the
agent's "Tests" tab in the Orchestrate UI and grade Journey Success.

Test cases live as JSON files (see `references/evaluation_template.json`) and
upload via the HTTP API — there's no `orchestrate` CLI command for hosted
test-case upload. Full schema, upload helper, and grading rules in
`references/evaluation_recipe.md`.

Short version:
```bash
# Get a JWT, find the agent id, upload the JSON as multipart.
TOKEN=$(curl -fsS -X POST "$WO_IAM_URL/siusermgr/api/1.0/apikeys/token" \
    -H "Content-Type: application/json" \
    -d "{\"apikey\":\"$WO_INSTANCE_API_KEY\"}" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
AGENT_ID=$(curl -fsS -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agents" \
    | python3 -c "import sys,json; print(next(a['id'] for a in json.load(sys.stdin) if a['name']=='my_agent'))")
curl -fsS -X POST -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agent/$AGENT_ID/test_case/v2" \
    -F "file=@tests/my_test.json;type=application/json"
```

Journey Success grades four things on each run: tool-call coverage, tool-call
ordering (the `goals` DAG), per-arg matching (`strict` / `fuzzy` / `optional`),
and text-response keywords. Plan your `goal_details` carefully — over-specifying
keywords is the #1 reason hackathon tests fail unnecessarily.

## Verification checklist

You're done when, against the hosted instance:

1. `pytest tools/` passes locally.
2. `orchestrate env list` shows the hosted env as active.
3. `orchestrate tools list` shows your tool's function name.
4. `orchestrate agents list` shows your agent.
5. `$WO_INSTANCE_URL/manage/connectors` shows your connection as connected in
   both Draft and Live.
6. The hosted chat URL shows your agent, and a demo prompt round-trips through
   the tool and returns a sensible answer.
7. Your Journey Success test case uploads cleanly
   (`{"test_case_ids":["..."],"total_test_cases":1}`), appears under the agent's
   "Tests" tab, and **passes** when run from the UI.

If any step fails, see the "Common failure → fix" table at the bottom of
`references/deploy_recipe.md`.

## Common pitfalls (one-line each)

Full wrong/right examples in `references/pitfalls.md`.

1. **`tools:` strings drift from function names** — keep the three-way match.
2. **Manager with a non-empty `tools:`** — managers route only; always `tools: []`.
3. **Missing Google docstring** — every arg under `Args:`, plus `Returns:`.
4. **Raising in a `@tool`** — always return `ToolResponse` with `error_details`.
5. **LLM string typos** — stick to `groq/openai/gpt-oss-120b`.
6. **Wrong import order** — connections → tools → agents.
7. **Forgetting `orchestrate env list` before every import** — no env active means the import goes nowhere useful.
8. **`Scope not found` on env activate** — wrong `--iam-url` for the instance tier, not a bad key. The CLI defaults assume production IAM; staging/test need explicit overrides.

## Hard-recommended defaults

- `llm: groq/openai/gpt-oss-120b` everywhere unless you have a specific reason.
- `style: default` (use `react` only if you know what chain-of-thought reasoning
  buys you for your use case).
- One `@tool` per file, filename stem matches function name.
- One agent per YAML, filename stem matches the `name:` field.
- One `app_id` per connection YAML, stem matches `app_id`.

## Reference files

- `references/tool_template.py` — runnable `@tool` skeleton with `ToolResponse`/`ErrorDetails` inlined.
- `references/tool_test_template.py` — pytest happy + error path templates.
- `references/agent_collaborator.yaml` — worker agent template.
- `references/agent_manager.yaml` — router agent template.
- `references/connection_basic_auth.yaml` — `key_value` and `basic` auth configs.
- `references/connection_oauth.yaml` — `oauth_auth_code_flow` config.
- `references/yaml_schema.md` — full field-by-field schema for agents and connections.
- `references/deploy_recipe.md` — end-to-end commands for the hosted instance (no local server required).
- `references/evaluation_template.json` — Journey Success test case skeleton with inline schema commentary.
- `references/evaluation_recipe.md` — upload helper, grading rules, common failures.
- `references/remote_setup.md` — one-time hosted instance registration + Draft → Live promotion.
- `references/pitfalls.md` — seven traps with wrong vs right code.
- `starter/INSTALL.md` — installing `orchestrate` CLI (uv-based path, plus pip fallback). Read first if you're hitting Python-version errors.
- `starter/requirements.txt` — pinned deps. Python 3.11–3.13 only (not 3.14).
- `starter/env.example` — env-var skeleton.
- `starter/project_layout.md` — recommended directory layout and naming convention.
