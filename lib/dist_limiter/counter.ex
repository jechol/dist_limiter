defmodule DistLimiter.Counter do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  @buffer_length 100

  defmodule Data do
    defstruct resource: nil, window: nil, records: [], total: 0, max_total: nil

    def append(%__MODULE__{records: records, total: total} = data, {time, count} = r) do
      %Data{data | records: [r | records], total: total + count}
      |> trim_if_exceed_max(time)
    end

    def count_sum(%__MODULE__{records: records}, min_ts) do
      records
      |> Stream.take_while(fn {ts, _count} -> ts >= min_ts end)
      |> Stream.map(fn {_ts, count} -> count end)
      |> Enum.sum()
    end

    defp trim_if_exceed_max(
           %Data{window: window, records: records, total: total, max_total: max_total} = data,
           now
         ) do
      if total > max_total do
        new_records =
          records
          |> Enum.take_while(fn {time, _} ->
            time >= now - window
          end)

        new_total = new_records |> Enum.map(fn {_t, c} -> c end) |> Enum.sum()

        %Data{data | records: new_records, total: new_total}
      else
        data
      end
    end
  end

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
