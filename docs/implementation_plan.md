# Implementation Plan: Building Your First Enterprise Agent

> **Note for Hackathon Participants**: This document is a **reference guide** showing what Bob Shell will generate for you. You don't need to follow these steps manually - instead, describe your agent idea to Bob and it will create all these files automatically using the `wxo-adk-agent` skill.
>
> **How to use this document**:
> - Read it to understand the agent development workflow
> - Use it as a reference when Bob generates code
> - Refer to it if you need to manually fix or customize something Bob created

## Overview

This plan shows the complete workflow for building a watsonx Orchestrate enterprise agent with 1-2 tools. We use the **Weather Travel Advisor** as an example, but the same pattern applies to any agent.

**Hackathon Workflow**: Describe your idea to Bob → Bob generates everything → You deploy → You demo

---

## Phase 1: Environment Setup (15 minutes)

### Prerequisites Check
- [ ] Python 3.12 installed (`python3.12 --version`)
- [ ] Virtual environment created and activated
- [ ] ADK CLI installed (`orchestrate --version`)
- [ ] Environment variables configured (WO_INSTANCE_URL, WO_INSTANCE_API_KEY, etc.)

### Setup Commands
```bash
# Create project directory
mkdir weather-travel-agent
cd weather-travel-agent

# Copy starter files
cp ../starter/requirements.txt .
cp ../starter/env.example .env

# Edit .env with hackathon tenant credentials (or use these directly):
# WO_INSTANCE_URL=https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/f0486067-ab8a-458e-9db1-c44bc11bf146
# WO_INSTANCE_API_KEY=***REMOVED***
# WO_IAM_URL=https://iam.cloud.ibm.com
# WO_AUTH_TYPE=ibm_iam
# WO_ENV_NAME=hackathon

# Create project structure
mkdir -p agents tools connections tests

# Activate environment and install dependencies
source .venv/bin/activate
pip install -r requirements.txt

# Register the hosted environment
orchestrate env add --name $WO_ENV_NAME \
    --url $WO_INSTANCE_URL \
    --iam-url $WO_IAM_URL \
    --type $WO_AUTH_TYPE

orchestrate env activate $WO_ENV_NAME --api-key $WO_INSTANCE_API_KEY

# Verify
orchestrate env list  # Should show (active) marker
```

---

## Phase 2: Tool Development (45 minutes)

### Step 1: Get API Credentials

For Weather Travel Advisor:
1. Sign up at https://openweathermap.org/api
2. Get free API key (1000 calls/day)
3. Add to .env: `OPENWEATHER_API_KEY=<your-key>`

### Step 2: Create the Tool File

**File**: `tools/get_weather_forecast.py`

