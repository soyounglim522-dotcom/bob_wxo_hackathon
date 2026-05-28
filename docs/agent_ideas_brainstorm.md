# Enterprise Agent Ideas - Brainstorming Session

## Quick-Win Tier 1 Agents (1-2 tools, ~2 hours)

### 1. **Cat Fact Mood Booster** 🐱
**Problem**: Team morale needs a boost during stressful work periods
**Tools**: 
- `get_random_cat_fact()` - Fetches a random cat fact from Cat Facts API
- `get_cat_image()` - Gets a random cat image from The Cat API

**Why it's great for learning**:
- Free public APIs (no auth complexity)
- Instant gratification - works in one chat turn
- Demonstrates tool chaining (fact + image)
- Fun demo that makes people smile

**APIs**: 
- https://catfact.ninja/fact (no auth)
- https://api.thecatapi.com/v1/images/search (free tier)

---

### 2. **GitHub PR Digest** 📊
**Problem**: Developers lose track of open PRs across repositories
**Tools**:
- `list_open_prs(repo_owner, repo_name)` - Lists open PRs with status
- `get_pr_details(repo_owner, repo_name, pr_number)` - Gets detailed PR info

**Why it's great**:
- Real developer workflow
- GitHub API is well-documented
- Free tier available (60 requests/hour unauthenticated)
- Clear success criteria (shows PR list)

**APIs**: GitHub REST API v3

---

### 3. **Weather Travel Advisor** ☀️
**Problem**: People forget to check weather before business trips
**Tools**:
- `get_weather_forecast(city, days)` - Gets multi-day forecast
- Optional: `get_travel_recommendations(weather_data)` - Suggests what to pack

**Why it's great**:
- OpenWeather API is free and reliable
- Practical use case everyone understands
- Can add packing suggestions based on conditions
- Demonstrates data transformation (weather → advice)

**APIs**: OpenWeatherMap API (free tier: 1000 calls/day)

---

### 4. **Crypto Price Tracker** 💰
**Problem**: Investors need quick price checks without opening multiple apps
**Tools**:
- `get_crypto_price(symbol)` - Current price for BTC, ETH, etc.
- `get_price_history(symbol, days)` - Historical trend

**Why it's great**:
- CoinGecko API is free and doesn't require auth
- Financial data is always interesting
- Can add price alerts logic
- Demonstrates number formatting and trends

**APIs**: CoinGecko API (free, no auth required)

---

### 5. **Dad Joke Generator** 😄
**Problem**: Icebreaker for meetings or Slack channels
**Tools**:
- `get_random_dad_joke()` - Fetches a random dad joke
- `search_jokes(keyword)` - Finds jokes about specific topics

**Why it's great**:
- icanhazdadjoke API is completely free
- Instant demo value
- Can add joke rating/voting
- Shows text processing

**APIs**: https://icanhazdadjoke.com/api (free, no auth)

---

### 6. **Public Holiday Checker** 📅
**Problem**: Planning meetings across time zones and countries
**Tools**:
- `get_holidays(country, year)` - Lists public holidays
- `is_working_day(country, date)` - Checks if a date is a working day

**Why it's great**:
- Nager.Date API is free and comprehensive
- Solves real scheduling problems
- Can integrate with calendar tools later
- Demonstrates date handling

**APIs**: Nager.Date API (free, no auth)

---

### 7. **News Headline Summarizer** 📰
**Problem**: Staying informed without information overload
**Tools**:
- `get_top_headlines(category, country)` - Fetches latest news
- Optional: `summarize_article(url)` - Gets article summary

**Why it's great**:
- NewsAPI has a free tier
- Demonstrates content aggregation
- Can filter by topics (tech, business, etc.)
- Shows API pagination handling

**APIs**: NewsAPI.org (free tier: 100 requests/day)

---

### 8. **Random Quote Generator** 💭
**Problem**: Need inspiration or motivational content
**Tools**:
- `get_random_quote()` - Fetches inspirational quote
- `search_quotes(author, keyword)` - Finds specific quotes

**Why it's great**:
- Quotable API is free and simple
- Can be used in Slack bots
- Demonstrates text search
- Quick to implement

**APIs**: https://api.quotable.io (free, no auth)

---

## Recommended Starting Point

**I recommend starting with #3 (Weather Travel Advisor) or #1 (Cat Fact Mood Booster)** because:

1. **Weather Travel Advisor**:
   - Practical business use case
   - OpenWeather API is reliable and well-documented
   - Can demo with real cities
   - Easy to extend (add packing suggestions, alerts)

2. **Cat Fact Mood Booster**:
   - Fastest to implement (simplest APIs)
   - Guaranteed to work (no rate limits)
   - Fun demo that people remember
   - Shows tool chaining (fact + image)

Both can be built in under 2 hours and provide a solid foundation for understanding the ADK workflow.

---

## Next Steps

Once you pick an idea, I'll help you:

1. **Set up the project structure** (agents/, tools/, connections/)
2. **Write the Python @tool functions** with proper ToolResponse handling
3. **Create the agent YAML** with clear instructions
4. **Write unit tests** with pytest
5. **Configure the connection** (if API requires auth)
6. **Deploy to your hosted instance**
7. **Create a Journey Success test case**

Which one sounds most interesting to you?
