# watsonx Orchestrate Hackathon Bundle

에이전트 개발 키트(ADK)를 사용하여 엔터프라이즈 AI 에이전트를 구축하고 IBM Watsonx Orchestrate에 배포하세요. 
구축하고자 하는 내용을 설명하기만 하면 Bob이 코드를 생성해 주며, Docker나 로컬 서버 없이 바로 공유 호스팅 인스턴스에 배포할 수 있습니다.

## 1. Get repo and Bob

### Repo

```bash
# Clone and cd into the repo
$ git clone https://github.com/soyounglim522-dotcom/bob_wxo_hackathon
$ cd bob_wxo_hackathon
```

이제 모든 준비가 끝났습니다! Bob으로 해당 디렉터리를 열어 실행하세요.

## 2. Setup Bob

MCP 서버 구성 파일과 스킬을 Bob의 `.bob` 구성 디렉터리에 복사하여, Bob이 watsonx Orchestrate와 통신하고 에이전트 구축용 스킬을 불러올 수 있도록 합니다. 두 작업 모두를 수행하는 방법은 여러 가지가 있지만, 여기서는 단순히 파일을 구성 디렉터리의 적절한 위치로 복사하는 방법을 사용하겠습니다.

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

> MCP 서버에 연결되지 않으면, Bob을 복사한 후 다시 시작해 보세요. Bob은 시작 시 `mcp.json` 파일과 스킬 정보를 자동으로 불러옵니다.


## 3. Get watsonx Orchestrate

1. 메일로 도착한 IBM Cloud Join now 눌러서 wxo 인스턴스에 접속합니다.
2. IBM Cloud > Resource List > AI/Machine Learning > watsonx Orchestrate 선택합니다.
3. Credential에서 URL 복사하고 메모장에 적어둡니다.
4. 상단 바의 Manage > IAM 선택합니다.
5. 왼쪽 바의 Manage Identities > API Keys 선택합니다.
6. 오른쪽의 Create 파란색 버튼 누르고, wxo-api-<본인이름> 작성합니다.
7. API Key 복사하고 메모장에 적어둡니다.


## 4. Setup dev env

`ibm-watsonx-orchestrate` requires **Python 3.11–3.13** (not 3.14).

이 가이드에서는 [uv](https://astral.sh/uv)와 그 pip 호환 인터페이스를 사용합니다. 

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

# NOTE: 위에서 저장한 watsonx Orchestrate URL, API Key를 .env 파일에 넣어줍니다. 

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

준비가 다 되었습니다. Bob을 실행하고 만들고 싶은 것을 설명하기만 하면, Bob이
필요한 도구, YAML 구성 파일, 테스트, 배포 명령어를 자동으로 생성해 줍니다.

**Example prompt:**

```
ibm_knolwedge 에이전트를 만들되, 에이전트의 이름 뒤에는 _<본인이름영어로> 을 붙여줘. 그리고 orchestrate에 에이전트를 업로드해줘.
```


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

### Evaluation using WxO UI

공유 인스턴스에 에이전트를 배포한 후에는 WatsonX Orchestrate UI를 통해 테스트를 생성하고 에이전트를 평가하여, 에이전트가 일관되게 작동하고 도구를 올바르게 호출하는지 확인할 수 있습니다.

From the IBM Cloud Dashboard (where you are redirected from the IBM Cloud invitation), navigate to the Resource List (3rd icon in the sidebar).
<img width="1685" height="485" alt="sc1" src="https://github.com/user-attachments/assets/efb34b91-697c-484c-ac7a-77f269f3adf7" />

Then, under **AI / Machine Learning**, select the WxO Hackathon instance and **launch** the WxO UI.

In the UI sidebar, click **Build** and select your deployed agent.
<img width="1424" height="665" alt="sc2" src="https://github.com/user-attachments/assets/f1c8ff6e-33f0-4c45-a322-fae790b39f9d" />

---

### Journey Success (judging metric)

Each team can upload at least one Journey Success test case — a JSON file describing:

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

또한 UI의 채팅창에 내용을 입력하여 에이전트를 테스트할 수 있으며, 테스트 로그를 저장하여 어떤 도구 호출이 사용되었는지 확인할 수 있습니다. 테스트가 저장되면 테스트 케이스를 검토하여 일관성을 확인할 수 있습니다.
<img width="689" height="886" alt="sc3" src="https://github.com/user-attachments/assets/0d083265-9d5a-473a-b79a-1d3f7aae3151" />

---

## 0714 해커톤 전까지 보고 오면 좋은 문서들
Bob이 2026년 6월 25일, v2로 새롭게 업데이트되었습니다. 아래 Docs를 참고해서 새로운 기능에 익숙해지면 어떨까요?
- Bob Docs : [https://bob.ibm.com/docs/ide](https://bob.ibm.com/docs/ide)
- getting started with Bob : [pdf](./getting-started-with-bob.pdf)

- Instana mcp : [https://github.com/instana/mcp-instana](https://github.com/instana/mcp-instana)

- Bob L3 : [https://learn.ibm.com/course/view.php?id=18804](https://learn.ibm.com/course/view.php?id=18804)
- Wxo L3 : [https://learn.ibm.com/course/view.php?id=15986](https://learn.ibm.com/course/view.php?id=15986)
- Instana L3 : [https://learn.ibm.com/course/view.php?id=10326](https://learn.ibm.com/course/view.php?id=10326)

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



