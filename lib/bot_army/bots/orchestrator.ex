defmodule BotArmy.Bots.Orchestrator do
  @moduledoc """
  Orchestrator is the user-facing query bot that provides fast, focused answers.
  Uses local Ollama for quick responses.

  Subscribes to: >, ponder.insight.*
  Publishes: orchestrator.response.*, orchestrator.query.*

  Handles user queries by fetching specific context and synthesizing answers.
  """

  use BotArmy.Bot

  @impl BotArmy.Bot
  def bot_name, do: :orchestrator

  @impl BotArmy.Bot
  def subscribe_patterns do
    [">", "ponder.insight.>"]
  end

  @impl GenServer
  def init(opts) do
    gnat = Keyword.get(opts, :gnat)
    Process.put(:"#{__MODULE__}.gnat", gnat)

    # Subscribe to patterns
    Enum.each(subscribe_patterns(), fn pattern ->
      {:ok, _sub} = Gnat.sub(gnat, self(), pattern)
      Logger.info("#{bot_name()} subscribed to: #{pattern}")
    end)

    {:ok, %{
      gnat: gnat,
      events_processed: 0,
      recent_events: [],
      insights: []
    }}
  end

  @impl GenServer
  def handle_info({:msg, %{topic: _topic, body: body}}, state) do
    case BotArmy.Event.decode(body) do
      {:ok, event} ->
        new_state = cond do
          # Track insights specially
          String.starts_with?(event.subject, "ponder.insight") ->
            Logger.info("🎯 Orchestrator captured insight: #{inspect(event.data)}")
            %{state |
              insights: [event | state.insights] |> Enum.take(50),
              events_processed: state.events_processed + 1
            }

          # Track all events for context
          true ->
            %{state |
              recent_events: [event | state.recent_events] |> Enum.take(500),
              events_processed: state.events_processed + 1
            }
        end

        {:noreply, new_state}

      {:error, reason} ->
        Logger.error("#{bot_name()} failed to decode event: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  @impl BotArmy.Bot
  def handle_event(_event), do: :ok  # Handled in handle_info

  # Public API for queries

  @doc """
  Query the orchestrator for information about a specific topic.
  In production, this would call local Ollama with the context.
  """
  def query(question) do
    GenServer.call(__MODULE__, {:query, question})
  end

  @doc """
  Get recent insights detected by the PonderingBot.
  """
  def get_insights do
    GenServer.call(__MODULE__, :get_insights)
  end

  @doc """
  Get events matching a specific pattern.
  """
  def get_events(pattern) do
    GenServer.call(__MODULE__, {:get_events, pattern})
  end

  @doc """
  Get summary of system activity.
  """
  def summary do
    GenServer.call(__MODULE__, :summary)
  end

  # GenServer callbacks

  @impl GenServer
  def handle_call({:query, question}, _from, state) do
    Logger.info("🔍 Orchestrator query: #{question}")

    # In production, this would:
    # 1. Fetch relevant context from Postgres
    # 2. Call local Ollama with context + question
    # 3. Return synthesized answer

    # Mock response for now
    response = %{
      question: question,
      answer: generate_mock_answer(question, state),
      context_events: length(state.recent_events),
      insights_used: length(state.insights),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    # Publish query result
    publish_event("orchestrator.query.completed", response)

    {:reply, response, state}
  end

  @impl GenServer
  def handle_call(:get_insights, _from, state) do
    insights = Enum.map(state.insights, & &1.data)
    {:reply, insights, state}
  end

  @impl GenServer
  def handle_call({:get_events, pattern}, _from, state) do
    matching = Enum.filter(state.recent_events, fn event ->
      matches_pattern?(event.subject, pattern)
    end)
    {:reply, matching, state}
  end

  @impl GenServer
  def handle_call(:summary, _from, state) do
    summary = %{
      total_events: state.events_processed,
      recent_events: length(state.recent_events),
      insights: length(state.insights),
      event_types: count_event_types(state.recent_events),
      latest_insight: List.first(state.insights)
    }
    {:reply, summary, state}
  end

  def get_stats(state) do
    %{
      bot: bot_name(),
      events_processed: state.events_processed,
      recent_events_cached: length(state.recent_events),
      insights_cached: length(state.insights),
      subscriptions: subscribe_patterns()
    }
  end

  # Private helpers

  defp generate_mock_answer(question, state) do
    cond do
      String.contains?(String.downcase(question), "insight") ->
        "I've detected #{length(state.insights)} insights. #{format_insights(state.insights)}"

      String.contains?(String.downcase(question), "health") or String.contains?(String.downcase(question), "sre") ->
        sre_events = Enum.filter(state.recent_events, fn e -> String.starts_with?(e.subject, "sre") end)
        "I see #{length(sre_events)} SRE events. System appears to be running normally."

      String.contains?(String.downcase(question), "finance") or String.contains?(String.downcase(question), "spending") ->
        finance_events = Enum.filter(state.recent_events, fn e -> String.starts_with?(e.subject, "finance") end)
        "I've tracked #{length(finance_events)} financial events recently."

      String.contains?(String.downcase(question), "trading") or String.contains?(String.downcase(question), "market") ->
        trading_events = Enum.filter(state.recent_events, fn e -> String.starts_with?(e.subject, "trading") or String.starts_with?(e.subject, "market") end)
        "I see #{length(trading_events)} trading/market events."

      true ->
        "I've processed #{state.events_processed} total events. #{length(state.recent_events)} recent events in buffer. Ask me about specific topics like 'insights', 'health', 'finance', or 'trading'."
    end
  end

  defp format_insights([]), do: ""
  defp format_insights(insights) do
    latest = List.first(insights)
    if latest && latest.data do
      "Latest: #{Map.get(latest.data, "description", "N/A")}"
    else
      ""
    end
  end

  defp matches_pattern?(subject, pattern) do
    String.contains?(subject, pattern)
  end

  defp count_event_types(events) do
    events
    |> Enum.map(fn e -> e.subject |> String.split(".") |> List.first() end)
    |> Enum.frequencies()
  end
end
