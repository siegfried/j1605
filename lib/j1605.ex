defmodule J1605 do
  use Application

  alias J1605.Device

  def turn_on(number) do
    GenServer.cast(Device, {true, number})
  end

  def turn_off(number) do
    GenServer.cast(Device, {false, number})
  end

  def update_states do
    GenServer.cast(Device, :states)
  end

  def start(_type, _args) do
    :j1605
    |> Application.get_all_env()
    |> J1605.Supervisor.start_link()
  end
end
