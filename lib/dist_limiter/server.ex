defmodule DistLimiter.Server do
  use GenServer

  defstruct resource: nil, timestamps: []

  def start_link(resource) do
    GenServer.start_link(__MODULE__, [resource])
  end

  def init([resource]) do
    {:ok, %__MODULE__{resource: resource}}
  end

  def count_consumption(server, resource, window) do
    GenServer.call(server, {:count_consumption, resource, window})
  end

  def record_consumption(server, resource, count) do
    GenServer.cast(server, {:record_consumption, resource, count})
  end

  # Callback

  def handle_call(
        {:count_consumption, resource, window},
        _from,
        %__MODULE__{resource: resource, timestamps: timestamps} = state
      ) do
    min_ts = :erlang.system_time(:millisecond) - window

    consumption =
      timestamps
      |> Stream.take_while(fn {ts, _count} -> ts >= min_ts end)
      |> Stream.map(fn {_ts, count} -> count end)
      |> Enum.sum()

    {:reply, consumption, state}
  end

  def handle_cast(
        {:record_consumption, resource, count},
        %__MODULE__{resource: resource, timestamps: timestamps} = state
      ) do
    now = :erlang.system_time(:millisecond)

    {:noreply, %__MODULE__{state | timestamps: [{now, count} | timestamps]}}
  end
end
