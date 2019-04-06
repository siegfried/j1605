defmodule J1605 do
  use Application

  def start(_type, _args) do
    :j1605
    |> Application.get_all_env()
    |> J1605.Supervisor.start_link()
  end
end
