# BotArmy Architecture

## System Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                         BotArmy Application                         │
│                     (Single Elixir BEAM Process)                    │
│                           ~100MB RAM                                │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                      OTP Supervision Tree                           │
│  Strategy: :one_for_one (restart individual processes on crash)    │
└────────────────────────────────────────────────────────────────────┘
                                  │
                                  ├─────► NATS Connection Supervisor
                                  │
                                  ├─────► JournalBot GenServer
                                  │
                                  ├─────► SREBot GenServer
                                  │
                                  ├─────► FinanceBot GenServer
                                  │
                                  ├─────► TradingBot GenServer
                                  │
                                  ├─────► PonderingBot GenServer
                                  │
                                  └─────► Orchestrator GenServer
```

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        NATS Event Bus                            │
│                    (Message Broker)                              │
│                                                                  │
│  Subjects:                                                       │
│    • journal.entry.created                                       │
│    • sre.alert.cpu, sre.health.ok                               │
│    • finance.transaction.processed                               │
│    • trading.signal.buy, market.price.update                    │
│    • ponder.insight.detected                                     │
│    • orchestrator.query.completed                                │
└─────────────────────────────────────────────────────────────────┘
           ↑                                            ↓
           │                                            │
           └────────────── Pub/Sub ─────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ↓                   ↓                   ↓
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Domain Bots  │    │ PonderingBot │    │ Orchestrator │
│              │    │              │    │              │
│ • JournalBot │    │ Subscribes:  │    │ Subscribes:  │
│ • SREBot     │    │   ">"        │    │   ">"        │
│ • FinanceBot │    │   (all)      │    │   "ponder.*" │
│ • TradingBot │    │              │    │              │
│              │    │ Every 5 min: │    │ On demand:   │
│ Subscribe to │    │ • Analyze    │    │ • Query      │
│ domain-      │    │ • Detect     │    │ • Synthesize │
│ specific     │    │   patterns   │    │ • Respond    │
│ events       │    │ • Publish    │    │              │
│              │    │   insights   │    │              │
└──────────────┘    └──────────────┘    └──────────────┘
        ↑                   ↑                   ↑
        │                   │                   │
        └───────────────────┴───────────────────┘
                            │
                    User Interaction
                    (Demo Module)
```

## Data Flow Diagrams

### 1. Simple Event Flow (Journal Entry)

```
┌──────┐
│ User │
└───┬──┘
    │ 1. BotArmy.Demo.journal("text", "happy")
    ↓
┌──────────────┐
│  JournalBot  │
└───┬──────────┘
    │ 2. Publishes: "journal.entry.create"
    ↓
┌──────────────┐
│ NATS Bus     │
└───┬──────────┘
    │ 3. Delivers to subscribers
    ├─────────────┬─────────────┐
    ↓             ↓             ↓
┌──────────┐ ┌──────────┐ ┌──────────┐
│JournalBot│ │Pondering │ │Orchestra │
│          │ │Bot       │ │tor       │
└──────────┘ └──────────┘ └──────────┘
    │             │             │
    │ 4a. Logs    │ 4b. Buffers │ 4c. Caches
    │             │             │
    ↓
Publishes: "journal.entry.created" (confirmation)
```

### 2. Pattern Detection Flow (PonderingBot)

```
Time: 00:00 - 04:59
┌──────────────┐
│ PonderingBot │  ← Subscribes to ALL events (">")
└───┬──────────┘
    │ Buffers events in memory
    ↓
[ Event Buffer ]
• journal.entry.created (00:15)
• sre.alert.cpu (00:45)
• finance.transaction.processed (01:20)
• sre.alert.memory (02:10)
• sre.alert.disk (03:45)
• trading.signal.buy (04:30)
[... up to 1000 events]

Time: 05:00
    │
    ↓ Ponder Loop Triggered
┌──────────────┐
│   Analyze    │
│   Patterns   │
└───┬──────────┘
    │
    ├─► Count alert events: 3 alerts found
    │
    ├─► Detect cluster: "Multiple alerts in short period"
    │
    └─► Create insight
        │
        ↓
    Publish: "ponder.insight.detected"
        │
        ↓
    ┌──────────────┐
    │ NATS Bus     │
    └───┬──────────┘
        │
        ↓
    ┌──────────────┐
    │ Orchestrator │ ← Captures insight
    │ (+ User)     │
    └──────────────┘
```