```python
"""Weather forecast tool for travel planning."""

from typing import Generic, Optional, TypeVar, List
import requests
from ibm_watsonx_orchestrate.agent_builder.connections import (
    ConnectionType,
    ExpectedCredentials,
)
from ibm_watsonx_orchestrate.agent_builder.tools import tool
from pydantic import BaseModel, computed_field
from pydantic.dataclasses import dataclass
import os


# ToolResponse and ErrorDetails (inlined from template)
T = TypeVar("T")

@dataclass
class ErrorDetails:
    """Unified wrapper for tool error information."""
    status_code: Optional[int]
    url: Optional[str]
    reason: Optional[str]
    details: Optional[str]
    recommendation: Optional[str]


class ToolResponse(BaseModel, Generic[T]):
    """Unified wrapper for all tool responses."""
    error_details: Optional[ErrorDetails]
    tool_output: Optional[T]

    @computed_field
    @property
    def is_success(self) -> bool:
        return self.error_details is None


# Connection configuration
OPENWEATHER_CONNECTIONS = [
    ExpectedCredentials(
        app_id="openweather",
        type=ConnectionType.KEY_VALUE,
    ),
]


@dataclass
class WeatherDay:
    """Weather data for a single day."""
    date: str
    temp_high: float
    temp_low: float
    description: str
    humidity: int
    wind_speed: float


@dataclass
class WeatherForecast:
    """Multi-day weather forecast."""
    city: str
    country: str
    forecast_days: List[WeatherDay]
    travel_advice: str


@tool(expected_credentials=OPENWEATHER_CONNECTIONS)
def get_weather_forecast(city: str, days: int = 3) -> ToolResponse[WeatherForecast]:
    """
    Retrieves weather forecast for a city to help with travel planning.

    Args:
        city: City name (e.g., "New York", "London", "Tokyo").
        days: Number of days to forecast (1-5). Defaults to 3.

    Returns:
        A ToolResponse containing WeatherForecast with daily conditions and travel advice,
        or ErrorDetails if the API call fails.
    """
    # Get API key from environment (in production, use connection credentials)
    api_key = os.getenv("OPENWEATHER_API_KEY")
    if not api_key:
        return ToolResponse(
            tool_output=None,
            error_details=ErrorDetails(
                status_code=None,
                url=None,
                reason="Missing API key",
                details="OPENWEATHER_API_KEY not found in environment",
                recommendation="Set OPENWEATHER_API_KEY in your .env file",
            ),
        )

    # Validate days parameter
    if days < 1 or days > 5:
        days = 3

    try:
        # Call OpenWeather API
        url = "https://api.openweathermap.org/data/2.5/forecast"
        response = requests.get(
            url,
            params={
                "q": city,
                "appid": api_key,
                "units": "metric",  # Celsius
                "cnt": days * 8,  # 8 forecasts per day (3-hour intervals)
            },
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()

        # Parse forecast data
        city_name = data["city"]["name"]
        country = data["city"]["country"]
        
        # Group by day and extract daily highs/lows
        daily_forecasts = []
        current_date = None
        day_temps = []
        day_conditions = []
        
        for item in data["list"]:
            date = item["dt_txt"].split()[0]
            
            if current_date != date:
                # Save previous day if exists
                if current_date and day_temps:
                    daily_forecasts.append(WeatherDay(
                        date=current_date,
                        temp_high=max(day_temps),
                        temp_low=min(day_temps),
                        description=max(set(day_conditions), key=day_conditions.count),
                        humidity=item["main"]["humidity"],
                        wind_speed=item["wind"]["speed"],
                    ))
                
                # Start new day
                current_date = date
                day_temps = []
                day_conditions = []
            
            day_temps.append(item["main"]["temp"])
            day_conditions.append(item["weather"][0]["description"])
        
        # Add last day
        if current_date and day_temps:
            daily_forecasts.append(WeatherDay(
                date=current_date,
                temp_high=max(day_temps),
                temp_low=min(day_temps),
                description=max(set(day_conditions), key=day_conditions.count),
                humidity=daily_forecasts[-1].humidity if daily_forecasts else 50,
                wind_speed=daily_forecasts[-1].wind_speed if daily_forecasts else 0,
            ))

        # Generate travel advice
        avg_temp = sum(d.temp_high for d in daily_forecasts) / len(daily_forecasts)
        has_rain = any("rain" in d.description.lower() for d in daily_forecasts)
        
        advice_parts = []
        if avg_temp < 10:
            advice_parts.append("Pack warm clothing (jacket, sweater)")
        elif avg_temp > 25:
            advice_parts.append("Pack light, breathable clothing")
        else:
            advice_parts.append("Pack layers for variable temperatures")
        
        if has_rain:
            advice_parts.append("Bring an umbrella or rain jacket")
        
        travel_advice = ". ".join(advice_parts) + "."

        return ToolResponse(
            error_details=None,
            tool_output=WeatherForecast(
                city=city_name,
                country=country,
                forecast_days=daily_forecasts[:days],
                travel_advice=travel_advice,
            ),
        )

    except requests.exceptions.RequestException as exc:
        return ToolResponse(
            tool_output=None,
            error_details=ErrorDetails(
                status_code=getattr(exc.response, "status_code", None) if hasattr(exc, "response") else None,
                url=url,
                reason=str(exc),
                details=getattr(exc.response, "text", None) if hasattr(exc, "response") else None,
                recommendation="Verify the city name and your API key. Check your network connection.",
            ),
        )
```

