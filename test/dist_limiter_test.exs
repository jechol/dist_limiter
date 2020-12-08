defmodule DistLimiterTest do
  use ExUnit.Case
  doctest DistLimiter

  test "greets the world" do
    assert DistLimiter.hello() == :world
  end
end
