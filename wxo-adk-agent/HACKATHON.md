# Hackathon Flow — watsonx Orchestrate Enterprise Agents

## The pitch (30 seconds)

Hackers use a coding agent (Bob / Bob Shell) plus a custom skill we ship them to build a real enterprise agent — Python tools, agent YAML, connections — and deploy it straight to a shared hosted Orchestrate instance for demo. No Docker, no local server, no boilerplate.

## What we provide

| | |
|---|---|
| **`wxo-adk-agent` skill** | A drop-in `~/.bob/skills/` bundle. 15 files: templates, schemas, deploy recipe, 8-pitfall guide, Journey Success eval template. Auto-triggers when hackers mention "watsonx Orchestrate" / "@tool" / "agents import". |
| **Hosted Orchestrate instance** | One shared environment. Each hacker gets an instance URL + API key. |
| **12 use-case prompts** | Three tiers from 2-hour warm-up to full-day ambition. |

## The flow

```
   ┌─────────────────────────────────────────────────────────────────┐
   │  1. SETUP (15 min, once)                                        │
   │     brew install python@3.12             # Python 3.14 won't    │
   │                                          # work; package pins   │
   │                                          # <3.14,>=3.11.        │
   │     python3.12 -m venv .venv && source .venv/bin/activate       │
   │     pip install ibm-watsonx-orchestrate                         │
   │     drop wxo-adk-agent/ into ~/.bob/skills/                  │
   │     orchestrate env add  --name hackathon  --url $URL  \        │
   │                          --iam-url $IAM   --type $TYPE          │
   │     orchestrate env activate hackathon --api-key $KEY           │
   └─────────────────────────────────────────────────────────────────┘
                                  ↓
   ┌─────────────────────────────────────────────────────────────────┐
   │  2. PICK A TARGET                                               │
   │     Bob  reads the skill, suggests one of 12 use cases.         │
   │     Default: Tier 1 (single tool, demo in one chat turn).       │
   └─────────────────────────────────────────────────────────────────┘
                                  ↓
   ┌─────────────────────────────────────────────────────────────────┐
   │  3. BUILD (Bob does the typing)                                 │
   │       tools/my_tool.py           ← @tool, ToolResponse, docstr  │
   │       tools/my_tool_test.py      ← pytest mocks                 │
   │       connections/my_app.yaml    ← key_value | oauth | basic    │
   │       agents/my_agent.yaml       ← name, llm, instructions      │
   └─────────────────────────────────────────────────────────────────┘
                                  ↓
   ┌─────────────────────────────────────────────────────────────────┐
   │  4. TEST LOCALLY                                                │
   │     pytest tools/         ← only fast feedback loop, no server  │
   └─────────────────────────────────────────────────────────────────┘
                                  ↓
   ┌─────────────────────────────────────────────────────────────────┐
   │  5. DEPLOY TO HOSTED INSTANCE                                   │
   │     orchestrate env list                  ← confirm env active  │
   │     orchestrate connections add/configure/set-credentials       │
   │     orchestrate tools import                                    │
   │     orchestrate agents import                                   │
   │     → promote Draft → Live in the connections UI                │
   └─────────────────────────────────────────────────────────────────┘
                                  ↓
   ┌─────────────────────────────────────────────────────────────────┐
   │  6. DEMO IN HOSTED CHAT                                         │
   │     $WO_INSTANCE_URL/chat → pick agent → send prompt → 🎤       │
   └─────────────────────────────────────────────────────────────────┘
                                  ↓
   ┌─────────────────────────────────────────────────────────────────┐
   │  7. UPLOAD JOURNEY SUCCESS TEST CASE                            │
   │     write tests/<scenario>.json     ← schema in skill bundle    │
   │     POST /v1/orchestrate/agent/<id>/test_case/v2  (multipart)   │
   │     → judges press "Run" in the agent's Tests tab and grade     │
   │       tool ordering + arg matching + final-text keywords.       │
   └─────────────────────────────────────────────────────────────────┘
```

## Use-case tiers (let hackers self-select)

| Tier | Effort | Examples |
|---|---|---|
| **1 — Single tool** | ~2 hrs | PTO balance · GitHub PR digest · Next meeting · Expense lookup · Weather travel reminder |
| **2 — Multi-tool agent** | ~½ day | IT helpdesk (KB → ticket → status) · Sales lead enricher · RFP tracker · Document summarizer |
| **3 — Manager + collaborators** | full day | Employee onboarding (HR + IT + Facilities) · Support triage (refund + shipping + KB) · Finance close assistant |

## Journey Success — the judging metric

Every team uploads at least one **Journey Success** test case as part of the
submission. Each test case is a JSON file describing:

- the user prompt that kicks off the conversation
- the tool(s) the agent must call, in order
- the argument values each tool call must match (`strict` / `fuzzy` / `optional`)
- the keywords the final response must contain

Judges open the agent's "Tests" tab in the Orchestrate UI and click **Run**.
The platform executes the full trajectory and shows per-goal pass/fail.
Submissions are ranked by how many of their declared test cases pass.

