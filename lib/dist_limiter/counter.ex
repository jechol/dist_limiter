defmodule DistLimiter.Counter do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  defstruct resource: nil, window: nil, records: []

  def start_link(resource, window) do
    GenStateMachine.start_link(__MODULE__, {resource, window})
  end

  def init({resource, window}) do
    {:ok, :counting, %__MODULE__{resource: resource, window: window, records: []}}
  end

  def get_count(pid, resource, window) do
    GenStateMachine.call(pid, {:get_count, resource, window})
  end

  def count_up(pid, resource, count) do
    GenStateMachine.cast(pid, {:count_up, resource, count})
  end

  # Callback

  def counting(:enter, _old_state, %__MODULE__{window: window}) do
    {:keep_state_and_data, [{:state_timeout, window, :stop}]}
  end

  def counting(
        :cast,
        {:count_up, resource, count},
        data = %__MODULE__{resource: resource, records: records}
      ) do
    now = :erlang.system_time(:millisecond)

    {:repeat_state, %__MODULE__{data | records: [{now, count} | records]}}
  end

  def counting(
        {:call, from},
        {:get_count, resource, window},
        data = %__MODULE__{resource: resource, records: records}
      ) do
    min_ts = :erlang.system_time(:millisecond) - window

    count_sum =
      records
      |> Stream.take_while(fn {ts, _count} -> ts >= min_ts end)
      |> Stream.map(fn {_ts, count} -> count end)
      |> Enum.sum()

    {:keep_state, data, [{:reply, from, count_sum}]}
  end

  def counting(:state_timeout, :stop, %__MODULE__{}) do
    :stop
  end
end