### Step 3: Create Unit Tests

**File**: `tools/get_weather_forecast_test.py`

```python
"""Unit tests for get_weather_forecast tool."""

import pytest
from unittest.mock import patch, Mock
from tools.get_weather_forecast import get_weather_forecast


@pytest.fixture
def mock_weather_response():
    """Mock successful OpenWeather API response."""
    return {
        "city": {"name": "London", "country": "GB"},
        "list": [
            {
                "dt_txt": "2024-01-15 12:00:00",
                "main": {"temp": 8.5, "humidity": 75},
                "weather": [{"description": "cloudy"}],
                "wind": {"speed": 5.2},
            },
            {
                "dt_txt": "2024-01-15 15:00:00",
                "main": {"temp": 10.2, "humidity": 70},
                "weather": [{"description": "partly cloudy"}],
                "wind": {"speed": 4.8},
            },
            {
                "dt_txt": "2024-01-16 12:00:00",
                "main": {"temp": 7.1, "humidity": 80},
                "weather": [{"description": "light rain"}],
                "wind": {"speed": 6.5},
            },
        ],
    }


def test_get_weather_forecast_success(mock_weather_response, monkeypatch):
    """Test successful weather forecast retrieval."""
    # Set API key
    monkeypatch.setenv("OPENWEATHER_API_KEY", "test_key_123")
    
    # Mock requests.get
    with patch("tools.get_weather_forecast.requests.get") as mock_get:
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = mock_weather_response
        mock_get.return_value = mock_response
        
        # Call tool
        result = get_weather_forecast("London", days=2)
        
        # Assertions
        assert result.is_success
        assert result.tool_output is not None
        assert result.tool_output.city == "London"
        assert result.tool_output.country == "GB"
        assert len(result.tool_output.forecast_days) <= 2
        assert "umbrella" in result.tool_output.travel_advice.lower() or "rain" in result.tool_output.travel_advice.lower()


def test_get_weather_forecast_missing_api_key(monkeypatch):
    """Test error handling when API key is missing."""
    # Remove API key
    monkeypatch.delenv("OPENWEATHER_API_KEY", raising=False)
    
    # Call tool
    result = get_weather_forecast("London")
    
    # Assertions
    assert not result.is_success
    assert result.error_details is not None
    assert "API key" in result.error_details.reason


def test_get_weather_forecast_api_error(monkeypatch):
    """Test error handling when API returns error."""
    monkeypatch.setenv("OPENWEATHER_API_KEY", "test_key_123")
    
    with patch("tools.get_weather_forecast.requests.get") as mock_get:
        mock_response = Mock()
        mock_response.status_code = 404
        mock_response.text = "City not found"
        mock_response.raise_for_status.side_effect = Exception("404 Error")
        mock_get.return_value = mock_response
        
        # Call tool
        result = get_weather_forecast("InvalidCity123")
        
        # Assertions
        assert not result.is_success
        assert result.error_details is not None
        assert result.error_details.status_code == 404
```

### Step 4: Run Tests Locally

```bash
pytest tools/get_weather_forecast_test.py -v
```

Expected output: All tests pass ✓

---

## Phase 3: Agent Configuration (30 minutes)

### Step 1: Create Connection YAML

**File**: `connections/openweather.yaml`

```yaml
spec_version: v1
kind: connection
app_id: openweather

environments:
  draft:
    kind: key_value
    type: team
    credentials:
      api_key: "{OPENWEATHER[api_key]}"
  
  live:
    kind: key_value
    type: team
    credentials:
      api_key: "{OPENWEATHER[api_key]}"
```

### Step 2: Create Agent YAML

**File**: `agents/weather_travel_agent.yaml`

