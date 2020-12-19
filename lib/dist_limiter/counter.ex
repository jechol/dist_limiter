defmodule DistLimiter.Counter do
  @moduledoc false
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  @buffer_length 99

  alias __MODULE__.Data

  def start_link({_resource, {_window, _limit}} = setup) do
    GenStateMachine.start_link(__MODULE__, setup)
  end

  def init({resource, {window, limit}}) do
    {:ok, :counting, Data.new(resource, {window, limit}, @buffer_length)}
  end

  def get_count(pid, resource, window) do
    try do
      GenStateMachine.call(pid, {:get_count, resource, window})
    catch
      :exit, {:noproc, _} ->
        # time-of-check to time-of-use race condition happened.
        0
    end
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
    {:repeat_state, data |> Data.append({now(), count})}
  end

  def counting(
        {:call, from},
        {:get_count, resource, window},
        data = %Data{resource: resource}
      ) do
    min_ts = now() - window

    {:keep_state, data, [{:reply, from, data |> Data.count_sum(min_ts)}]}
  end

  def counting(:state_timeout, :stop, %Data{}) do
    :stop
  end

  defp now() do
    :erlang.system_time(:millisecond)
  end
end
