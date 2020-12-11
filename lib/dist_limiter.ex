defmodule DistLimiter do
  @scope __MODULE__

  def consume(resource, {window, limit}, count) do
    sum = get_sum_of_consumption(resource, window)

    if sum + count <= limit do
      DistLimiter.Counter.count_up(get_local_counter(resource, window, limit), resource, count)
      {:ok, limit - (sum + count)}
    else
      {:error, :overflow}
    end
  end

  def get_remaining(resource, {window, limit}) do
    sum = get_sum_of_consumption(resource, window)
    limit - sum
  end

  # Util

  defp get_sum_of_consumption(resource, window) do
    resource
    |> get_counters()
    |> Task.async_stream(fn counter ->
      DistLimiter.Counter.get_count(counter, resource, window)
    end)
    |> Stream.map(fn {:ok, count} -> count end)
    |> Enum.sum()
  end

  defp get_local_counter(resource, window, limit) do
    case UniPg.get_local_members(@scope, resource) do
      [counter] ->
        counter

      [] ->
        {:ok, counter} = DistLimiter.Counter.start_link(resource, {window, limit})
        UniPg.join(@scope, resource, [counter])
        counter
    end
  end

  defp get_counters(resource) do
    UniPg.get_members(@scope, resource)
    # uniq() is required for bugs in :pg
    |> Enum.uniq()
  end
end
