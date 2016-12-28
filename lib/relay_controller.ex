defmodule RelayController do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = case Mix.env do
                 :test -> []
                 _ -> [
                   worker(RelayController.J1605, [])
                 ]
               end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RelayController.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
