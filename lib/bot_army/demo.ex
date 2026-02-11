defmodule BotArmy.Demo do
  @moduledoc """
  Demo module for testing the bot army.
  Provides easy functions to trigger various bot activities.
  """

  alias BotArmy.Bots.{JournalBot, SREBot, FinanceBot, TradingBot, Orchestrator}

  def run_demo do
    IO.puts("\n🎭 === BotArmy Demo Starting === 🎭\n")

    # Wait a moment for bots to fully initialize
    :timer.sleep(1000)

    IO.puts("1️⃣  Creating journal entries...")
    JournalBot.create_entry("Started learning Elixir today. It's amazing!", "excited")
    JournalBot.create_entry("Built a bot army with NATS messaging", "accomplished")
    :timer.sleep(500)

    IO.puts("\n2️⃣  Checking system health...")
    SREBot.check_health()
    :timer.sleep(500)
    SREBot.check_health()
    :timer.sleep(500)

    IO.puts("\n3️⃣  Recording financial transactions...")
    FinanceBot.record_transaction(45.99, "groceries", "expense")
    FinanceBot.record_transaction(150.00, "consulting", "income")
    FinanceBot.record_transaction(200.00, "electronics", "expense")
    :timer.sleep(500)

    IO.puts("\n4️⃣  Trading activity...")
    TradingBot.update_price("AAPL", 175.50)
    TradingBot.update_price("TSLA", 85.25)
    TradingBot.execute_order("AAPL", "buy", 10)
    :timer.sleep(500)

    IO.puts("\n5️⃣  Triggering more alerts for pattern detection...")
    SREBot.alert("warning", "High CPU usage detected")
    SREBot.alert("warning", "Memory threshold exceeded")
    :timer.sleep(500)

    IO.puts("\n⏳ Waiting for PonderingBot to process events...")
    :timer.sleep(2000)

    IO.puts("\n6️⃣  Querying Orchestrator...\n")
    query_orchestrator()

    IO.puts("\n✅ Demo complete! Bots will continue running in the background.")
    IO.puts("📊 Use BotArmy.Demo functions to interact with bots.\n")
  end

  def query_orchestrator do
    questions = [
      "What insights have you detected?",
      "How is the system health?",
      "Show me recent financial activity",
      "Any trading patterns?"
    ]

    Enum.each(questions, fn question ->
      IO.puts("\n❓ #{question}")
      response = Orchestrator.query(question)
      IO.puts("💡 #{response.answer}")
      :timer.sleep(500)
    end)

    IO.puts("\n📈 System Summary:")
    summary = Orchestrator.summary()
    IO.inspect(summary, pretty: true)
  end

  def show_stats do
    IO.puts("\n📊 === Bot Army Statistics === 📊\n")

    bots = [
      JournalBot,
      SREBot,
      FinanceBot,
      TradingBot,
      BotArmy.Bots.PonderingBot,
      Orchestrator
    ]

    Enum.each(bots, fn bot ->
      stats = bot.stats()
      IO.puts("#{stats.bot}:")
      IO.puts("  Events processed: #{stats.events_processed}")
      IO.puts("  Subscriptions: #{inspect(stats.subscriptions)}")

      case Map.get(stats, :buffer_size) do
        nil -> :ok
        size -> IO.puts("  Buffer size: #{size}")
      end

      case Map.get(stats, :insights_found) do
        nil -> :ok
        count -> IO.puts("  Insights found: #{count}")
      end

      IO.puts("")
    end)
  end

  # Individual bot interaction helpers

  def journal(content, mood \\ "neutral") do
    JournalBot.create_entry(content, mood)
  end

  def health_check do
    SREBot.check_health()
  end

  def alert(severity, message) do
    SREBot.alert(severity, message)
  end

  def spend(amount, category) do
    FinanceBot.record_transaction(amount, category, "expense")
  end

  def income(amount, category) do
    FinanceBot.record_transaction(amount, category, "income")
  end

  def price(symbol, price) do
    TradingBot.update_price(symbol, price)
  end

  def trade(symbol, action, quantity) do
    TradingBot.execute_order(symbol, action, quantity)
  end

  def ask(question) do
    response = Orchestrator.query(question)
    IO.puts("\n❓ #{question}")
    IO.puts("💡 #{response.answer}\n")
    response
  end

  def insights do
    Orchestrator.get_insights()
  end

  def summary do
    Orchestrator.summary()
  end
end
