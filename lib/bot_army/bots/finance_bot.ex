defmodule BotArmy.Bots.FinanceBot do
  @moduledoc """
  FinanceBot tracks personal finances and transactions.

  Subscribes to: finance.*
  Publishes: finance.transaction.*, finance.budget.*, finance.report.*
  """

  use BotArmy.Bot

  @impl BotArmy.Bot
  def bot_name, do: :finance_bot

  @impl BotArmy.Bot
  def subscribe_patterns do
    ["finance.>"]
  end

  @impl BotArmy.Bot
  def handle_event(%BotArmy.Event{subject: "finance.transaction.record", data: data}) do
    amount = Map.get(data, "amount", 0)
    category = Map.get(data, "category", "unknown")
    type = Map.get(data, "type", "expense")

    Logger.info("💰 Transaction recorded: #{type} $#{amount} (#{category})")

    # Publish confirmation
    publish_event("finance.transaction.processed", data)

    # Check if spending is high
    if type == "expense" and amount > 100 do
      publish_event("finance.alert.large_expense", data)
    end

    :ok
  end

  def handle_event(%BotArmy.Event{subject: subject}) do
    Logger.debug("FinanceBot received: #{subject}")
    :ok
  end

  # Public API
  def record_transaction(amount, category, type \\ "expense") do
    data = %{
      amount: amount,
      category: category,
      type: type,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    publish_event("finance.transaction.record", data)
  end

  def get_budget_summary do
    publish_event("finance.budget.request", %{})
  end
end
