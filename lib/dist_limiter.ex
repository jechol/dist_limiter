defmodule DistLimiter do
  @scope __MODULE__

  @doc """
  Consume a count of resources if available.

  If succeeds, `{:ok, remaining_count}`.

  If falied, `{:error, :overflow}`.

    ```
    iex> DistLimiter.consume({:ip, "a.b.c.d", :password_challenge}, {60000, 1}, 1)
    {:ok, 0}
    iex> DistLimiter.consume({:ip, "a.b.c.d", :password_challenge}, {60000, 1}, 1)
    {:error, :overflow}
    ```
  """
  @spec consume(resource :: any(), {window :: integer(), limit :: integer()}, count :: integer()) ::
          {:ok, integer()} | {:error, :overflow}
  def consume(resource, {window, limit} = _rate, count) do
    sum = get_sum_of_consumption(resource, window)

    if sum + count <= limit do
      DistLimiter.Counter.count_up(get_local_counter(resource, window, limit), resource, count)
      {:ok, limit - (sum + count)}
    else
      {:error, :overflow}
    end
  end

  @doc """
  Get remaining count of the given resource.

    ```
    iex> DistLimiter.get_remaining({:ip, "a.b.c.d", :password_challenge}, {60000, 1})
    1
    iex> DistLimiter.consume({:ip, "a.b.c.d", :password_challenge}, {60000, 1}, 1)
    {:ok, 0}
    iex> DistLimiter.get_remaining({:ip, "a.b.c.d", :password_challenge}, {60000, 1})
    0
    ```
  """
  @spec get_remaining(resource :: any(), {window :: integer(), limit :: integer()}) :: integer()
  def get_remaining(resource, {window, limit} = _rate) do
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
