defmodule Maelstrom.Server do
  @moduledoc """
  A server/node process which acts on input messages.
  """
  use GenServer

  @impl true
  def init(_args) do
    {:ok, %{node_id: nil, next_message_id: 0}}
  end

  @impl true
  def handle_call({:msg, msg}, _from, %{next_message_id: next_message_id} = state) do
    payload = Jason.decode!(msg)

    {response, state} =
      case payload["body"]["type"] do
        "init" ->
          {reply, state} = initialise(payload, state)
          {{:ok, Jason.encode!(reply)}, state}

        "echo" ->
          {reply, state} = echo(payload, state)
          {{:ok, Jason.encode!(reply)}, state}

        other ->
          {{:error, "Unknown message type #{other}"}, state}
      end

    {:reply, response, %{state | next_message_id: next_message_id + 1}}
  end

  defp initialise(%{"body" => %{"node_id" => node_id}} = payload, state) do
    IO.puts(:stderr, "Initialising node to ID #{node_id}")

    state = %{state | node_id: node_id}
    reply = put_in(reply_to_sender(payload, state), ["body", "type"], "init_ok")
    {reply, state}
  end

  defp echo(payload, state) do
    reply = put_in(reply_to_sender(payload, state), ["body", "type"], "echo_ok")
    {reply, state}
  end

  defp reply_to_sender(%{"src" => src, "body" => body}, state) do
    # Set msg_id to our current next ID and set te reply-to to the payload's ID.
    body = Map.put(%{body | "msg_id" => state[:next_message_id]}, "in_reply_to", body["msg_id"])
    # Swap src and dest and use the new body.
    %{"src" => state[:node_id], "dest" => src, "body" => body}
  end
end
