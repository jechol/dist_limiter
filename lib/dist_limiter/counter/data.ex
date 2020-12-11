defmodule DistLimiter.Counter.Data do
  alias __MODULE__

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
