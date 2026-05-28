# Recommended project layout

```
my-wxo-agent/
  agents/
    my_agent.yaml          # `name:` field == file stem
  tools/
    my_tool.py             # @tool function name == file stem
    my_tool_test.py        # co-located test
  connections/
    my_app.yaml            # `app_id:` == file stem
  .env                     # copy from env.example, never commit
  requirements.txt
```

## The one convention that matters

**Filename stem == `@tool` function name == agent YAML `name:` == string in `tools:`**

```
tools/get_weather.py           ⟵ filename stem
  └─ def get_weather(...)      ⟵ @tool function name
agents/weather_agent.yaml
  ├─ name: weather_agent
  └─ tools: [get_weather]      ⟵ exact match
connections/openweather.yaml
  └─ app_id: openweather       ⟵ matches ExpectedCredentials(app_id="openweather")
```

This three-way match eliminates pitfall #1 (tools list / function name drift)
by construction. Renaming one means renaming all four — the discipline forces
you to keep them in sync.

## Why these directories

- **`agents/`** — one YAML per agent. Manager agents (`*_manager.yaml`) are pure
  routers; collaborator agents (`*_agent.yaml`) own tools.
- **`tools/`** — one `@tool` function per file. Co-located `*_test.py` files
  run with `pytest tools/`. Don't share state across tools — keep each file
  self-contained so `orchestrate tools import` can package them individually.
- **`connections/`** — one YAML per external app. Filename stem matches the
  `app_id` so a hacker can map connection-to-tool at a glance.

## What NOT to do

- Don't nest tools by domain (no `tools/hr/...`). Keeps `orchestrate tools import --file` paths short.
- Don't put manager and collaborator agents in different directories. Flat `agents/` makes the routing graph easier to see.
- Don't share a single `connections.yaml` for multiple apps. The ADK expects one `app_id` per file.
