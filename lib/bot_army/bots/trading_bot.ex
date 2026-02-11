defmodule BotArmy.Bots.TradingBot do
  @moduledoc """
  TradingBot monitors trading signals and market data.

  Subscribes to: trading.*, market.*
  Publishes: trading.signal.*, trading.order.*
  """

  use BotArmy.Bot

  @impl BotArmy.Bot
  def bot_name, do: :trading_bot

  @impl BotArmy.Bot
  def subscribe_patterns do
    ["trading.>", "market.>"]
  end

  @impl BotArmy.Bot
  def handle_event(%BotArmy.Event{subject: "market.price.update", data: data}) do
    symbol = Map.get(data, "symbol", "UNKNOWN")
    price = Map.get(data, "price", 0)

    Logger.info("📈 Market update: #{symbol} @ $#{price}")

    # Simple mock trading logic
    if price > 100 do
      publish_event("trading.signal.sell", %{symbol: symbol, price: price, reason: "price_high"})
    else
      publish_event("trading.signal.buy", %{symbol: symbol, price: price, reason: "price_low"})
    end

    :ok
  end

  def handle_event(%BotArmy.Event{subject: "trading.order.execute", data: data}) do
    Logger.info("🎯 Executing order: #{inspect(data)}")

    # Publish confirmation
    publish_event("trading.order.completed", data)
    :ok
  end

  def handle_event(%BotArmy.Event{subject: subject}) do
    Logger.debug("TradingBot received: #{subject}")
    :ok
  end

  # Public API
  def update_price(symbol, price) do
    data = %{
      symbol: symbol,
      price: price,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    publish_event("market.price.update", data)
  end

  def execute_order(symbol, action, quantity) do
    data = %{
      symbol: symbol,
      action: action,
      quantity: quantity,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    publish_event("trading.order.execute", data)
  end
end
