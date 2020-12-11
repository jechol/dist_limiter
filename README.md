[![mix test](https://github.com/jechol/dist_limiter/workflows/mix%20test/badge.svg)](https://github.com/jechol/dist_limiter/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/dist_limiter)](https://hex.pm/packages/dist_limiter)
[![License badge](https://img.shields.io/hexpm/l/dist_limiter)](https://github.com/jechol/dist_limiter/blob/master/LICENSE.md)
# DistLimiter

Actor-based distributed rate limiter.

## Feature

### Distributed
Built on top of `pg`, nodes which are interested in the same resource form a process group. They record local resource consumption and exchange those records with other nodes when being asked to consume the resource.

## Usage

Let's say we want to limit password challenge from IP "a.b.c.d" to at most 3 times a hour.

```elixir
iex(1)> resource = {:ip, "a.b.c.d", :challenge_password}                             
{:ip, "a.b.c.d", :challenge_password}
iex(2)> limit = {3600 * 1000, 3}
{3600000, 3}
iex(3)> DistLimiter.get_remaining(resource, limit)                                        
3
iex(4)> DistLimiter.consume(resource, limit, 1)   
{:ok, 2}
iex(5)> DistLimiter.consume(resource, limit, 1)
{:ok, 1}
iex(6)> DistLimiter.consume(resource, limit, 1)
{:ok, 0}
iex(7)> DistLimiter.consume(resource, limit, 1)
{:error, :overflow}
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dist_limiter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dist_limiter, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dist_limiter](https://hexdocs.pm/dist_limiter).

