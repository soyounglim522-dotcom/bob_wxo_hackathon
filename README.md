# watsonx Orchestrate Hackathon Bundle

A comprehensive toolkit for building and deploying enterprise AI agents to IBM watsonx Orchestrate using the Agent Development Kit (ADK). This bundle enables developers to rapidly build production-ready agents with Python tools, YAML configurations, and direct deployment to hosted Orchestrate instances.

## 🎯 What's Included

### Core Components

- **📚 Starter Templates** (`starter/`)
  - Project layout guide
  - Environment configuration template
  - Installation instructions for all platforms
  - Pinned dependencies (Python 3.11-3.13)

- **🛠️ wxo-adk-agent Skill** (`wxo-adk-agent/`)
  - Complete reference documentation
  - Tool and agent templates
  - Connection configuration examples
  - Deployment recipes and troubleshooting guides
  - Common pitfalls and solutions
  - Journey Success evaluation templates

- **💡 Agent Ideas** (`agent_ideas_brainstorm.md`)
  - Tiered use cases by complexity
  - Implementation time estimates
  - Suggested tool combinations

- **📋 Implementation Plan** (`implementation_plan.md`)
  - Step-by-step development workflow
  - Testing strategies
  - Deployment checklist

## 🎯 Hackathon Tenant Credentials

**Dedicated Hackathon Instance** - All participants can use these shared credentials:

```bash
# Instance URL
WO_INSTANCE_URL=https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146

# API Key (shared for hackathon use only)
WO_INSTANCE_API_KEY=***REMOVED***

# IAM Configuration (US South Production)
WO_IAM_URL=https://iam.cloud.ibm.com
WO_AUTH_TYPE=production
```

> **Note**: These credentials are for hackathon use only and are shared among all participants. Do not use for production workloads.

## 🤖 Hackathon Workflow: Build with Bob

**This hackathon is designed for Bob Shell (coding agent) users.** Instead of manually writing code, you'll describe what you want to build and Bob will generate all the files, tests, and deployment commands.

### How It Works

1. **You describe** your agent idea in natural language
2. **Bob generates** the Python tools, YAML configs, tests, and deployment commands
3. **You deploy** to the shared hackathon instance
4. **You demo** in the hosted chat UI

The `wxo-adk-agent` skill (in `wxo-adk-agent/`) contains all the templates and references Bob needs. When you mention "watsonx Orchestrate", "@tool", or "agent", Bob automatically uses this skill to generate production-ready code.

### Example Interaction

```
You: "Build me a weather travel agent that checks forecasts and suggests what to pack"

Bob: [Generates tools/get_weather_forecast.py, agents/weather_agent.yaml, 
      connections/openweather.yaml, tests, and provides deployment commands]

You: [Run the deployment commands Bob provides]

You: [Test in hosted chat at $WO_INSTANCE_URL/chat]
```

### Reference Materials

