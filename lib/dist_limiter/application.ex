defmodule DistLimiter.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: UniPg,
        start: {UniPg, :start_link, [DistLimiter]}
      },
      {DynamicSupervisor, strategy: :one_for_one, name: DistLimiter.DynamicSupervisor}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
