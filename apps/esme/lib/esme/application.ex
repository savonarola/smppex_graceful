defmodule ESME.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    terminate_timeout = Application.get_env(:esme, :terminate_timeout)

    children = [
      {ESME.SessionSupervisor, []},
      Supervisor.child_spec({ESME, []}, shutdown: terminate_timeout)
    ]

    opts = [strategy: :one_for_one, name: ESME.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
