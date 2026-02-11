# BotArmy Cheat Sheet

Quick reference for common operations.

## Learning the system

- **[Learning guide](docs/LEARNING_GUIDE.md)** – What each part does and why (diagrams, bullets, short sections).
- **[Kubernetes cheatsheet](docs/KUBERNETES_CHEATSHEET.md)** – `kubectl` and YAML resources.
- **[Design thinking](docs/DESIGN_AND_SETUP_THINKING.md)** – Reasoning behind setup and code.

## Starting Up

```bash
# Start NATS
./start_nats.sh

# Start BotArmy
iex -S mix

# Or compile first
mix compile && iex -S mix
```

## Demo Commands

### Full Demo
```elixir
BotArmy.Demo.run_demo()
BotArmy.Demo.show_stats()
```

### Create Events

```elixir
# Journal
BotArmy.Demo.journal("Today I learned Elixir!", "excited")
BotArmy.Demo.journal("Feeling stressed", "anxious")

# Health & Alerts
BotArmy.Demo.health_check()
BotArmy.Demo.alert("warning", "CPU spike")
BotArmy.Demo.alert("critical", "Database down")

# Finance
BotArmy.Demo.spend(50.00, "groceries")
BotArmy.Demo.spend(200.00, "electronics")
BotArmy.Demo.income(1500.00, "freelance")

# Trading
BotArmy.Demo.price("AAPL", 175.50)
BotArmy.Demo.price("TSLA", 250.00)
BotArmy.Demo.trade("AAPL", "buy", 10)
BotArmy.Demo.trade("TSLA", "sell", 5)
```

### Query System

```elixir
# Ask questions
BotArmy.Demo.ask("What insights have you detected?")
BotArmy.Demo.ask("How is the system health?")
BotArmy.Demo.ask("Show me recent financial activity")
BotArmy.Demo.ask("Any trading patterns?")

# Get raw data
BotArmy.Demo.insights()
BotArmy.Demo.summary()
```

## Direct Bot API

### JournalBot
```elixir
alias BotArmy.Bots.JournalBot

JournalBot.create_entry("Journal text", "happy")
JournalBot.stats()
```

### SREBot
```elixir
alias BotArmy.Bots.SREBot

SREBot.check_health()
SREBot.alert("critical", "Service down")
SREBot.stats()
```

### FinanceBot
```elixir
alias BotArmy.Bots.FinanceBot

FinanceBot.record_transaction(100.00, "dining", "expense")
FinanceBot.record_transaction(2000.00, "salary", "income")
FinanceBot.get_budget_summary()
FinanceBot.stats()
```

### TradingBot
```elixir
alias BotArmy.Bots.TradingBot

TradingBot.update_price("AAPL", 175.50)
TradingBot.execute_order("TSLA", "buy", 10)
TradingBot.stats()
```

### PonderingBot
```elixir
alias BotArmy.Bots.PonderingBot

PonderingBot.get_buffer_size()
PonderingBot.stats()
```

### Orchestrator
```elixir
alias BotArmy.Bots.Orchestrator

Orchestrator.query("What patterns do you see?")
Orchestrator.get_insights()
Orchestrator.get_events("sre")
Orchestrator.summary()
Orchestrator.stats()
```

## Publishing Custom Events

```elixir
alias BotArmy.Event

# Create an event
event = Event.new(
  "custom.test.event",
  %{message: "Hello from custom code!"},
  :test_bot
)

# Encode to JSON
payload = Event.encode(event)

# Publish to NATS
Gnat.pub(:gnat, "custom.test.event", payload)
```

## Subscribing to Events

```elixir
# Subscribe to specific pattern
{:ok, sub} = Gnat.sub(:gnat, self(), "journal.>")

# Receive messages
receive do
  {:msg, %{topic: topic, body: body}} ->
    {:ok, event} = Event.decode(body)
    IO.inspect(event)
end
```

## Inspecting State

```elixir
# Get state of a GenServer
:sys.get_state(BotArmy.Bots.Orchestrator)
:sys.get_state(BotArmy.Bots.PonderingBot)

# Check process info
Process.info(Process.whereis(BotArmy.Bots.Orchestrator))

# List all registered processes
Process.registered() |> Enum.filter(&String.contains?(to_string(&1), "Bot"))
```

## Debugging

```elixir
# Enable detailed logging
Logger.configure(level: :debug)

# Disable detailed logging
Logger.configure(level: :info)

# Watch messages in real-time
# (From shell, in another terminal)
docker exec -it nats-dev nats sub ">"
```

## Monitoring

```elixir
# Check NATS connection
Gnat.active_subscriptions(:gnat)

# Get all bot stats
for bot <- [
  BotArmy.Bots.JournalBot,
  BotArmy.Bots.SREBot,
  BotArmy.Bots.FinanceBot,
  BotArmy.Bots.TradingBot,
  BotArmy.Bots.PonderingBot,
  BotArmy.Bots.Orchestrator
] do
  IO.inspect(bot.stats(), label: to_string(bot))
end

# Check supervisor
Supervisor.which_children(BotArmy.Supervisor)

# Count processes
Supervisor.count_children(BotArmy.Supervisor)
```

