[![mix test](https://github.com/jechol/dist_limiter/workflows/mix%20test/badge.svg)](https://github.com/jechol/dist_limiter/actions)
[![Hex version badge](https://img.shields.io/hexpm/v/dist_limiter)](https://hex.pm/packages/dist_limiter)
[![License badge](https://img.shields.io/hexpm/l/dist_limiter)](https://github.com/jechol/dist_limiter/blob/master/LICENSE.md)
# DistLimiter

Distributed rate limiter.

## Features

### Distributed
Built on top of `pg`, nodes which are interested in the same resource automatically form a process group. They record local `consume` timestamps and exchange those records with other nodes when being asked to `consume`.
### Garbage collection
Member processes automatically stop when `window` milliseconds elapsed after last `consume` on the node.

### Sliding window algorithm
`dist_limiter` implemented sliding window algorithm.


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

Add `dist_limiter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dist_limiter, "~> 0.1.1"}
  ]
end
```
