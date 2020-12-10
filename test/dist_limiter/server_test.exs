defmodule DistLimiter.ServerTest do
  use ExUnit.Case, async: true

  alias DistLimiter.Server

  test "count" do
    {:ok, pid} = Server.start_link(:resource1, 200)
    Server.count_up(pid, :resource1, 1)
    Server.count_up(pid, :resource1, 1)

    assert Server.get_count(pid, :resource1, 200) == 2
  end

  test "count -> stop" do
    {:ok, pid} = Server.start_link(:resource1, 100)

    Process.sleep(50)
    Server.count_up(pid, :resource1, 1)

    Process.sleep(70)
    assert Process.alive?(pid)

    Process.sleep(70)
    refute Process.alive?(pid)
  end

  test "stop" do
    {:ok, pid} = Server.start_link(:resource1, 100)

    Process.sleep(200)
    refute Process.alive?(pid)
  end
end
