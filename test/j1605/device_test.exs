defmodule J1605.DeviceTest do
  use ExUnit.Case, async: true

  alias J1605.Device

  describe "J1605.Device.init/1" do
    test "raises match error if the device is not ready" do
      assert Device.init(nil) == {:stop, :bad_args}
    end

    test "prepares state if the device is ready" do
      {:ok, listen_socket} = :gen_tcp.listen(2000, [:binary])

      spawn_link(fn ->
        {:ok, _} = :gen_tcp.accept(listen_socket)
      end)

      Process.sleep(1000)

      {:ok, state} = Device.init({{127, 0, 0, 1}, 2000, 100})
      assert state.relays == nil
      assert is_port(state.socket)
    end
  end

  describe "J1605.Device.handle_cast/2" do
    setup do
      address = {127, 0, 0, 1}
      port = Enum.random(2500..3000)
      {:ok, listen_socket} = :gen_tcp.listen(port, [:binary])

      spawn_link(fn ->
        {:ok, _} = :gen_tcp.accept(listen_socket)
      end)

      Process.sleep(1000)

      {:ok, socket} = :gen_tcp.connect(address, port, [:binary])

      {:ok, %{socket: socket}}
    end

    test "turns the relay on", %{socket: socket} do
      assert Device.handle_cast({true, 15}, %Device{socket: socket}) ==
               {:noreply, %Device{socket: socket}}
    end

    test "turns the relay off", %{socket: socket} do
      assert Device.handle_cast({false, 15}, %Device{socket: socket}) ==
               {:noreply, %Device{socket: socket}}
    end

    test "raises error if the number is abnormal", %{socket: socket} do
      assert_raise FunctionClauseError, fn ->
        Device.handle_cast({true, 16}, %Device{socket: socket})
      end

      assert_raise FunctionClauseError, fn ->
        Device.handle_cast({false, 16}, %Device{socket: socket})
      end
    end

    test "check the relays", %{socket: socket} do
      assert Device.handle_cast(:states, %Device{socket: socket}) ==
               {:noreply, %Device{socket: socket}}
    end
  end

  describe "J1605.Device.handle_info/2" do
    setup do
      address = {127, 0, 0, 1}
      port = Enum.random(3000..3500)
      {:ok, listen_socket} = :gen_tcp.listen(port, [:binary])

      spawn_link(fn ->
        {:ok, _} = :gen_tcp.accept(listen_socket)
      end)

      Process.sleep(1000)

      {:ok, socket} = :gen_tcp.connect(address, port, [:binary])

      {:ok, %{socket: socket}}
    end

    test "updates relay states", %{socket: socket} do
      Registry.start_link(keys: :duplicate, name: J1605.Registry)
      Registry.register(J1605.Registry, "subscribers", nil)

      assert Device.handle_info(
               {:tcp, socket, <<0x1, 0x12, 0x34, 0x5, 0x5, 0x0, 0x0, 0x20, 0x3, 0x1, 0x0, 0x0>>},
               %Device{socket: socket}
             ) ==
               {:noreply,
                %Device{
                  relays:
                    {true, true, false, false, false, false, false, false, true, false, false,
                     false, false, false, false, false},
                  socket: socket
                }}

      assert_received {:states,
                       {true, true, false, false, false, false, false, false, true, false, false,
                        false, false, false, false, false}}

      assert Device.handle_info(
               {:tcp, socket, <<0x1, 0x0, 0x0, 0x1, 0x5, 0x0, 0x24, 0x20, 0x3, 0x1, 0x0, 0x0>>},
               %Device{socket: socket}
             ) ==
               {:noreply,
                %Device{
                  relays:
                    {true, true, false, false, false, false, false, false, true, false, false,
                     false, false, false, false, false},
                  socket: socket
                }}

      assert_received {:states,
                       {true, true, false, false, false, false, false, false, true, false, false,
                        false, false, false, false, false}}
    end

    test "raises error if it is from unknown socket", %{socket: socket} do
      assert_raise FunctionClauseError, fn ->
        Device.handle_info(
          {:tcp, nil, <<0x1, 0x12, 0x34, 0x5, 0x5, 0x0, 0x0, 0x20, 0x3, 0x1, 0x0, 0x0>>},
          %Device{socket: socket}
        )
      end
    end
  end
end
