defmodule BotArmy.Bots.PonderingBot do
  @moduledoc """
  PonderingBot watches all events and looks for patterns over time.
  This is the autonomous, background thinking bot that uses cloud models.

  Subscribes to: > (everything)
  Publishes: ponder.insight.detected, ponder.pattern.*

  Runs periodic "ponder loops" to analyze batched events for emergent patterns.
  """

  use BotArmy.Bot

  @ponder_interval :timer.minutes(5)

  @impl BotArmy.Bot
  def bot_name, do: :pondering_bot

  @impl BotArmy.Bot
  def subscribe_patterns do
    [">"]  # Subscribe to everything
  end

  @impl GenServer
  def init(opts) do
    gnat = Keyword.get(opts, :gnat)
    Process.put(:"#{__MODULE__}.gnat", gnat)

    # Subscribe to all events
    Enum.each(subscribe_patterns(), fn pattern ->
      {:ok, _sub} = Gnat.sub(gnat, self(), pattern)
      Logger.info("#{bot_name()} subscribed to: #{pattern}")
    end)

    # Schedule first ponder loop
    schedule_ponder()

    {:ok, %{
      gnat: gnat,
      events_processed: 0,
      event_buffer: [],
      insights_found: 0
    }}
  end

  @impl GenServer
  def handle_info(:ponder, state) do
    # Run the ponder loop
    insights = analyze_events(state.event_buffer)

    Enum.each(insights, fn insight ->
      Logger.info("🧠 Insight detected: #{insight.description}")
      publish_event("ponder.insight.detected", insight)
    end)

    # Clear buffer and schedule next ponder
    schedule_ponder()

    {:noreply, %{state |
      event_buffer: [],
      insights_found: state.insights_found + length(insights)
    }}
  end

  @impl GenServer
  def handle_info({:msg, %{topic: _topic, body: body}}, state) do
    case BotArmy.Event.decode(body) do
      {:ok, event} ->
        # Don't log every event (too noisy), just buffer them
        new_buffer = [event | state.event_buffer] |> Enum.take(1000)  # Keep last 1000
        {:noreply, %{state |
          events_processed: state.events_processed + 1,
          event_buffer: new_buffer
        }}

      {:error, reason} ->
        Logger.error("#{bot_name()} failed to decode event: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl BotArmy.Bot
  def handle_event(_event), do: :ok  # Handled in handle_info

  # Private functions

  defp schedule_ponder do
    Process.send_after(self(), :ponder, @ponder_interval)
  end

  defp analyze_events(events) when length(events) == 0 do
    []
  end

  defp analyze_events(events) do
    Logger.info("🤔 Pondering #{length(events)} events...")

    # Mock pattern detection - in production, this would call Claude API
    insights = []

    # Pattern 1: Detect clusters of alerts
    alert_events = Enum.filter(events, fn e -> String.contains?(e.subject, "alert") end)
    insights = if length(alert_events) > 3 do
      [create_insight("alert_cluster", "Multiple alerts detected in short period", alert_events) | insights]
    else
      insights
    end

    # Pattern 2: Detect high spending patterns
    finance_events = Enum.filter(events, fn e -> String.starts_with?(e.subject, "finance") end)
    insights = if length(finance_events) > 5 do
      [create_insight("high_activity", "High financial activity detected", finance_events) | insights]
    else
      insights
    end

    # Pattern 3: Detect trading patterns
    trading_signals = Enum.filter(events, fn e -> String.contains?(e.subject, "trading.signal") end)
    insights = if length(trading_signals) > 2 do
      [create_insight("trading_pattern", "Trading signals clustering", trading_signals) | insights]
    else
      insights
    end

    insights
  end

  defp create_insight(type, description, related_events) do
    %{
      type: type,
      description: description,
      event_count: length(related_events),
      subjects: Enum.map(related_events, & &1.subject) |> Enum.uniq(),
      detected_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  # Public API
  def get_buffer_size do
    GenServer.call(__MODULE__, :get_buffer_size)
  end

  @impl GenServer
  def handle_call(:get_buffer_size, _from, state) do
    {:reply, length(state.event_buffer), state}
  end

  def get_stats(state) do
    %{
      bot: bot_name(),
      events_processed: state.events_processed,
      buffer_size: length(state.event_buffer),
      insights_found: state.insights_found,
      subscriptions: subscribe_patterns()
    }
  end
end
