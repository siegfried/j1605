defmodule RelayController.J1605 do
  use GenServer

  @enforce_keys [:socket]
  defstruct [:socket, relays: nil, subscribers: []]

  def start_link do
    GenServer.start_link(__MODULE__, Application.get_env(:relay_controller, :j1605), name: __MODULE__)
  end

  def init({address, port}) do
    {:ok, socket} = :gen_tcp.connect(address, port, [:binary, active: true])
    {:ok, %RelayController.J1605{socket: socket, relays: nil, subscribers: []}}
  end

  def init(_) do
    {:stop, :bad_args}
  end

  def handle_call(:subscribe, {pid, _}, state = %{subscribers: subscribers}) do
    if Enum.member?(subscribers, pid) do
      {:reply, :ok, state}
    else
      {:reply, :ok, %{state | subscribers: [pid | subscribers]}}
    end
  end

  def handle_cast(request, state = %{socket: socket}) do
    case perform(socket, request) do
      :ok -> {:noreply, state}
      {:error, reason} -> {:stop, reason, %{state | socket: nil}}
    end
  end

  defp perform(socket, request) do
    case request do
      :states          -> check_states(socket)
      {action, number} -> perform_switch(socket, action, number)
    end
  end

  defp perform_switch(socket, action, number) when is_integer(number) and number >= 1 and number <= 16 do
    case action do
      :on  -> :gen_tcp.send(socket, <<0x25, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, number - 1, 0x00>>)
      :off -> :gen_tcp.send(socket, <<0x26, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, number - 1, 0x00>>)
    end
  end

  defp check_states(socket) do
    :gen_tcp.send(socket, <<0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>)
  end

  def handle_info({:tcp, socket, message}, state = %{socket: state_socket, subscribers: subscribers}) when socket === state_socket do
    case message do
      <<0x01, _, _, _, 0x05, _, _, 0x20, relay_bits :: little-integer-size(16), 0x00, 0x00>> ->
        relays = <<relay_bits :: size(16)>> |> relay_bits_to_list |> Enum.reverse |> List.to_tuple
        alive_subscribers = for subscriber <- subscribers, Process.alive?(subscriber) do
          send subscriber, {:j1605, relays}
          subscriber
        end
        {:noreply, %{state | relays: relays, subscribers: alive_subscribers}}
      _ ->
        {:noreply, state}
    end
  end

  defp relay_bits_to_list(bits) when is_bitstring(bits) do
    for << b :: size(1) <- bits >> do
      case b do
        0 -> false
        1 -> true
      end
    end
  end
end
