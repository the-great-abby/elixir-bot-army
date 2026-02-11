defmodule BotArmy.NatsReady do
  @moduledoc false
  # Gate process: waits for :gnat to be registered before allowing the supervisor
  # to continue starting children. Gnat.ConnectionSupervisor connects asynchronously,
  # so bots would otherwise start before :gnat exists and get :noproc.

  use GenServer
  require Logger

  @max_wait_ms 15_000
  @poll_ms 100

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    gnat_name = Keyword.get(opts, :gnat_name, :gnat)
    max_attempts = div(@max_wait_ms, @poll_ms)

    case wait_for_gnat(gnat_name, max_attempts) do
      :ok ->
        {:ok, %{gnat_name: gnat_name}}
      {:error, _} ->
        Logger.error("""
        ❌ NATS connection did not become ready in #{@max_wait_ms}ms.
        Ensure NATS is running: make nats
        """)
        {:stop, :gnat_not_ready}
    end
  end

  defp wait_for_gnat(_name, 0), do: {:error, :timeout}

  defp wait_for_gnat(name, attempts) do
    case Process.whereis(name) do
      nil ->
        Process.sleep(@poll_ms)
        wait_for_gnat(name, attempts - 1)
      _pid ->
        :ok
    end
  end
end
