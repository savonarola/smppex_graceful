defmodule ESME.SessionSupervisor do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
