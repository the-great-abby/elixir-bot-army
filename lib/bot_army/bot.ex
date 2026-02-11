defmodule BotArmy.Bot do
  @moduledoc """
  Base behaviour for all bots in the army.
  Each bot is a GenServer that can publish and subscribe to NATS events.
  """

  @callback bot_name() :: atom()
  @callback subscribe_patterns() :: [String.t()]
  @callback handle_event(BotArmy.Event.t()) :: :ok | {:error, term()}

  defmacro __using__(_opts) do
    quote do
      use GenServer
      require Logger
      @behaviour BotArmy.Bot

      alias BotArmy.Event

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl GenServer
      def init(opts) do
        gnat = Keyword.get(opts, :gnat)

        # Subscribe to patterns defined by the bot
        Enum.each(subscribe_patterns(), fn pattern ->
          {:ok, _sub} = Gnat.sub(gnat, self(), pattern)
          Logger.info("#{bot_name()} subscribed to: #{pattern}")
        end)

        {:ok, %{gnat: gnat, events_processed: 0}}
      end

      @impl GenServer
      def handle_info({:msg, %{topic: topic, body: body}}, state) do
        case Event.decode(body) do
          {:ok, event} ->
            Logger.debug("#{bot_name()} received event: #{event.subject}")
            handle_event(event)
            {:noreply, %{state | events_processed: state.events_processed + 1}}

          {:error, reason} ->
            Logger.error("#{bot_name()} failed to decode event: #{inspect(reason)}")
            {:noreply, state}
        end
      end

      @impl GenServer
      def handle_call(:stats, _from, state) do
        stats = %{
          bot: bot_name(),
          events_processed: state.events_processed,
          subscriptions: subscribe_patterns()
        }
        {:reply, stats, state}
      end

      # Helper function for publishing events
      def publish_event(subject, data) do
        event = Event.new(subject, data, bot_name())
        payload = Event.encode(event)

        gnat = GenServer.call(__MODULE__, :get_gnat)
        case Gnat.pub(gnat, subject, payload) do
          :ok ->
            Logger.debug("#{bot_name()} published: #{subject}")
            :ok
          error ->
            Logger.error("#{bot_name()} failed to publish: #{inspect(error)}")
            error
        end
      end

      @impl GenServer
      def handle_call(:get_gnat, _from, state) do
        {:reply, state.gnat, state}
      end

      # Get bot statistics
      def stats do
        GenServer.call(__MODULE__, :stats)
      end

      defoverridable handle_info: 2
    end
  end
end