### 3. Query Flow (Orchestrator)

```
┌──────┐
│ User │
└───┬──┘
    │ 1. BotArmy.Demo.ask("What insights?")
    ↓
┌──────────────┐
│ Orchestrator │
└───┬──────────┘
    │ 2. Fetch from internal cache:
    │    • Recent events (last 500)
    │    • Captured insights (last 50)
    ↓
[ Context Retrieval ]
    │
    │ 3. Filter relevant data
    │    • Find insights
    │    • Count by type
    ↓
[ Synthesis ]
    │
    │ 4. Generate answer
    │    (Future: Call Ollama here)
    ↓
┌──────────────┐
│   Response   │
│              │
│ "I've found  │
│  3 insights: │
│  - Alert     │
│    cluster   │
│  ..."        │
└───┬──────────┘
    │ 5. Return to user
    ↓
┌──────┐
│ User │
└──────┘
```

## State Management

### Domain Bots (Journal, SRE, Finance, Trading)

```elixir
State = %{
  gnat: :gnat,              # NATS connection
  events_processed: 0       # Counter
}
```

### PonderingBot

```elixir
State = %{
  gnat: :gnat,                    # NATS connection
  events_processed: 0,            # Total events seen
  event_buffer: [],               # Last 1000 events
  insights_found: 0               # Insights published
}

# Every 5 minutes:
# 1. Analyze event_buffer
# 2. Detect patterns
# 3. Publish insights
# 4. Clear buffer
```

### Orchestrator

```elixir
State = %{
  gnat: :gnat,                    # NATS connection
  events_processed: 0,            # Total events seen
  recent_events: [],              # Last 500 events (context)
  insights: []                    # Last 50 insights
}

# On query:
# 1. Filter recent_events and insights
# 2. Generate answer from context
# 3. Return immediately
```

## Message Format

### Event Structure

```elixir
%BotArmy.Event{
  subject: "journal.entry.created",   # Dot notation
  data: %{                            # Free-form map
    content: "Today was great!",
    mood: "happy"
  },
  timestamp: ~U[2024-02-10 12:00:00Z],  # UTC
  source: :journal_bot                  # Sender
}
```

### JSON Wire Format

```json
{
  "subject": "journal.entry.created",
  "data": {
    "content": "Today was great!",
    "mood": "happy"
  },
  "timestamp": "2024-02-10T12:00:00Z",
  "source": "journal_bot"
}
```

## Subject Naming Convention

```
<domain>.<entity>.<action>

Examples:
  journal.entry.created
  journal.entry.updated
  journal.insight.pattern

  sre.alert.cpu
  sre.alert.memory
  sre.health.ok
  sre.metric.disk

  finance.transaction.processed
  finance.transaction.failed
  finance.budget.exceeded
  finance.alert.large_expense

  trading.signal.buy
  trading.signal.sell
  trading.order.executed
  trading.order.failed

  market.price.update

  ponder.insight.detected
  ponder.pattern.alert_cluster
  ponder.pattern.spending_high

  orchestrator.query.completed
  orchestrator.response.ready
```

## Subscription Patterns

### Exact Match
```
"journal.entry.created"  → Only that specific subject
```

### Wildcard (Single Level)
```
"journal.entry.*"  → journal.entry.created
                     journal.entry.updated
                     journal.entry.deleted
```

### Wildcard (Multiple Levels)
```
"journal.>"  → journal.entry.created
              journal.entry.updated
              journal.insight.pattern
              journal.anything.else.here
```

### Everything
```
">"  → All events (PonderingBot and Orchestrator)
```

## Process Communication

