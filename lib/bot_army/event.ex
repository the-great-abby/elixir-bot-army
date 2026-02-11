defmodule BotArmy.Event do
  @moduledoc """
  Event structure and helpers for NATS message publishing/subscribing.

  Event subjects follow dot notation:
  - journal.entry.created
  - sre.alert.cpu
  - finance.transaction.processed
  - trading.signal.buy
  - ponder.insight.detected
  - bot.health.ping
  """

  defstruct [:subject, :data, :timestamp, :source]

  @type t :: %__MODULE__{
    subject: String.t(),
    data: map(),
    timestamp: DateTime.t(),
    source: atom()
  }

  @doc """
  Creates a new event with the given subject, data, and source bot name.
  """
  def new(subject, data, source) do
    %__MODULE__{
      subject: subject,
      data: data,
      timestamp: DateTime.utc_now(),
      source: source
    }
  end

  @doc """
  Encodes an event to JSON for publishing to NATS.
  """
  def encode(%__MODULE__{} = event) do
    event
    |> Map.from_struct()
    |> Jason.encode!()
  end

  @doc """
  Decodes a NATS message payload back into an event struct.
  """
  def decode(payload) when is_binary(payload) do
    case Jason.decode(payload) do
      {:ok, data} ->
        {:ok, struct(__MODULE__, atomize_keys(data))}
      {:error, _} = error ->
        error
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn
      {"subject", v} -> {:subject, v}
      {"data", v} -> {:data, v}
      {"timestamp", v} -> {:timestamp, parse_datetime(v)}
      {"source", v} -> {:source, String.to_atom(v)}
      {k, v} -> {String.to_atom(k), v}
    end)
  end

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end
  defp parse_datetime(_), do: DateTime.utc_now()
end
