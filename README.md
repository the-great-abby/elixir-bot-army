# BotArmy 🤖

An Elixir-based bot army using NATS for event-driven messaging. Multiple specialized bots work together, each monitoring different aspects of your life/system.

## 📚 Learning with this project

**New to Elixir or Kubernetes?** We have a short, ADHD-friendly learning guide:

- **[Learning guide](docs/LEARNING_GUIDE.md)** – What each part does, why it’s set up that way, with diagrams and bullet points. Start here.
- **[Kubernetes cheatsheet](docs/KUBERNETES_CHEATSHEET.md)** – `kubectl` commands you’ll use and what each YAML resource is for.
- **[Design & setup thinking](docs/DESIGN_AND_SETUP_THINKING.md)** – The reasoning behind event-driven design, the Bot behaviour, ConfigMaps, Makefile, etc.

You can jump around by section; no need to read in order.

## Architecture

```
Your entire bot army
  ├── JournalBot (GenServer)    - Tracks journal entries and life events
  ├── SREBot (GenServer)        - Monitors system health and alerts
  ├── FinanceBot (GenServer)    - Tracks finances and transactions
  ├── TradingBot (GenServer)    - Monitors trading signals
  ├── PonderingBot (GenServer)  - Background pattern detection
  └── Orchestrator (GenServer)  - Fast user-facing queries

Total RAM: ~100MB
One process, one container (or none!)
Supervision tree manages everything
```

## Two-Layer Intelligence System

### PonderingBot (Autonomous, Background)
- **Subscribes to:** `>` (everything)
- **Purpose:** Slow, deep background thinking
- **Behavior:**
  - Watches all event streams continuously
  - Builds context over time
  - Runs periodic "ponder loops" (every 5 minutes)
  - Looks for emergent patterns across all bots
  - Publishes insights when detected
- **Use case:** Local Ollama (not urgent, thoughtful)

### Orchestrator (User-Initiated, Interactive)
- **Subscribes to:** All events + `ponder.insight.*`
- **Purpose:** Fast, focused investigation tool
- **Behavior:**
  - Responds to user queries immediately
  - Fetches specific context on-demand
  - Synthesizes focused answers
  - Uses insights from PonderingBot
- **Use case:** Cloud models (fast response required)

## Event Bus Pattern

All communication happens through NATS using dot notation:

```
subject: journal.entry.created
subject: sre.alert.cpu
subject: finance.transaction.processed
subject: trading.signal.buy
subject: ponder.insight.detected
subject: bot.health.ping
```

Bots can subscribe broadly (`sre.>`) or narrowly (`sre.alert.cpu`).

## Prerequisites

1. **NATS Server** - Install and run locally:
   ```bash
   # Using Docker
   docker run -p 4222:4222 nats:latest

   # Or using Homebrew on macOS
   brew install nats-server
   nats-server

   # Or deploy to Rancher/Kubernetes
   helm install nats nats/nats --set nats.jetstream.enabled=true
   ```

2. **Elixir & Erlang** (via mise):
   ```bash
   mise use -g erlang@27 elixir@1.17
   ```

## Installation

```bash
cd bot_army
mix deps.get
```

## Running the Bot Army

### Start the application:
```bash
iex -S mix
```

### Run the demo:
```elixir
BotArmy.Demo.run_demo()
```

### Check bot statistics:
```elixir
BotArmy.Demo.show_stats()
```

## Interactive Usage

### Journal Entries
```elixir
BotArmy.Demo.journal("Today was productive!", "happy")
BotArmy.Demo.journal("Feeling stressed about deadlines", "anxious")
```

### System Health
```elixir
BotArmy.Demo.health_check()
BotArmy.Demo.alert("critical", "Database connection lost")
```

### Finances
```elixir
BotArmy.Demo.spend(50.00, "groceries")
BotArmy.Demo.spend(200.00, "electronics")
BotArmy.Demo.income(1500.00, "freelance")
```

### Trading
```elixir
BotArmy.Demo.price("AAPL", 175.50)
BotArmy.Demo.trade("TSLA", "buy", 10)
```

### Query Orchestrator
```elixir
BotArmy.Demo.ask("What insights have you detected?")
BotArmy.Demo.ask("How is the system health?")
BotArmy.Demo.ask("Show me recent financial activity")

# Get raw insights
BotArmy.Demo.insights()

# Get summary
BotArmy.Demo.summary()
```

## Event Flow Example

```
User: Journal entry created
          ↓
     [NATS: journal.entry.created]
          ↓
    ┌─────┴─────┐
    ↓           ↓
JournalBot   PonderingBot (buffers for analysis)
    ↓
  Logs it


After 5 minutes:

PonderingBot runs analysis
    ↓
Detects pattern: "High journaling frequency"
    ↓
Publishes: ponder.insight.detected
    ↓
Orchestrator captures insight


User queries:

User: "What patterns do you see?"
    ↓
Orchestrator
    ↓
Fetches insights + relevant events
    ↓
Returns: "You've been journaling daily..."
```

## Configuration

Environment variables:
- `NATS_HOST` - NATS server host (default: "localhost")
- `NATS_PORT` - NATS server port (default: 4222)

## Project Structure

```
lib/
├── bot_army.ex                    # Main module
├── bot_army/
│   ├── application.ex             # OTP Application & supervision tree
│   ├── bot.ex                     # Base bot behaviour
│   ├── event.ex                   # Event structure & helpers
│   ├── demo.ex                    # Demo/CLI interface
│   └── bots/
│       ├── journal_bot.ex         # Personal journal tracking
│       ├── sre_bot.ex             # System health monitoring
│       ├── finance_bot.ex         # Financial transaction tracking
│       ├── trading_bot.ex         # Trading signals & market data
│       ├── pondering_bot.ex       # Background pattern detection
│       └── orchestrator.ex        # User-facing query interface
```

## Extending the Bot Army

### Create a new bot:

```elixir
defmodule BotArmy.Bots.MyBot do
  use BotArmy.Bot

  @impl BotArmy.Bot
  def bot_name, do: :my_bot

  @impl BotArmy.Bot
  def subscribe_patterns do
    ["my.>"]  # Subscribe to all my.* events
  end

  @impl BotArmy.Bot
  def handle_event(%BotArmy.Event{subject: subject, data: data}) do
    # Handle events
    Logger.info("MyBot received: #{subject}")
    :ok
  end

  # Public API
  def do_something(value) do
    publish_event("my.action.done", %{value: value})
  end
end
```

### Add to supervision tree:

```elixir
# In lib/bot_army/application.ex
children = [
  # ... other bots
  {BotArmy.Bots.MyBot, [gnat: :gnat]}
]
```

## Next Steps

1. **Add Postgres persistence** - Store events for historical queries
2. **Integrate Claude API** - For real PonderingBot intelligence
3. **Integrate Ollama** - For fast Orchestrator responses
4. **Add web UI** - Phoenix LiveView for visualization
5. **Deploy to Kubernetes** - Use Helm charts for NATS + app

## Learning Resources

- [NATS Documentation](https://docs.nats.io/)
- [Elixir GenServer Guide](https://hexdocs.pm/elixir/GenServer.html)
- [OTP Supervision Trees](https://hexdocs.pm/elixir/Supervisor.html)
- [Gnat NATS Client](https://hexdocs.pm/gnat/)

## License

MIT
