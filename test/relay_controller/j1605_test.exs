defmodule RelayController.J1605Test do
  use ExUnit.Case, async: true

  alias RelayController.J1605

  describe "RelayController.J1605.init/1" do
    test "raises match error if the device is not ready" do
      assert J1605.init(nil) == {:stop, :bad_args}
    end

    test "prepares state if the device is ready" do
      {address, port} = Application.get_env :relay_controller, :j1605
      {:ok, listen_socket} = :gen_tcp.listen port, [:binary]
      spawn_link fn ->
        {:ok, _} = :gen_tcp.accept listen_socket
      end

      Process.sleep(1000)

      {:ok, state} = J1605.init({address, port})
      assert state.relays == nil
      assert is_port(state.socket)
      assert state.subscribers == []
    end
  end

  describe "RelayController.J1605.handle_call/3" do
    test "adds subscriber if it is not subscribed" do
      assert J1605.handle_call(:subscribe, {self, :nothing}, %{subscribers: []}) == {:reply, :ok, %{subscribers: [self]} }
    end

    test "does not add subscriber if it is subscribed" do
      assert J1605.handle_call(:subscribe, {self, :nothing}, %{subscribers: [self]}) == {:reply, :ok, %{subscribers: [self]} }
    end
  end

  describe "RelayController.J1605.handle_cast/2" do
    setup do
      {address, _} = Application.get_env :relay_controller, :j1605
      port = Enum.random 2500..3000
      {:ok, listen_socket} = :gen_tcp.listen port, [:binary]
      spawn_link fn ->
        {:ok, _} = :gen_tcp.accept listen_socket
      end

      Process.sleep(1000)

      {:ok, socket} = :gen_tcp.connect address, port, [:binary]

      {:ok, %{socket: socket}}
    end

    test "turns the relay on", %{socket: socket} do
      assert J1605.handle_cast({:on, 16}, %RelayController.J1605{socket: socket}) == {:noreply, %RelayController.J1605{socket: socket}}
    end

    test "turns the relay off", %{socket: socket} do
      assert J1605.handle_cast({:off, 16}, %RelayController.J1605{socket: socket}) == {:noreply, %RelayController.J1605{socket: socket}}
    end

    test "raises error if the number is abnormal", %{socket: socket} do
      assert_raise FunctionClauseError, fn ->
        J1605.handle_cast({:on, 17}, %RelayController.J1605{socket: socket})
      end
      assert_raise FunctionClauseError, fn ->
        J1605.handle_cast({:off, 17}, %RelayController.J1605{socket: socket})
      end
    end

    test "check the relays", %{socket: socket} do
      assert J1605.handle_cast(:states, %RelayController.J1605{socket: socket}) == {:noreply, %RelayController.J1605{socket: socket}}
    end
  end

  describe "RelayController.J1605.handle_info/2" do
    setup do
      {address, _} = Application.get_env :relay_controller, :j1605
      port = Enum.random 3000..3500
      {:ok, listen_socket} = :gen_tcp.listen port, [:binary]
      spawn_link fn ->
        {:ok, _} = :gen_tcp.accept listen_socket
      end

      Process.sleep(1000)

      {:ok, socket} = :gen_tcp.connect address, port, [:binary]

      {:ok, %{socket: socket}}
    end

    test "updates relay states", %{socket: socket} do
      assert J1605.handle_info({:tcp, socket, <<0x1, 0x12, 0x34, 0x5, 0x5, 0x0, 0x0, 0x20, 0x3, 0x1, 0x0, 0x0>>}, %RelayController.J1605{socket: socket, subscribers: [self]}) == {:noreply, %RelayController.J1605{relays: {true, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false}, socket: socket, subscribers: [self]}}
      assert J1605.handle_info({:tcp, socket, <<0x1, 0x0, 0x0, 0x1, 0x5, 0x0, 0x24, 0x20, 0x3, 0x1, 0x0, 0x0>>}, %RelayController.J1605{socket: socket, subscribers: [self]}) == {:noreply, %RelayController.J1605{relays: {true, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false}, socket: socket, subscribers: [self]}}
    end

    test "raises error if it is from unknown socket", %{socket: socket} do
      assert_raise FunctionClauseError, fn ->
        J1605.handle_info({:tcp, nil, <<0x1, 0x12, 0x34, 0x5, 0x5, 0x0, 0x0, 0x20, 0x3, 0x1, 0x0, 0x0>>}, %RelayController.J1605{socket: socket})
      end
    end

    test "removes subscribers not alive", %{socket: socket} do
      dead_subscriber = spawn fn -> true end
      Process.exit dead_subscriber, :kill
      assert J1605.handle_info({:tcp, socket, <<0x1, 0x12, 0x34, 0x5, 0x5, 0x0, 0x0, 0x20, 0x3, 0x1, 0x0, 0x0>>}, %RelayController.J1605{socket: socket, subscribers: [dead_subscriber]}) == {:noreply, %RelayController.J1605{relays: {true, true, false, false, false, false, false, false, true, false, false, false, false, false, false, false}, socket: socket, subscribers: []}}
    end
  end
end
