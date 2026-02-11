defmodule BotArmy.Bots.JournalBot do
  @moduledoc """
  JournalBot tracks personal journal entries and life events.

  Subscribes to: journal.*
  Publishes: journal.entry.created, journal.insight.*
  """

  use BotArmy.Bot

  @impl BotArmy.Bot
  def bot_name, do: :journal_bot

  @impl BotArmy.Bot
  def subscribe_patterns do
    ["journal.>"]
  end

  @impl BotArmy.Bot
  def handle_event(%BotArmy.Event{subject: "journal.entry.create", data: data}) do
    # Store journal entry (in production, save to Postgres)
    Logger.info("📔 Journal entry recorded: #{inspect(data)}")

    # Publish confirmation
    publish_event("journal.entry.created", data)
    :ok
  end

  def handle_event(%BotArmy.Event{subject: subject}) do
    Logger.debug("JournalBot received: #{subject}")
    :ok
  end

  # Public API for creating journal entries
  def create_entry(content, mood \\ nil) do
    data = %{
      content: content,
      mood: mood,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    publish_event("journal.entry.create", data)
  end
end
