defmodule DistLimiterTest do
  use ExUnit.Case
  doctest DistLimiter

  setup do
    Cluster.ensure_other_node_started()
    :ok
  end

  @gap 100

  def do_test(resource, first, second) do
    max = {@gap * 5, 2}

    call = fn node ->
      case node do
        :local -> DistLimiter.consume(resource, max, 1)
        :remote -> Cluster.rpc_other_node(DistLimiter, :consume, [resource, max, 1])
      end
    end

    assert {:ok, 1} == call.(first)

    Process.sleep(@gap * 2)

    assert {:ok, 0} == call.(second)

    Process.sleep(@gap * 2)

    {:error, :overflow} = DistLimiter.consume(resource, max, 1)
    {:error, :overflow} = Cluster.rpc_other_node(DistLimiter, :consume, [resource, max, 1])

    # Wait for first log disappear.
    Process.sleep(@gap * 2)
    assert 1 == DistLimiter.get_remaining(resource, max)

    Process.sleep(@gap * 2)
    assert 2 == DistLimiter.get_remaining(resource, max)

    Process.sleep(@gap * 2)
    assert 0 == UniPg.get_members(DistLimiter, resource) |> Enum.count()
  end

  test "local + local", %{test: resource} do
    do_test(resource, :local, :local)
  end

  test "local + remote", %{test: resource} do
    do_test(resource, :local, :remote)
  end

  test "remote + remote", %{test: resource} do
    do_test(resource, :remote, :remote)
  end
end
