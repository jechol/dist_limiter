defmodule DistLimiter.CounterTest do
  use ExUnit.Case, async: false

  alias DistLimiter.Counter

  test "count", %{test: resource} do
    {:ok, pid} = Counter.start_link({resource, {200, 10}})
    Counter.count_up(pid, resource, 1)
    Counter.count_up(pid, resource, 1)

    assert Counter.get_count(pid, resource, 200) == 2
  end

  test "count -> stop", %{test: resource} do
    {:ok, pid} = Counter.start_link({resource, {100, 10}})

    Process.sleep(50)
    Counter.count_up(pid, resource, 1)

    Process.sleep(70)
    assert Process.alive?(pid)

    Process.sleep(70)
    refute Process.alive?(pid)

    assert Counter.get_count(pid, resource, 100) == 0
  end

  test "stop", %{test: resource} do
    {:ok, pid} = Counter.start_link({resource, {100, 10}})

    Process.sleep(200)
    refute Process.alive?(pid)

    assert Counter.get_count(pid, resource, 100) == 0
  end

  test "get_count for local dead process", %{test: resource} do
    local_dead_pid = spawn(Process, :sleep, [0])

    Process.sleep(100)
    assert Counter.get_count(local_dead_pid, resource, 100) == 0
  end

  test "get_count for remote dead process", %{test: resource} do
    Cluster.ensure_other_node_started()
    remote_dead_pid = Cluster.rpc_other_node(Kernel, :spawn, [Process, :sleep, [0]])

    Process.sleep(100)
    assert Counter.get_count(remote_dead_pid, resource, 100) == 0
  end
end
