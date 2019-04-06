# J1605

J1605 is a switch hub with 16 relays can be controlled on TCP.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `j1605` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:j1605, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/j1605](https://hexdocs.pm/j1605).

## Configuration

```elixir
use Mix.Config

config :j1605,
  device: [
    address: "192.168.1.250",
    port: 2000
  ]
```

## Usage

1. Subscribe the switch events:

```elixir
Registry.register(J1605.Registry, "subscribers", nil)
```

2. Receive the switch states:

```elixir
{:states, {true, true, false, false, false, false, false, false,
          true, false, false, false, false, false, false, false}}
```

3. Turn on a switch:

```elixir
J1605.Device.turn_on(0) # between 0 and 15
```

4. Turn off a switch:

```elixir
J1605.Device.turn_off(0) # between 0 and 15
```

5. Update states:

```elixir
J1605.Device.update_states()
```
