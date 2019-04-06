# J1605

J1605 is a switch hub with 16 relays can be controlled on TCP.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `j1605` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:j1605, "~> 0.1.0"}]
    end
    ```

  2. Ensure `j1605` is started before your application:

    ```elixir
    def application do
      [applications: [:j1605]]
    end
    ```

  3. Subscribe the switch events:

    ```elixir
    Registry.register(J1605.Registry, "subscribers", nil)
    ```