```yaml
spec_version: v1
kind: native
name: weather_travel_agent
description: Provides weather forecasts and travel packing advice for upcoming trips.

llm: groq/openai/gpt-oss-120b
style: default

collaborators: []

tools:
  - get_weather_forecast

instructions: |
  ## Role
  You are a helpful travel assistant that provides weather forecasts and packing advice
  for business travelers. You help users prepare for trips by checking weather conditions
  and recommending what to bring.

  ## Tool Usage Guidelines
  
  ### When to use get_weather_forecast
  - User asks about weather for a specific city
  - User mentions an upcoming trip or travel plans
  - User wants to know what to pack for a destination
  - User asks about temperature, rain, or weather conditions
  
  ### How to use get_weather_forecast
  1. Extract the city name from the user's request
  2. Determine how many days to forecast (default: 3 days)
  3. Call the tool with city and days parameters
  4. Present the forecast in a clear, readable format
  5. Highlight the travel advice prominently
  
  ## Handling ToolResponse
  
  ### On Success (is_success = True)
  - Present the forecast day by day
  - Include temperatures (high/low), conditions, and any notable weather
  - Emphasize the travel_advice field - this is what users care about most
  - Format temperatures clearly (e.g., "High: 22°C, Low: 15°C")
  
  ### On Error (is_success = False)
  - Read the error_details.reason to understand what went wrong
  - If city not found: suggest checking spelling or trying a nearby major city
  - If API error: apologize and suggest trying again
  - Always be helpful and provide next steps
  
  ## Response Format
  
  Structure your responses like this:
  
  **Weather Forecast for [City], [Country]**
  
  📅 [Date]: [Conditions]
  - High: [temp]°C, Low: [temp]°C
  - [Description]
  
  [Repeat for each day]
  
  🧳 **Travel Advice**: [advice from tool]
  
  ## Scope Control
  - ONLY provide weather forecasts and travel packing advice
  - Do NOT book flights, hotels, or make reservations
  - Do NOT provide medical or safety advice beyond weather-related packing
  - If asked about non-weather topics, politely redirect to weather assistance
```

---

## Phase 4: Deployment (20 minutes)

### Step 1: Verify Environment

```bash
# Confirm active environment
orchestrate env list

# Should show:
# * hackathon (active)
```

### Step 2: Deploy Connection

```bash
# Add connection
orchestrate connections add --app-id openweather

# Configure for Draft environment
orchestrate connections configure \
    --app-id openweather \
    --env draft \
    --type team \
    --kind key_value

# Set credentials
orchestrate connections set-credentials \
    --app-id openweather \
    --env draft \
    -e api_key=$OPENWEATHER_API_KEY

# Verify
orchestrate connections list
```

### Step 3: Deploy Tool

```bash
orchestrate tools import \
    --kind python \
    --file tools/get_weather_forecast.py \
    --app-id openweather \
    --requirements-file requirements.txt

# Verify
orchestrate tools list
# Should show: get_weather_forecast
```

### Step 4: Deploy Agent

```bash
orchestrate agents import --file agents/weather_travel_agent.yaml

# Verify
orchestrate agents list
# Should show: weather_travel_agent
```

### Step 5: Promote Connection to Live

1. Open `$WO_INSTANCE_URL/manage/connectors` in browser
2. Find "openweather" connection
3. Verify Draft shows "connected" (green check)
4. Click into connection → switch to **Live** tab
5. Click **Paste Draft Credentials**
6. Click **Connect** → **Save**

---

## Phase 5: Testing (15 minutes)

### Step 1: Test in Hosted Chat

1. Navigate to `$WO_INSTANCE_URL/chat`
2. Select "weather_travel_agent" from agent dropdown
3. Try these prompts:

**Test Prompt 1**: "What's the weather like in London for the next 3 days?"

**Expected Response**:
- Shows 3-day forecast with temperatures
- Includes weather descriptions
- Provides packing advice

**Test Prompt 2**: "I'm traveling to Tokyo next week. What should I pack?"

**Expected Response**:
- Gets Tokyo weather forecast
- Recommends appropriate clothing
- Mentions umbrella if rain expected

**Test Prompt 3**: "Weather for InvalidCity12345"