```
┌─────────────────────────────────────────────────────────────────┐
│                    Elixir BEAM VM                                │
│                                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│  │ Process  │   │ Process  │   │ Process  │   │ Process  │    │
│  │ (Journal)│   │ (SRE)    │   │(Pondering│   │(Orchestr)│    │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘   └────┬─────┘    │
│       │              │              │              │           │
│       │              │              │              │           │
│       └──────────────┴──────────────┴──────────────┘           │
│                      │                                          │
│                      │ All messages via NATS                    │
│                      │ (not direct Erlang messages)             │
│                      ↓                                          │
│               ┌──────────────┐                                  │
│               │ NATS Client  │                                  │
│               │ (gnat)       │                                  │
│               └──────┬───────┘                                  │
└──────────────────────│────────────────────────────────────────┘
                       │
                       │ TCP
                       ↓
              ┌────────────────┐
              │  NATS Server   │
              │  (External)    │
              └────────────────┘
```

## Fault Tolerance

### Supervision Strategy

```
If a bot crashes:
  1. Supervisor detects crash
  2. Restarts bot (:one_for_one)
  3. Bot re-subscribes to NATS
  4. Bot starts fresh (state lost)
  5. Other bots continue unaffected

If NATS crashes:
  1. All bots lose connection
  2. Supervisor restarts NATS connection
  3. Bots reconnect automatically
  4. System recovers

If entire app crashes:
  1. Supervisor tree restarts all
  2. All state lost (no persistence yet)
  3. Event history lost (ephemeral)
  4. System ready for new events
```

## Scalability Options

### Single Machine (Current)
```
┌───────────────────┐
│   BotArmy App     │
│   (1 process)     │
│   + NATS          │
└───────────────────┘
```

### Distributed (Future)
```
┌───────────────────┐     ┌───────────────────┐
│  BotArmy Node 1   │     │  BotArmy Node 2   │
│  • JournalBot     │     │  • FinanceBot     │
│  • SREBot         │     │  • TradingBot     │
└─────────┬─────────┘     └─────────┬─────────┘
          │                         │
          └────────┬────────────────┘
                   │
            ┌──────┴──────┐
            │ NATS Cluster│
            └─────────────┘
                   │
          ┌────────┴────────┐
          │                 │
┌─────────┴─────────┐ ┌─────────┴─────────┐
│  PonderingBot     │ │  Orchestrator     │
│  (Standalone)     │ │  (Standalone)     │
└───────────────────┘ └───────────────────┘
```

### Kubernetes (Future)
```
┌────────────────────────────────────────────────┐
│              Kubernetes Cluster                 │
│                                                 │
│  ┌──────────────┐  ┌──────────────┐           │
│  │ BotArmy Pod  │  │ BotArmy Pod  │           │
│  │ (Replica 1)  │  │ (Replica 2)  │           │
│  └──────┬───────┘  └──────┬───────┘           │
│         │                  │                    │
│         └────────┬─────────┘                    │
│                  │                              │
│         ┌────────┴────────┐                     │
│         │  NATS StatefulSet│                    │
│         │  (JetStream)     │                    │
│         └────────┬─────────┘                    │
│                  │                              │
│         ┌────────┴────────┐                     │
│         │ Postgres StatefulSet │                │
│         │ (Events)        │                     │
│         └─────────────────┘                     │
└────────────────────────────────────────────────┘
```

## Performance Characteristics

### Latency
- **Event publish:** < 1ms
- **Event delivery:** < 5ms
- **Pattern detection:** 5 minutes (batched)
- **Query response:** < 10ms (cached)

### Throughput
- **Events/second:** ~10,000 (NATS limit)
- **Bots supported:** Unlimited (add more)
- **Concurrent queries:** Limited by single Orchestrator process

### Memory
- **Base app:** ~50MB
- **Per bot:** ~5-10MB
- **NATS client:** ~10MB
- **Event buffer (Pondering):** ~5MB (1000 events)
- **Event cache (Orchestrator):** ~2MB (500 events)
- **Total:** ~100MB

---

**Architecture Principles:**
- ✅ Event-driven
- ✅ Loosely coupled
- ✅ Fault tolerant
- ✅ Easy to extend
- ✅ Observable
- ✅ Scalable
