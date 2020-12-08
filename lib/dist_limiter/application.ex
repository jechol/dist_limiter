defmodule DistLimiter.Application do
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: UniPg,
        start: {UniPg, :start_link, [DistLimiter]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
