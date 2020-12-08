defmodule DistLimiter.ServerTest do
  use ExUnit.Case, async: true

  alias DistLimiter.Server

  test "record -> count" do
    {:ok, pid} = Server.start_link(:resource1)
    Server.record_consumption(pid, :resource1, 1)
    Server.record_consumption(pid, :resource1, 1)

    2 = Server.count_consumption(pid, :resource1, 100)
  end

  test "record -> sleep -> count" do
    {:ok, pid} = Server.start_link(:resource1)
    Server.record_consumption(pid, :resource1, 1)
    Server.record_consumption(pid, :resource1, 1)

    Process.sleep(200)

    0 = Server.count_consumption(pid, :resource1, 100)
  end
end