- **implementation_plan.md** - Understand what Bob generates (reference only, not a manual tutorial)
- **agent_ideas_brainstorm.md** - 12 use cases to choose from
- **wxo-adk-agent/references/** - Templates and schemas Bob uses

## 🚀 Quick Start

### Prerequisites

- **Python 3.11-3.13** (NOT 3.14 - ADK requires <3.14)
- **Git** for version control
- **Bob Shell** installed and configured

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/colehurwitz/bob_wxo_hackathon.git
cd bob_wxo_hackathon

# Create virtual environment
python3.12 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install ADK CLI
pip install ibm-watsonx-orchestrate
orchestrate --version
```

### 2. Configure Environment

```bash
# Copy environment template
cp starter/env.example .env

# Edit .env with your credentials
# - WO_INSTANCE_URL (from organizer)
# - WO_INSTANCE_API_KEY (from organizer)
# - WO_IAM_URL (depends on instance tier)
# - WO_AUTH_TYPE (depends on instance tier)
```

### 3. Register Orchestrate Environment

```bash
# Load environment variables
source .env

# Register and activate environment
orchestrate env add \
    --name hackathon \
    --url $WO_INSTANCE_URL \
    --iam-url $WO_IAM_URL \
    --type $WO_AUTH_TYPE

orchestrate env activate hackathon --api-key $WO_INSTANCE_API_KEY

# Verify
orchestrate env list
```

### 4. Start Building

Follow the project layout guide in `starter/project_layout.md` to structure your agent project.

## 📖 Documentation

### Essential Reading

1. **[AGENTS.md](AGENTS.md)** - Project overview and architecture
2. **[HACKATHON.md](HACKATHON.md)** - Hackathon-specific workflow and tips
3. **[starter/INSTALL.md](starter/INSTALL.md)** - Platform-specific installation
4. **[starter/project_layout.md](starter/project_layout.md)** - Recommended structure

### Reference Documentation (`wxo-adk-agent/references/`)

- **[tool_template.py](wxo-adk-agent/references/tool_template.py)** - Runnable tool skeleton
- **[tool_test_template.py](wxo-adk-agent/references/tool_test_template.py)** - pytest template
- **[agent_collaborator.yaml](wxo-adk-agent/references/agent_collaborator.yaml)** - Worker agent template
- **[agent_manager.yaml](wxo-adk-agent/references/agent_manager.yaml)** - Router agent template
- **[connection_basic_auth.yaml](wxo-adk-agent/references/connection_basic_auth.yaml)** - Auth configs
- **[connection_oauth.yaml](wxo-adk-agent/references/connection_oauth.yaml)** - OAuth flow
- **[yaml_schema.md](wxo-adk-agent/references/yaml_schema.md)** - Complete field reference
- **[deploy_recipe.md](wxo-adk-agent/references/deploy_recipe.md)** - Deployment commands
- **[evaluation_recipe.md](wxo-adk-agent/references/evaluation_recipe.md)** - Test case grading
- **[pitfalls.md](wxo-adk-agent/references/pitfalls.md)** - Common mistakes and fixes
- **[remote_setup.md](wxo-adk-agent/references/remote_setup.md)** - Environment configuration

## 🏗️ Architecture

### Three-Primitive Model

1. **Tools** - Python functions decorated with `@tool`, containing business logic
2. **Agents** - YAML specifications defining LLM behavior and tool bindings
3. **Connections** - YAML configurations for external API authentication

### Agent Types

- **Collaborator Agents** - Workers that execute tools directly
- **Manager Agents** - Pure routers that delegate to collaborator agents

## 🎓 Use Cases by Complexity

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

## 🔧 Development Workflow

### Standard Iteration Loop

```bash
# 1. Write/modify tool
vim tools/my_tool.py

# 2. Run unit tests
pytest tools/my_tool_test.py -v

# 3. Deploy to hosted instance
orchestrate env list  # Verify active environment
orchestrate tools import --kind python --file tools/my_tool.py \
    --app-id my_app --requirements-file requirements.txt
orchestrate agents import --file agents/my_agent.yaml

# 4. Test in hosted chat
# Navigate to $WO_INSTANCE_URL/chat

# 5. Upload test case (for judges)
# See wxo-adk-agent/references/evaluation_recipe.md
```

## 🧪 Testing

### Unit Tests
```bash
pytest tools/  # Fast local feedback loop
```

### Integration Tests
- Hosted chat UI - Where LLM behavior actually runs
- Navigate to `$WO_INSTANCE_URL/chat`

### Journey Success Tests
- JSON test cases uploaded via HTTP API
- Graded by the platform
- See `wxo-adk-agent/references/evaluation_recipe.md`

## 🔐 Security Best Practices

- Never commit `.env` files (use `.gitignore`)
- Store API keys in environment variables, not code
- Use Draft environment for development
- Promote to Live only after testing
- Always specify `--requirements-file` when importing tools
- Run `pytest` before every deployment

## 🐛 Troubleshooting

### Common Issues

| Symptom | Fix |
|---------|-----|
| `orchestrate: command not found` | Activate virtual environment: `source .venv/bin/activate` |
| `Scope not found` error | Wrong IAM URL or auth type - check `wxo-adk-agent/references/remote_setup.md` |
| Tool doesn't appear after import | Forgot `--requirements-file` flag |
| Agent doesn't call tool | Connection not promoted to Live, or tool name mismatch |
| Test case upload fails | Wrong multipart format - use `-F "file=@...;type=application/json"` |

See **[wxo-adk-agent/references/pitfalls.md](wxo-adk-agent/references/pitfalls.md)** for detailed solutions.

## 📚 Additional Resources

- **Official Documentation**: [developer.watson-orchestrate.ibm.com](https://developer.watson-orchestrate.ibm.com)
- **Python Connections Guide**: [Python Connections](https://developer.watson-orchestrate.ibm.com/connections/associate_connection_to_tool/python_connections)
- **ADK Package**: [ibm-watsonx-orchestrate on PyPI](https://pypi.org/project/ibm-watsonx-orchestrate/)

## 🤝 Contributing

This is a hackathon bundle - focus on building your agent! The templates and references are provided as-is for rapid development.

## 📄 License

IBM watsonx Orchestrate Agent Development Kit

## 🎉 Getting Help

- Full documentation in `wxo-adk-agent/references/`
- Hackathon flow overview in `HACKATHON.md`
- Installation troubleshooting in `starter/INSTALL.md`
- Common failures in `wxo-adk-agent/references/deploy_recipe.md`
- Pitfall examples in `wxo-adk-agent/references/pitfalls.md`

---

**Ready to build?** Start with `starter/project_layout.md` and choose a use case from `agent_ideas_brainstorm.md`!