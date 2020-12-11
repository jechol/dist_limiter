defmodule DistLimiter.Counter.DataTest do
  use ExUnit.Case, async: true

  alias DistLimiter.Counter.Data

  test "append 1", %{test: resource} do
    data = Data.new(resource, {1000, 10}, 9)
    assert data.max_total == 19
    now = :erlang.system_time(:millisecond)

    data = 1..10 |> Enum.reduce(data, fn i, data -> data |> Data.append({now + i * 50, 2}) end)

    assert data.records |> Enum.count() == 10
    assert data.total == 20
  end

  test "append 2", %{test: resource} do
    data = Data.new(resource, {1000, 10}, 9)
    assert data.max_total == 19
    now = :erlang.system_time(:millisecond)

    data = 1..10 |> Enum.reduce(data, fn i, data -> data |> Data.append({now + i * 100, 2}) end)

    assert data.records |> Enum.count() == 10
    assert data.total == 20
  end

  test "append 3", %{test: resource} do
    data = Data.new(resource, {1000, 10}, 9)
    assert data.max_total == 19
    now = :erlang.system_time(:millisecond)

    data = 1..9 |> Enum.reduce(data, fn i, data -> data |> Data.append({now + i * 200, 2}) end)
    assert data.records |> Enum.count() == 9
    assert data.total == 18

    data = 10..10 |> Enum.reduce(data, fn i, data -> data |> Data.append({now + i * 200, 2}) end)
    assert data.records |> Enum.count() == 6
    assert data.total == 12
  end
end
