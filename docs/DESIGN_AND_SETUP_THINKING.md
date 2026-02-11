# Design and setup: the thinking behind it

Short notes on **why** things are set up the way they are. Useful when you change or extend the project.

---

## Why event-driven (NATS) instead of direct function calls?

**Idea:** Bots don’t call each other. They publish events; whoever cares subscribes.

- **Loose coupling:** Add a new bot = add a new subscriber. No need to change existing bots.
- **Same pattern locally and scaled:** One process today; tomorrow you can run subscribers in other processes or nodes; the event contract stays the same.
- **Learning:** You see a real message bus (subjects, pub/sub) without a big framework.

**Tradeoff:** Events are async and best-effort. For “must happen exactly once” or request/response, you’d add patterns (e.g. JetStream, or request-reply) later.

---

## Why one Supervisor and one_for_one?

**Idea:** One supervision tree starts NATS connection + all bots. If one bot crashes, only that bot restarts.

- **Simplicity:** One place that defines “what runs” (`application.ex`).
- **one_for_one:** Restart only the failed child. We don’t need to restart the whole army when JournalBot crashes.
- **Order:** NATS connection is started first (first child), so bots can depend on `:gnat` in their `init`.

**Tradeoff:** If NATS connection dies, we might want to restart all bots. For this learning project, restarting the connection (and letting bots reconnect) is enough.

---

## Why a Bot behaviour and `use BotArmy.Bot`?

**Idea:** Every bot does the same thing: subscribe to patterns, receive messages, optionally publish. So we put that in one place (the behaviour + macro) and each bot only implements the interesting part.

- **Less duplication:** Subscription loop, JSON decode, `publish_event` live in `bot.ex`. Each bot implements `bot_name`, `subscribe_patterns`, `handle_event`.
- **Consistent pattern:** New bots are easy to add and look the same as existing ones.
- **Elixir idiom:** Behaviours + `use` for “shared contract + shared implementation” are standard in Elixir/OTP.

---

## Why dot-notation subjects (e.g. journal.entry.created)?

**Idea:** Subjects are hierarchical so we can subscribe with wildcards.

- **One level:** `journal.entry.*` → created, updated, deleted.
- **All under a domain:** `journal.>` → everything journal-related.
- **Everything:** `>` (PonderingBot, Orchestrator).

Convention: `domain.entity.action` keeps subjects predictable and documentable.

---

## Why read NATS host/port from environment in Application.start?

**Idea:** Same compiled app runs in different environments by changing env, not code.

- **Local:** `NATS_HOST=localhost` (or unset, we default to localhost).
- **Docker:** `NATS_HOST=host.docker.internal` so the container reaches NATS on the host.
- **Kubernetes:** `NATS_HOST=nats` (Service name in the same namespace).

No recompile, no separate “dev” vs “prod” build. ConfigMap (or .env) holds the values.

---

## Why ConfigMap for NATS in Kubernetes?

**Idea:** Configuration is not baked into the image. The same image runs in any cluster; the cluster supplies NATS address via ConfigMap.

- **Same image everywhere:** Build once, deploy to dev/staging/prod by changing ConfigMap (or namespace).
- **No secrets in image:** NATS here is non-sensitive (host/port). For API keys we’d use a Secret and `secretKeyRef`.

---

## Why a Makefile for Docker and Kubernetes?

**Idea:** One set of commands that work the same for everyone.

- **Docker:** `make docker-build`, `make docker-run` so we don’t forget `--env` or `host.docker.internal`.
- **Kubernetes:** `make k8s-deploy` applies the right files in the right order; `make k8s-destroy` removes the namespace. New people (or you in 6 months) don’t have to remember the exact `kubectl` sequence.
- **Override when needed:** `make k8s-deploy IMAGE=myreg/bot-army:v1` for real registries.

---

## Why multi-stage Dockerfile?

**Idea:** Build stage has Elixir/Hex/compiler; runtime stage has only the release + minimal OS. Result: smaller image and fewer attack surfaces.

- **Stage 1:** Elixir image, mix deps.get, mix release.
- **Stage 2:** Slim Debian, copy only `_build/prod/rel/bot_army`, run as `nobody`.

We don’t ship Mix, source code, or build tools in the final image.

---

## Why PonderingBot on a timer (e.g. every 5 minutes)?

**Idea:** Pattern detection doesn’t need to be real-time. Batching events and analyzing periodically is simpler and cheaper.

- **Batch analysis:** Collect events in a buffer; every N minutes run the “ponder” logic and publish insights.
- **Future:** That batch could be sent to an external API (e.g. Claude) without blocking the rest of the system. Right now it’s in-process logic.

---

## Why Orchestrator subscribes to everything and caches?

**Idea:** User questions should be answered quickly from recent context. So Orchestrator subscribes to `>` (and ponder.*) and keeps a bounded cache of events + insights. When you ask “what insights?”, it doesn’t call other bots or NATS again; it reads from its own state.

- **Low latency:** No extra network or process hops at query time.
- **Tradeoff:** Cache is in-memory and lost on restart. For persistence we’d add a store (e.g. Postgres) later.

---

If you change one of these (e.g. add persistence or move to request-reply), this doc is the place to note the new reasoning.
