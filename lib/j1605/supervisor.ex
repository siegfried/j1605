defmodule J1605.Supervisor do
  use Supervisor

  alias J1605.Device

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(arg) do
    children =
      case Mix.env() do
        :test ->
          []

        _ ->
          with {:ok, config} <- Access.fetch(arg, :device),
               {:ok, address} <- Access.fetch(config, :address),
               {:ok, port} <- Access.fetch(config, :port),
               {:ok, address} <- parse_ipv4_address(address) do
            [
              {Device, {address, port}},
              {Registry,
               keys: :duplicate, name: J1605.Registry, partitions: System.schedulers_online()}
            ]
          end
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp parse_ipv4_address(address) when is_binary(address) do
    address |> String.to_charlist() |> parse_ipv4_address()
  end

  defp parse_ipv4_address(address) do
    with {:ok, address} <- :inet.parse_ipv4_address(address) do
      {:ok, address}
    else
      _ -> {:error, :invalid_address}
    end
  end
end
