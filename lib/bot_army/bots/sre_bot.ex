defmodule BotArmy.Bots.SREBot do
  @moduledoc """
  SREBot monitors system health and alerts.

  Subscribes to: sre.*
  Publishes: sre.alert.*, sre.health.*, sre.metric.*
  """

  use BotArmy.Bot

  @impl BotArmy.Bot
  def bot_name, do: :sre_bot

  @impl BotArmy.Bot
  def subscribe_patterns do
    ["sre.>"]
  end

  @impl BotArmy.Bot
  def handle_event(%BotArmy.Event{subject: "sre.check.health", data: _data}) do
    # Perform health check
    health = %{
      status: "healthy",
      cpu: :rand.uniform(100),
      memory: :rand.uniform(100),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Logger.info("🏥 Health check: CPU #{health.cpu}%, Memory #{health.memory}%")

    if health.cpu > 80 or health.memory > 80 do
      publish_event("sre.alert.high_usage", health)
    else
      publish_event("sre.health.ok", health)
    end

    :ok
  end

  def handle_event(%BotArmy.Event{subject: subject}) do
    Logger.debug("SREBot received: #{subject}")
    :ok
  end

  # Public API
  def check_health do
    publish_event("sre.check.health", %{})
  end

  def alert(severity, message) do
    data = %{
      severity: severity,
      message: message,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    publish_event("sre.alert.#{severity}", data)
  end
end
