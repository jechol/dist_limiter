defmodule DistLimiterTest do
  use ExUnit.Case
  doctest DistLimiter

  setup do
    Cluster.ensure_other_node_started()
    :ok
  end

  test "local" do
    {:ok, 1} = DistLimiter.consume(:resource1, {200, 2}, 1)
    {:ok, 0} = DistLimiter.consume(:resource1, {200, 2}, 1)
    {:error, :overflow} = DistLimiter.consume(:resource1, {200, 2}, 1)

    Process.sleep(300)

    2 = DistLimiter.get_remaining(:resource1, {200, 2})
    {:ok, 1} = DistLimiter.consume(:resource1, {200, 2}, 1)
    1 = DistLimiter.get_remaining(:resource1, {200, 2})
  end

  test "distributed" do
    {:ok, 1} = DistLimiter.consume(:resource2, {1000, 2}, 1)
    Process.sleep(300)

    {:ok, 0} = Cluster.rpc_other_node(DistLimiter, :consume, [:resource2, {1000, 2}, 1])
    Process.sleep(300)

    {:error, :overflow} = DistLimiter.consume(:resource2, {1000, 2}, 1)

    {:error, :overflow} =
      Cluster.rpc_other_node(DistLimiter, :consume, [:resource2, {1000, 2}, 1])
  end
end
