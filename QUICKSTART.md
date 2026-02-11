# Quick Start Guide 🚀

Get your bot army running in 3 minutes!

## Step 1: Start NATS

```bash
./start_nats.sh
```

Or manually with Docker:
```bash
docker run -d --name nats-dev -p 4222:4222 nats:latest
```

## Step 2: Start the Bot Army

```bash
iex -S mix
```

You should see:
```
🚀 Starting BotArmy with NATS at localhost:4222
journal_bot subscribed to: journal.>
sre_bot subscribed to: sre.>
finance_bot subscribed to: finance.>
trading_bot subscribed to: trading.>
pondering_bot subscribed to: >
orchestrator subscribed to: >
✅ BotArmy started successfully!
```

## Step 3: Run the Demo

In the IEx console:

```elixir
BotArmy.Demo.run_demo()
```

This will:
- Create journal entries
- Check system health
- Record financial transactions
- Simulate trading activity
- Trigger SRE alerts
- Query the Orchestrator for insights

## Interactive Commands

### Quick Actions
```elixir
# Journal
BotArmy.Demo.journal("Had a great day!", "happy")

# Health checks
BotArmy.Demo.health_check()
BotArmy.Demo.alert("warning", "CPU spike detected")

# Finances
BotArmy.Demo.spend(50.00, "groceries")
BotArmy.Demo.income(1000.00, "salary")

# Trading
BotArmy.Demo.price("AAPL", 175.50)
BotArmy.Demo.trade("TSLA", "buy", 10)
```

### Query the Orchestrator
```elixir
BotArmy.Demo.ask("What insights have you detected?")
BotArmy.Demo.ask("How is the system health?")
BotArmy.Demo.ask("Show me recent financial activity")

# Get raw data
BotArmy.Demo.insights()
BotArmy.Demo.summary()
```

### Check Bot Statistics
```elixir
BotArmy.Demo.show_stats()
```

## Architecture at a Glance

```
┌─────────────────────────────────────────┐
│           NATS Event Bus                │
│   (All bots communicate via events)     │
└─────────────────────────────────────────┘
              ↑         ↓
    ┌─────────┴─────────┴──────────┐
    │                               │
    ↓                               ↓
┌─────────┐                   ┌──────────┐
│ Bots    │                   │ Analysis │
├─────────┤                   ├──────────┤
│ Journal │                   │ Pondering│
│ SRE     │───→ Events ───→   │   Bot    │
│ Finance │                   │(5-min)   │
│ Trading │                   └────┬─────┘
└─────────┘                        │
                                   ↓
                             Insights
                                   ↓
                            ┌──────────┐
                            │Orchestrat│
                            │   or     │
                            │(instant) │
                            └──────────┘
                                   ↑
                                  You
```

## What's Happening?

1. **Specialized Bots** listen for their events:
   - JournalBot → `journal.*`
   - SREBot → `sre.*`
   - FinanceBot → `finance.*`
   - TradingBot → `trading.*` and `market.*`

2. **PonderingBot** watches everything (`>`):
   - Buffers all events
   - Every 5 minutes, analyzes patterns
   - Publishes insights when found

3. **Orchestrator** provides instant answers:
   - Tracks all events + insights
   - Responds to queries immediately
   - Uses cached context for fast responses

## Next Steps

1. **Customize patterns** - Edit bot files to detect your own patterns
2. **Add persistence** - Connect to Postgres to store events
3. **Integrate AI** - Add Claude API for PonderingBot intelligence
4. **Build UI** - Create Phoenix LiveView dashboard
5. **Deploy** - Package for Kubernetes/Docker

## Troubleshooting

### NATS connection failed
```
Error: Connection refused (localhost:4222)
```
**Solution:** Make sure NATS is running (`./start_nats.sh`)

### Bots not receiving events
**Solution:** Check subscriptions with `BotArmy.Demo.show_stats()`

### Want to reset?
```bash
# Stop NATS and remove data
docker stop nats-dev && docker rm nats-dev

# Restart everything
./start_nats.sh
iex -S mix
```

## Tips

- Events are ephemeral unless you add persistence
- PonderingBot runs every 5 minutes by default (configurable)
- All bots run in one BEAM process (~100MB RAM total)
- Pattern matching happens in Elixir (instant, no network calls)

## Have Fun! 🎉

Your bot army is ready. Try experimenting with different event patterns and see what insights the PonderingBot discovers!
