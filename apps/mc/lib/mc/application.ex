defmodule MC.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    MC.start(Application.get_env(:mc, :port))

    children = []

    opts = [strategy: :one_for_one, name: MC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
