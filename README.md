# watsonx Orchestrate Hackathon Bundle

Build and deploy enterprise AI agents to IBM watsonx Orchestrate using the Agent Development Kit (ADK). Describe what you want to build, Bob generates the code, and you deploy straight to a shared hosted instance — no Docker, no local server.

## 1. Get repo and Bob

### Bob

1. Go to [bob.ibm.com/trial](https://bob.ibm.com/trial)
2. Signup
2. Download Bob or Bob Shell for your platform
3. Install
5. Sign in

### Repo

Go to [Hackathon repo](https://github.com/colehurwitz/bob_wxo_hackathon.git)

```bash
# Clone and cd into the repo
$ git clone https://github.com/colehurwitz/bob_wxo_hackathon.git
$ cd bob_wxo_hackathon
```

You are all set! Open the directory with Bob or run `bob` if you installed Bob Shell

> This guide is written for Bob (Bob IDE) but Bob Shell also will work

## 2. Join watsonx Orchestrate instance

1. Sign in to [cloud.ibm.com](https://cloud.ibm.com/)
2. Go to [Notifications](https://cloud.ibm.com/notifications)
3. Find invitation and join
4. Go to [Resources](https://cloud.ibm.com/resources)
5. Search for `watsonx Orchestrate-hackathon` and select it

## 3. Setup Bob

Copy the MCP server config and skills into Bob's `.bob` config directory so it can talk to watsonx Orchestrate and load the agent-building skill. There are many mechanisms for both but we will simply copy the files to the right location in the config directory.

```bash
# Create Bob's config directory
mkdir -p .bob

# Register the Orchestrate MCP server
cp mcp/mcp.json .bob/mcp.json

# Load the wxo-adk-agent skill (provides templates + instructions Bob needs)
cp -r skills .bob/skills
```

That's it! We've configured:

- [ibm-watsonx-orchestrate-mcp-server](https://developer.watson-orchestrate.ibm.com/mcp_server/wxOmcp_docs_server)
- **wxo-adk-agent skill** - streamlined Skill for building wxO agents

> If the MCP server doesn't connect, try restarting Bob after copying it over — it picks up `mcp.json` and skills on startup.

## 4. Setup dev env

`ibm-watsonx-orchestrate` requires **Python 3.11–3.13** (not 3.14).

This guide uses [uv](https://astral.sh/uv) and it's pip-compatible interface. If you want to use different tooling, go for it!

### macOS / Linux

```bash
# Install uv
$ curl -LsSf https://astral.sh/uv/install.sh | sh

# Create venv with a compatible Python version and install the ADK
$ uv sync

# Verify
$ uv run orchestrate --version
ADK Version: 2.x.x
```

> Don't want to curl + pipe to bash? View other [install options](https://docs.astral.sh/uv/getting-started/installation/).

### Windows (PowerShell)

```powershell

# Install uv
$ powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Clone and cd into the repo
$ git clone https://github.com/colehurwitz/bob_wxo_hackathon.git
$ cd bob_wxo_hackathon

# Create venv and install
$ uv sync

# Verify
$ uv run orchestrate --version
```

### Register the Orchestrate environment

> This guide will assume macOS / Linux from now on

```bash
# Create .env file
$ cp env.example .env

# Load credentials
$ source .env   # or set the variables manually

# Register
$ uv run orchestrate env add \
    --name hackathon \
    --url $WO_INSTANCE_URL \
    --iam-url $WO_IAM_URL \
    --type $WO_AUTH_TYPE
[INFO] - Environment 'hackathon' has been created

# Activate
$ uv run orchestrate env activate hackathon --api-key $WO_INSTANCE_API_KEY

# Confirm
$ uv run orchestrate env list
```

---

## 5. Start Building

You're set up. Open Bob and describe what you want to build — Bob will generate
the tools, YAML configs, tests, and deployment commands for you.

**Example prompt:**

```
Build me a weather travel agent and upload it to Orchestrate with evaluation test cases
```

---

### Use Cases (pick one)

| Tier | Effort | Examples |
|------|--------|----------|
| **1 — Single tool** | ~2 hrs | PTO balance · GitHub PR digest · Next meeting · Expense lookup · Weather reminder |
| **2 — Multi-tool agent** | ~½ day | IT helpdesk (KB → ticket → status) · Sales lead enricher · RFP tracker · Document summarizer |
| **3 — Manager + collaborators** | full day | Employee onboarding (HR + IT + Facilities) · Support triage · Finance close assistant |

> **Free APIs great for Tier 1:** [OpenWeatherMap](https://openweathermap.org/api) (1000 calls/day) · [GitHub REST API](https://docs.github.com/en/rest) (60 req/hr, no auth) · [CoinGecko](https://www.coingecko.com/en/api) (no auth) · [Nager.Date](https://date.nager.at) holidays (no auth) · [icanhazdadjoke](https://icanhazdadjoke.com/api) (no auth) · [NewsAPI](https://newsapi.org) (100 req/day free)

---

### Development Workflow

```
tools/my_tool.py          ← @tool, ToolResponse, docstring
tools/my_tool_test.py     ← pytest mocks
connections/my_app.yaml   ← key_value | oauth | basic auth
agents/my_agent.yaml      ← name, llm, instructions, tools list
tests/my_scenario.json    ← Journey Success test case
```

**Naming rule:** filename stem == function name == YAML `name:` field == `tools:` list entry. Drift here is the #1 failure.

### Iteration loop

```bash
# 1. Run unit tests
uv run pytest tests/

# 2. Check active environment
uv run orchestrate env list

# 3. Deploy in order: connections → tools → agents
uv run orchestrate connections add --app-id my_app
uv run orchestrate connections configure --app-id my_app --env draft --type team --kind key_value
uv run orchestrate connections set-credentials --app-id my_app --env draft -e token=$TOKEN
uv run orchestrate tools import --kind python --file tools/my_tool.py --app-id my_app --requirements-file requirements.txt
uv run orchestrate agents import --file agents/my_agent.yaml

# 4. Promote Draft → Live in the UI
# Open $WO_INSTANCE_URL/manage/connectors → "Paste Draft Credentials"

# 5. Test in hosted chat
# Navigate to $WO_INSTANCE_URL/chat
```

---

### Journey Success (judging metric)

Each team uploads at least one Journey Success test case — a JSON file describing:

- The user prompt that starts the conversation
- The tools the agent must call, in order
- Argument matching rules (`strict` / `fuzzy` / `optional`)
- Keywords the final response must contain

Judges click **Run** in the agent's **Tests** tab. The platform executes the full trajectory and shows per-goal pass/fail. Teams are ranked by how many test cases pass.

Upload via HTTP API:

```bash
TOKEN=$(curl -X POST "$WO_IAM_URL/siusermgr/api/1.0/apikeys/token" \
    -H "Content-Type: application/json" \
    -d "{\"apikey\":\"$WO_INSTANCE_API_KEY\"}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

AGENT_ID=$(curl -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agents" \
    | python3 -c "import sys,json; print(next(a['id'] for a in json.load(sys.stdin) if a['name']=='my_agent'))")

curl -X POST -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agent/$AGENT_ID/test_case/v2" \
    -F "file=@tests/my_test.json;type=application/json"
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `orchestrate: command not found` | Prefix with `uv run` |
| `Scope not found` on `env add` (production) | Wrong IAM URL — must be `https://iam.cloud.ibm.com` with no path suffix |
| `Scope not found` on `env add` (staging) | Add `--iam-url https://iam.platform.test.saas.ibm.com --type mcsp_v1` to `env add` |
| Tool doesn't appear after import | Missing `--requirements-file` flag |
| Agent doesn't call tool | Connection not promoted to Live, or tool name mismatch |
| Test case upload fails | Use `-F "file=@...;type=application/json"` (not `-d`) |
| Interactive API-key prompt on `env activate` | Pass `--api-key $WO_INSTANCE_API_KEY` — the CLI does not read `WO_*` env vars |

---

## Reference

- Official docs: [developer.watson-orchestrate.ibm.com](https://developer.watson-orchestrate.ibm.com)
- ADK package: [ibm-watsonx-orchestrate on PyPI](https://pypi.org/project/ibm-watsonx-orchestrate/)
- IBM Bob docs: [bob.ibm.com](https://bob.ibm.com)
