defmodule MC do

  use SMPPEX.Session

  alias SMPPEX.Pdu
  alias SMPPEX.Pdu.Factory, as: PduFactory
  alias SMPPEX.Pdu.Errors

  alias __MODULE__, as: MC

  @system_id "MC"

  defstruct [
    state: :unbound,
    last_msg_id: 1
  ]

  def start(port) do
    SMPPEX.MC.start({MC, []}, transport_opts: [port: port])
  end

  def init(_socket, _transport, []) do
    Logger.metadata(role: :mc)
    Logger.info("Peer connected")
    {:ok, %MC{}}
  end

  def handle_pdu(pdu, st) do
    case Pdu.command_name(pdu) do
      :bind_transmitter -> handle_bind(pdu, st)
      :bind_receiver -> handle_bind(pdu, st)
      :bind_transceiver -> handle_bind(pdu, st)
      :submit_sm -> handle_submit_sm(pdu, st)
      :unbind -> handle_unbind(pdu, st)
      _ -> {:ok, st}
    end
  end

  def handle_socket_closed(st) do
    if st.state == :terminating do
      Logger.info("Peer correctly teminated connection")
      {:normal, st}
    else
      Logger.warn("Peer teminated connection abnormally")
      {:normal, st}
    end
  end

  def terminate(reason, _lost_pdus, _st) do
    Logger.info("Terminating with reason #{inspect reason}")
    :stop
  end

  # Private

  defp handle_bind(pdu, st) do
    case st.state do
      :unbound ->
        Logger.metadata(system_id: Pdu.mandatory_field(pdu, :system_id))
        {:ok, [bind_resp(pdu, :ROK)], %MC{st | state: :bound}}
      :bound ->
        {:ok, [bind_resp(pdu, :RALYBND)], st}
      :terminating ->
        {:ok, [bind_resp(pdu, :RALYBND)], st}
    end
  end

  defp bind_resp(pdu, command_status) do
    PduFactory.bind_resp(
      bind_resp_command_id(pdu),
      Errors.code_by_name(command_status),
      @system_id
    ) |> Pdu.as_reply_to(pdu)
  end

  defp bind_resp_command_id(pdu), do: 0x80000000 + Pdu.command_id(pdu)

  defp handle_submit_sm(pdu, st) do
    case st.state do
      :unbound ->
        {:ok, [submit_sm_error_resp(pdu, :RINVBNDSTS)], st}
      :bound ->
        {resp, new_st} = submit_sm_ok_resp(pdu, st)
        {:ok, [resp], new_st}
      :terminating ->
        {:ok, [submit_sm_error_resp(pdu, :RINVBNDSTS)], st}
    end
  end

  defp submit_sm_error_resp(pdu, status) do
    status
    |> Errors.code_by_name
    |> PduFactory.submit_sm_resp
    |> Pdu.as_reply_to(pdu)
  end

  defp submit_sm_ok_resp(pdu, st) do
    msg_id = st.last_msg_id + 1

    resp = :ROK
    |> Errors.code_by_name
    |> PduFactory.submit_sm_resp(to_string(msg_id))
    |> Pdu.as_reply_to(pdu)

    {resp, %MC{st | last_msg_id: msg_id}}
  end

  defp handle_unbind(pdu, st) do
    case st.state do
      :unbound ->
        {:ok, [unbind_resp(pdu, :RINVBNDSTS)], st}
      :bound ->
        {:ok, [unbind_resp(pdu, :ROK)], %MC{st | state: :terminating}}
      :terminating ->
        {:ok, [unbind_resp(pdu, :RINVBNDSTS)], st}
    end
  end

  defp unbind_resp(pdu, status) do
    code = Errors.code_by_name(status)
    PduFactory.unbind_resp(code) |> Pdu.as_reply_to(pdu)
  end

end
