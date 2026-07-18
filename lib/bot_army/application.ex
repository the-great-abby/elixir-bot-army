defmodule BotArmy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @nats_retries 10
  @nats_retry_ms 1_000

  @impl true
  def start(_type, _args) do
    # Get NATS connection settings from config or environment
    nats_host = System.get_env("NATS_HOST", "localhost")
    nats_port = System.get_env("NATS_PORT", "4223") |> String.to_integer()

    Logger.info("🚀 Starting BotArmy with NATS at #{nats_host}:#{nats_port}")

    case wait_for_nats(nats_host, nats_port, @nats_retries) do
      :ok ->
        start_supervisor(nats_host, nats_port)

      {:error, _} ->
        Logger.error("""
        ❌ NATS is not running at #{nats_host}:#{nats_port}.
        Start NATS first in another terminal: make nats
        """)

        {:error, :nats_unavailable}
    end
  end

  defp wait_for_nats(_host, _port, 0), do: {:error, :timeout}

  defp wait_for_nats(host, port, tries) do
    case :gen_tcp.connect(to_charlist(host), port, [], 2_000) do
      {:ok, sock} ->
        :gen_tcp.close(sock)
        :ok

      _ ->
        Process.sleep(@nats_retry_ms)
        wait_for_nats(host, port, tries - 1)
    end
  end

  defp start_supervisor(nats_host, nats_port) do
    children = [
      # NATS connection (connects asynchronously; :gnat is registered when ready)
      %{
        id: :gnat,
        start:
          {Gnat.ConnectionSupervisor, :start_link,
           [
             %{
               name: :gnat,
               connection_settings: [
                 %{host: nats_host, port: nats_port}
               ]
             }
           ]}
      },
      # Gate: wait for :gnat to be registered before starting bots (avoids :noproc)
      {BotArmy.NatsReady, [gnat_name: :gnat]},

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

        Logger.info(
          "📊 Active bots: JournalBot, SREBot, FinanceBot, TradingBot, PonderingBot, Orchestrator"
        )

        {:ok, pid}

      error ->
        Logger.error("❌ Failed to start BotArmy: #{inspect(error)}")
        error
    end
  end
end