## Stress Testing

```elixir
# Generate many events quickly
for i <- 1..100 do
  BotArmy.Demo.journal("Entry #{i}", "neutral")
  Process.sleep(10)
end

# Check buffer sizes after
BotArmy.Bots.PonderingBot.get_buffer_size()
BotArmy.Bots.Orchestrator.summary()
```

## Trigger Pattern Detection

```elixir
# Generate alert cluster (should trigger insight)
for i <- 1..5 do
  BotArmy.Demo.alert("warning", "Alert #{i}")
  Process.sleep(100)
end

# Wait for ponder loop (5 minutes) or check insights immediately
BotArmy.Demo.insights()

# Generate high financial activity
for i <- 1..10 do
  BotArmy.Demo.spend(:rand.uniform(200), "shopping")
  Process.sleep(50)
end
```

## Configuration

```elixir
# Check current config
Application.get_env(:bot_army, :nats_host)
Application.get_env(:bot_army, :nats_port)

# Set config at runtime
Application.put_env(:bot_army, :nats_host, "192.168.1.100")

# Environment variables
System.get_env("NATS_HOST")
System.get_env("NATS_PORT")
```

## Common Patterns

### Generate Sample Data
```elixir
# Morning routine
BotArmy.Demo.journal("Woke up feeling refreshed", "happy")
BotArmy.Demo.spend(5.00, "coffee")
BotArmy.Demo.health_check()

# Work session
BotArmy.Demo.journal("Starting work", "focused")
BotArmy.Demo.price("AAPL", 175.50)
BotArmy.Demo.price("GOOGL", 140.25)

# Lunch break
BotArmy.Demo.spend(15.00, "lunch")
BotArmy.Demo.journal("Good lunch break", "satisfied")

# Afternoon
BotArmy.Demo.alert("warning", "High memory usage")
BotArmy.Demo.health_check()
BotArmy.Demo.spend(100.00, "shopping")

# Evening
BotArmy.Demo.journal("Productive day!", "accomplished")
BotArmy.Demo.ask("What patterns did you notice today?")
```

### Investigation Workflow
```elixir
# 1. Generate activity
for _ <- 1..10, do: BotArmy.Demo.health_check()

# 2. Check what happened
BotArmy.Demo.summary()

# 3. Get specific events
Orchestrator.get_events("sre")

# 4. Ask for insights
BotArmy.Demo.ask("What's happening with system health?")

# 5. Check stats
BotArmy.Demo.show_stats()
```

## Restarting

```elixir
# Restart a specific bot
Supervisor.terminate_child(BotArmy.Supervisor, BotArmy.Bots.JournalBot)
Supervisor.restart_child(BotArmy.Supervisor, BotArmy.Bots.JournalBot)

# Or just kill it (supervisor will restart)
Process.exit(Process.whereis(BotArmy.Bots.JournalBot), :kill)
```

## Cleanup

```bash
# Stop NATS
docker stop nats-dev

# Remove NATS container
docker rm nats-dev

# Clean Elixir build
mix clean

# Remove dependencies
rm -rf deps _build
mix deps.get
```

## NATS Commands (from host)

```bash
# Subscribe to all events
docker exec -it nats-dev nats sub ">"

# Subscribe to specific pattern
docker exec -it nats-dev nats sub "journal.>"

# Publish test event
docker exec -it nats-dev nats pub "test.event" "hello world"

# Check server info
docker exec -it nats-dev nats server info

# Check connections
docker exec -it nats-dev nats server list
```

## Useful IEx Commands

```elixir
# Recompile without restarting
recompile()

# Clear screen
clear()

# Help
h BotArmy.Demo
h BotArmy.Event

# See module exports
exports BotArmy.Demo

# See type specs
t BotArmy.Event

# History
v()        # Last result
v(1)       # Result from line 1
v(-1)      # Previous result
```

## Next Steps

- [ ] Add Postgres persistence
- [ ] Integrate Claude API
- [ ] Add Ollama integration
- [ ] Build Phoenix LiveView UI
- [ ] Deploy to Kubernetes
- [ ] Add more bots
- [ ] Create custom patterns

## Tips

1. **Use aliases** to save typing:
   ```elixir
   alias BotArmy.Demo, as: D
   D.journal("Quick entry", "happy")
   ```

2. **Pipe for readability**:
   ```elixir
   Orchestrator.get_events("sre")
   |> Enum.take(5)
   |> Enum.map(& &1.subject)
   ```

3. **Pattern match results**:
   ```elixir
   %{events_processed: count} = PonderingBot.stats()
   IO.puts("Processed #{count} events")
   ```

4. **Use IEx helpers**:
   ```elixir
   i BotArmy.Event  # Inspect module
   r BotArmy.Demo   # Reload module
   ```

---

**Happy bot building! 🤖**
