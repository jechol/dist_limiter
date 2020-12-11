defmodule DistLimiterTest do
  use ExUnit.Case
  doctest DistLimiter

  setup do
    Cluster.ensure_other_node_started()
    :ok
  end

  @gap 300

  def do_test(first, second) do
    max = {@gap * 5, 2}

    {:ok, 1} =
      case first do
        :local -> DistLimiter.consume(:resource3, max, 1)
        :remote -> Cluster.rpc_other_node(DistLimiter, :consume, [:resource3, max, 1])
      end

    Process.sleep(@gap * 2)

    {:ok, 0} =
      case second do
        :local -> DistLimiter.consume(:resource3, max, 1)
        :remote -> Cluster.rpc_other_node(DistLimiter, :consume, [:resource3, max, 1])
      end

    Process.sleep(@gap * 2)

    {:error, :overflow} = DistLimiter.consume(:resource3, max, 1)
    {:error, :overflow} = Cluster.rpc_other_node(DistLimiter, :consume, [:resource3, max, 1])

    # Wait for first log disappear.
    Process.sleep(@gap * 2)
    1 = DistLimiter.get_remaining(:resource3, max)

    Process.sleep(@gap * 2)
    2 = DistLimiter.get_remaining(:resource3, max)

    Process.sleep(@gap * 4)
    0 = UniPg.get_members(DistLimiter, :resource3) |> Enum.count()
  end

  test "local + local" do
    do_test(:local, :local)
  end

  test "local + remote" do
    do_test(:local, :remote)
  end

  test "remote + remote" do
    do_test(:remote, :remote)
  end
end