This makes judging fast and objective. Teams self-grade by writing test cases
that match what their agent actually does; the platform verifies. A team that
*claims* the agent handles a 3-step workflow but only wrote a 1-step test case
gets less credit than a team whose 3-step test case passes end-to-end.

## Why this works for a hackathon

- **Zero environment setup** — no `orchestrate server start`, no Docker. Just `pip` + the skill + an env entry.
- **Coding-agent native** — hackers describe what they want in English; Bob writes the @tool function, the YAML, the deploy commands, AND the Journey Success test case. The skill keeps it on-rails.
- **Real deploy, not a demo stub** — every team ships to the same hosted instance. Judging is "open this URL in the hosted chat and try it" plus "run their Journey Success test."
- **Tested end-to-end** — the skill's templates have been validated against the live ADK (`ibm-watsonx-orchestrate 2.0.0`): tool decorator, agent YAML, connection YAML, every CLI command and flag, and the v2 test-case upload endpoint.

## What we need from organizers before kickoff

1. Provision the shared hosted Orchestrate instance (or have each hacker spin up
   their own free trial — see "How hackers get their instance" below).
2. Generate one API key per hacker (or one team key per team).
3. Hand out a one-pager with **five** values: `WO_INSTANCE_URL`, `WO_INSTANCE_API_KEY`, `WO_IAM_URL`, `WO_AUTH_TYPE` (e.g. `mcsp_v1` for staging), plus the install command and skill bundle link.
4. Pick the demo / judging window — each team gets ~3 minutes in the hosted chat, plus the platform auto-runs their uploaded Journey Success tests.
5. Set a minimum bar — e.g. "at least one Journey Success test case must pass" — so submissions converge on something runnable, not just a chat-demo trick.

> **One landmine to call out in the kickoff:** the ADK CLI's default auth
> detection only works for production instances. For staging, hackers must
> set `--iam-url https://iam.platform.test.saas.ibm.com` and
> `--type mcsp_v1` on `env add`. The skill documents this — but it's the
> single most likely thing to derail a team in the first 15 minutes.

## How hackers install the ADK

`ibm-watsonx-orchestrate` requires Python **3.11, 3.12, or 3.13** — `pip` will
refuse to install on Python 3.14 (the current macOS Homebrew default).

### macOS

```bash
brew install python@3.12
python3.12 -m venv .venv
source .venv/bin/activate
pip install ibm-watsonx-orchestrate
orchestrate --version
```

### Linux (Debian/Ubuntu)

```bash
sudo apt install python3.12 python3.12-venv
python3.12 -m venv .venv
source .venv/bin/activate
pip install ibm-watsonx-orchestrate
orchestrate --version
```

### Windows

```powershell
# Install Python 3.12 from python.org first.
py -3.12 -m venv .venv
.venv\Scripts\activate
pip install ibm-watsonx-orchestrate
orchestrate --version
```

### Important reminder

`orchestrate` is only on PATH while the venv is activated. Every new terminal
tab: `source .venv/bin/activate` (or `.venv\Scripts\activate` on Windows)
before running CLI commands. The "command not found" error almost always means
the venv isn't active.

Full install guide (with troubleshooting + an optional `uv` shortcut for those
who already have it): `wxo-adk-agent/starter/INSTALL.md`.

## How hackers get their instance (free-trial path)

If your event doesn't pre-provision a shared instance, every hacker can spin
up their own 30-day Orchestrate trial. No credit card, no IBM Cloud subscription
required — just an IBMid (free).

### Sign up

1. Go to **https://www.ibm.com/products/watsonx-orchestrate** and click
   **Try it for free**.
2. Sign in with an IBMid or create one (email + password; use `N/A` for company
   if you don't have one).
3. Verify your email.
4. On **Deploy your trial**, pick the region closest to you, name the instance,
   click **Create trial instance**.
5. When the trial-ready screen appears, click **Access your trial now**.

The trial gives you the full Standard edition for 30 days. A separate IBM Cloud
account is *not* required, and the watsonx.ai trial does *not* include
Orchestrate — use the link above specifically.

### Grab the instance URL and API key

Once you're inside the Orchestrate UI:

1. Click your **profile avatar** (top-right).
2. Open **Settings** → **API details**.
3. Copy the **Service instance URL** → this is your `WO_INSTANCE_URL`.
4. Click **Generate API key**, then **copy it immediately** → this is your
   `WO_INSTANCE_API_KEY`. The key cannot be retrieved later, only regenerated.

For self-provisioned production trial instances, you typically don't need
`WO_IAM_URL` or `WO_AUTH_TYPE` overrides — the CLI defaults are correct. Only
non-production tiers (`staging-wa.*`, `*.test.cloud.ibm.com`) need them.

Paste both values into `.env` per the skill's `starter/env.example`, run
`orchestrate env add` + `env activate`, and you're in.

### When to use trial vs shared instance

- **Solo hacker / small ad-hoc event:** each person spins up their own trial.
  Zero coordination, but everyone deploys to their own URL — judges have to
  click through 12 different demo links.
- **Organized hackathon / shared judging:** organizers pre-provision one
  instance, hand out per-team API keys against it. Judges see all submissions
  in one place. This is what the rest of this doc assumes.
