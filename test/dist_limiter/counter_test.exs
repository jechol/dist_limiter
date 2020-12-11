defmodule DistLimiter.CounterTest do
  use ExUnit.Case, async: true

  alias DistLimiter.Counter

  test "count" do
    {:ok, pid} = Counter.start_link(:resource1, {200, 10})
    Counter.count_up(pid, :resource1, 1)
    Counter.count_up(pid, :resource1, 1)

    assert Counter.get_count(pid, :resource1, 200) == 2
  end

  test "count -> stop" do
    {:ok, pid} = Counter.start_link(:resource1, {100, 10})

    Process.sleep(50)
    Counter.count_up(pid, :resource1, 1)

    Process.sleep(70)
    assert Process.alive?(pid)

    Process.sleep(70)
    refute Process.alive?(pid)
  end

  test "stop" do
    {:ok, pid} = Counter.start_link(:resource1, {100, 10})

    Process.sleep(200)
    refute Process.alive?(pid)
  end
end
