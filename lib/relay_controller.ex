defmodule RelayController do
  use Application

  def start(_type, _args) do
    :relay_controller
    |> Application.get_all_env()
    |> RelayController.Supervisor.start_link()
  end
end
