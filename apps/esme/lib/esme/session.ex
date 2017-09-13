defmodule ESME.Session do

  use SMPPEX.Session

  require Logger

  defstruct [
    shutdowner: nil,
    state: :unbound
  ]

  alias SMPPEX.Pdu.Factory, as: PduFactory
  alias SMPPEX.Pdu

  alias __MODULE__, as: Session

  def start_link([host, port, system_id, password]) do
    response_limit = Application.get_env(:esme, :response_limit)

    SMPPEX.ESME.start_link(host, port, {__MODULE__, [system_id, password]}, esme_opts: [ response_limit: response_limit])
  end

  def init(_socket, _transport, [system_id, password]) do
    Process.flag(:trap_exit, true)
    Logger.metadata(system_id: system_id, role: :esme)
    send(self(), {:bind, system_id, password})
    {:ok, %Session{}}
  end

  def handle_info({:bind, system_id, password}, st) do
    bind_pdu = PduFactory.bind_transceiver(system_id, password)
    {:noreply, [bind_pdu], st}
  end

  def handle_resp(pdu, _original_pdu, st) do
    case Pdu.command_name(pdu) do
      :bind_transceiver_resp -> handle_bind_resp(pdu, st)
      :unbind_resp -> handle_unbind_resp(st, :response)
      _ -> handle_any_resp(pdu, st)
    end
  end

  def handle_resp_timeout(pdus, st) do
    Logger.info("Timeout pdus: #{inspect pdus}")
    if Enum.any?(pdus, &Pdu.command_name(&1) == :unbind) do
      handle_unbind_resp(st, :timeout)
    else
      {:ok, st}
    end
  end

  def handle_call(:unbind, from, st) do
    Logger.info("Unbinding")
    {:noreply, [PduFactory.unbind], %Session{st | shutdowner: from, state: :terminating}}
  end

  def handle_call({:send_pdu, pdu}, _from, st) do
    case st.state do
      :unbound -> {:reply, {:error, :RINVBNDSTS}, st}
      :bound -> {:reply, :ok, [pdu], st}
      :terminating -> {:reply, {:error, :terminating}, st}
    end
  end

  def terminate(reason, _lost_pdus, _st) do
    Logger.info("Terminating with reason #{inspect reason}")
    :stop
  end

  defp handle_bind_resp(pdu, st) do
    if Pdu.success_resp?(pdu) do
      Logger.info("Succesfully bound")
      {:ok, %Session{st | state: :bound}}
    else
      Logger.info("Unsuccessful bind")
      {:stop, :bind_failure, st}
    end
  end

  defp handle_unbind_resp(st, status) do
    Logger.info("Got unbind #{status}")
    SMPPEX.Session.reply(st.shutdowner, :ok)
    {:ok, st}
  end

  defp handle_any_resp(pdu, st) do
    Logger.info("Got response: #{inspect pdu}")
    {:ok, st}
  end

end