**Expected Response**:
- Graceful error handling
- Suggests checking spelling
- Offers to try another city

### Step 2: Create Journey Success Test Case

**File**: `tests/weather_forecast_test.json`

```json
{
  "agent": "weather_travel_agent",
  "story": "You are planning a business trip and need to check the weather.",
  "starting_sentence": "What's the weather forecast for Paris for the next 3 days?",
  "response_summary": "A 3-day weather forecast for Paris with daily temperatures and packing recommendations",
  "goals": {
    "get_weather_forecast-1": ["present_forecast"]
  },
  "goal_details": [
    {
      "name": "get_weather_forecast-1",
      "type": "tool_call",
      "tool_name": "get_weather_forecast",
      "args": {
        "city": "Paris",
        "days": 3
      },
      "arg_matching": {
        "city": "strict",
        "days": "fuzzy"
      }
    },
    {
      "name": "present_forecast",
      "type": "text",
      "summary": "Present the weather forecast with temperatures and travel advice",
      "keywords": ["Paris", "°C", "advice"]
    }
  ]
}
```

### Step 3: Upload Test Case

```bash
# Get JWT token
TOKEN=$(curl -fsS -X POST "$WO_IAM_URL/siusermgr/api/1.0/apikeys/token" \
    -H "Content-Type: application/json" \
    -d "{\"apikey\":\"$WO_INSTANCE_API_KEY\"}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# Get agent ID
AGENT_ID=$(curl -fsS -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agents" \
    | python3 -c "import sys,json; print(next(a['id'] for a in json.load(sys.stdin) if a['name']=='weather_travel_agent'))")

# Upload test case
curl -fsS -X POST -H "Authorization: Bearer $TOKEN" \
    "$WO_INSTANCE_URL/v1/orchestrate/agent/$AGENT_ID/test_case/v2" \
    -F "file=@tests/weather_forecast_test.json;type=application/json"
```

### Step 4: Run Test in UI

1. Open `$WO_INSTANCE_URL/manage/agents`
2. Click "weather_travel_agent"
3. Go to **Tests** tab
4. Click **Run** on your test case
5. Verify all goals pass ✓

---

## Success Criteria Checklist

- [ ] Environment configured and active
- [ ] Tool file created with proper ToolResponse handling
- [ ] Unit tests written and passing locally
- [ ] Connection YAML created
- [ ] Agent YAML created with clear instructions
- [ ] Connection deployed and promoted to Live
- [ ] Tool imported successfully
- [ ] Agent imported successfully
- [ ] Manual testing in hosted chat works
- [ ] Journey Success test case uploaded
- [ ] Test case passes when run from UI

---

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| `orchestrate tools list` is empty | Forgot `--requirements-file` flag |
| Tool calls 404 in chat | Wrong import order - reimport in correct order |
| Connection shows "disconnected" | API key incorrect or not set |
| Test case fails on keywords | Keywords too specific - use broader terms |
| Agent doesn't call tool | Instructions not specific enough about when to use tool |

---

## Next Steps After Success

1. **Add a second tool** (e.g., `get_travel_recommendations`)
2. **Enhance error handling** with more specific messages
3. **Add more test cases** for edge cases
4. **Try a different use case** from the brainstorm list
5. **Build a manager agent** that routes to multiple collaborators

---

## Time Estimate

- Phase 1 (Setup): 15 minutes
- Phase 2 (Tool Development): 45 minutes
- Phase 3 (Agent Configuration): 30 minutes
- Phase 4 (Deployment): 20 minutes
- Phase 5 (Testing): 15 minutes

**Total**: ~2 hours for a complete, tested, deployed agent

---

## Resources

- Full ADK documentation: `wxo-adk-agent/references/`
- Tool template: `wxo-adk-agent/references/tool_template.py`
- Agent templates: `wxo-adk-agent/references/agent_*.yaml`
- Pitfalls guide: `wxo-adk-agent/references/pitfalls.md`
- Deploy recipe: `wxo-adk-agent/references/deploy_recipe.md`
