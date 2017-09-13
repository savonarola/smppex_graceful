defmodule ESME do
  use GenServer

  alias __MODULE__, as: ESME

  require Logger

  def start(id, host, port, system_id, password) do
    Supervisor.start_child(ESME.SessionSupervisor, session_child_spec(id, [host, port, system_id, password]))
  end

  def start_link([]) do
    GenServer.start_link(ESME, [])
  end

  def init([]) do
    Process.flag(:trap_exit, true)
    {:ok, []}
  end

  def send_pdu(session, pdu) do
    GenServer.call(session, {:send_pdu, pdu})
  end

  def terminate(reason, _st) do
    sessions = all_sessions()

    Logger.info("Terminating(#{inspect reason}) sessions with unbind #{inspect sessions}")

    sessions
    |> Enum.map(& run_unbind_task(&1))
    |> Enum.map(& Task.await(&1))
  end

  def all_sessions do
    children = Supervisor.which_children(ESME.SessionSupervisor)
    for {_, child, :worker, _} when is_pid(child) <- children, do: child
  end

  defp session_child_spec(id, args) do
    terminate_timeout = Application.get_env(:esme, :terminate_timeout)
    %{
      id: id,
      start: {ESME.Session, :start_link, [args]},
      restart: :permanent,
      shutdown: terminate_timeout,
      type: :worker
    }
  end

  defp run_unbind_task(pid) do
    Task.async(fn ->
      SMPPEX.Session.call(pid, :unbind)
    end)
  end

end
