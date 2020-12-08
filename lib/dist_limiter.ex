defmodule DistLimiter do
  @scope __MODULE__

  def start() do
    {:ok, self()}
  end

  def consume(resource, {window, limit}, count) do
    sum = get_sum_of_consumption(resource, window) |> IO.inspect(label: "consumption")

    if sum + count <= limit do
      DistLimiter.Server.record_consumption(get_local_server(resource), resource, count)
      {:ok, limit - (sum + count)}
    else
      {:error, :overflow}
    end
  end

  # Util

  defp get_sum_of_consumption(resource, window) do
    resource
    |> get_servers()
    |> IO.inspect()
    |> Task.async_stream(fn server ->
      DistLimiter.Server.count_consumption(server, resource, window)
    end)
    |> Stream.map(fn {:ok, count} -> count |> IO.inspect(label: "count") end)
    |> Enum.sum()
  end

  defp get_local_server(resource) do
    case UniPg.get_local_members(@scope, resource) do
      [server] ->
        server

      [] ->
        {:ok, server} = DistLimiter.Server.start_link(resource)
        UniPg.join(@scope, resource, [server]) |> IO.inspect(label: "joined")
        server
    end
  end

  defp get_servers(resource) do
    UniPg.get_members(@scope, resource)
    # uniq() is required for bugs in :pg
    |> Enum.uniq()
  end
end
