defmodule BotArmy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Get NATS connection settings from config or environment
    nats_host = System.get_env("NATS_HOST", "localhost")
    nats_port = System.get_env("NATS_PORT", "4222") |> String.to_integer()

    Logger.info("🚀 Starting BotArmy with NATS at #{nats_host}:#{nats_port}")

    children = [
      # NATS connection
      %{
        id: :gnat,
        start: {Gnat.ConnectionSupervisor, :start_link,
                [%{
                  name: :gnat,
                  connection_settings: [
                    %{host: nats_host, port: nats_port}
                  ]
                }]}
      },

      # All the bots
      {BotArmy.Bots.JournalBot, [gnat: :gnat]},
      {BotArmy.Bots.SREBot, [gnat: :gnat]},
      {BotArmy.Bots.FinanceBot, [gnat: :gnat]},
      {BotArmy.Bots.TradingBot, [gnat: :gnat]},
      {BotArmy.Bots.PonderingBot, [gnat: :gnat]},
      {BotArmy.Bots.Orchestrator, [gnat: :gnat]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BotArmy.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("✅ BotArmy started successfully!")
        Logger.info("📊 Active bots: JournalBot, SREBot, FinanceBot, TradingBot, PonderingBot, Orchestrator")
        {:ok, pid}
      error ->
        Logger.error("❌ Failed to start BotArmy: #{inspect(error)}")
        error
    end
  end
end
