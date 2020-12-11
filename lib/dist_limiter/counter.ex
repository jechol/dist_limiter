defmodule DistLimiter.Counter do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  @buffer_length 100

  alias __MODULE__.Data

  def start_link(resource, {window, limit}) do
    GenStateMachine.start_link(__MODULE__, {resource, {window, limit}})
  end

  def init({resource, {window, limit}}) do
    {:ok, :counting,
     %Data{resource: resource, window: window, records: [], max_total: limit + @buffer_length}}
  end

  def get_count(pid, resource, window) do
    GenStateMachine.call(pid, {:get_count, resource, window})
  end

  def count_up(pid, resource, count) do
    GenStateMachine.cast(pid, {:count_up, resource, count})
  end

  # Callback

  def counting(:enter, _old_state, %Data{window: window}) do
    {:keep_state_and_data, [{:state_timeout, window, :stop}]}
  end

  def counting(
        :cast,
        {:count_up, resource, count},
        data = %Data{resource: resource}
      ) do
    now = :erlang.system_time(:millisecond)

    {:repeat_state, data |> Data.append({now, count})}
  end

  def counting(
        {:call, from},
        {:get_count, resource, window},
        data = %Data{resource: resource}
      ) do
    min_ts = :erlang.system_time(:millisecond) - window

    {:keep_state, data, [{:reply, from, data |> Data.count_sum(min_ts)}]}
  end

  def counting(:state_timeout, :stop, %Data{}) do
    :stop
  end
end
