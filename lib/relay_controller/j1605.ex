defmodule J1605.Device do
  use GenServer

  @enforce_keys [:socket]
  defstruct [:socket, relays: nil]

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init({address, port}) do
    with {:ok, socket} <- :gen_tcp.connect(address, port, [:binary, active: true]) do
      {:ok, %__MODULE__{socket: socket, relays: nil}}
    else
      error -> {:stop, error}
    end
  end

  def init(_) do
    {:stop, :bad_args}
  end

  @impl true
  def handle_cast(request, state = %{socket: socket}) do
    with :ok <- perform(socket, request) do
      {:noreply, state}
    else
      {:error, reason} -> {:stop, reason, %{state | socket: nil}}
    end
  end

  defp perform(socket, request) do
    case request do
      :states -> check_states(socket)
      {action, number} -> perform_switch(socket, action, number)
    end
  end

  defp perform_switch(socket, action, number)
       when is_integer(number) and number >= 1 and number <= 16 do
    case action do
      :on ->
        :gen_tcp.send(socket, <<0x25, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, number - 1, 0x00>>)

      :off ->
        :gen_tcp.send(socket, <<0x26, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, number - 1, 0x00>>)
    end
  end

  defp check_states(socket) do
    :gen_tcp.send(socket, <<0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>)
  end

  @impl true
  def handle_info(
        {:tcp, socket, message},
        state = %__MODULE__{socket: state_socket}
      )
      when socket === state_socket do
    case message do
      <<0x01, _, _, _, 0x05, _, _, 0x20, relay_bits::little-integer-size(16), 0x00, 0x00>> ->
        relays =
          <<relay_bits::size(16)>> |> relay_bits_to_list |> Enum.reverse() |> List.to_tuple()

        Registry.dispatch(J1605.Registry, "subscribers", fn entries ->
          Enum.each(entries, fn {pid, _} -> send(pid, {:device, relays}) end)
        end)

        {:noreply, %{state | relays: relays}}

      _ ->
        {:noreply, state}
    end
  end

  defp relay_bits_to_list(bits) when is_bitstring(bits) do
    for <<b::size(1) <- bits>> do
      case b do
        0 -> false
        1 -> true
      end
    end
  end
end
