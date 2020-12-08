defmodule DistLimiter.Application do
  use Application

  def start(_type, _args) do
    children = [
      # The Stack is a child started via Stack.start_link([:hello])
      %{
        id: UniPg,
        start: {UniPg, :start_link, [DistLimiter]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
