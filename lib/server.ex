defmodule Maelstrom.Server do
  @moduledoc """
  A server/node process which acts on input messages.
  """
  use GenServer

  # Keys which are part of the body specification but which
  # consider part of the 'message data', i.e. the envelope.
  @body_envelope_keys [:type, :msg_id, :in_reply_to]

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def process(pid, message) do
    GenServer.call(pid, {:message, message})
  end

  @impl true
  def init(_args) do
    {:ok, %{node_id: nil, next_message_id: 0}}
  end

  @impl true
  def handle_call({:message, message}, _from, state) do
    log("Handling message ID #{state[:next_message_id]}")
    spawn_process_message(message, state)
    {:reply, :ok, increment_message_id(state)}
  end

  @impl true
  def handle_info({:update_state, state_updates}, state) do
    {:noreply, Map.merge(state, state_updates)}
  end

  defp spawn_process_message(message, state) do
    spawn(__MODULE__, :do_process_message, [message, self(), state])
  end

  def do_process_message(message, from, state) do
    with {:ok, payload} <- Jason.decode(message),
         {envelope, body} <- parse_request(payload),
         {:ok, state} <- process_message(envelope, body, state) do
      send(from, {:update_state, state})
    else
      {:error, reason} -> log("Error: #{reason}")
    end
  end

  defp parse_request(%{"src" => src, "dest" => dest, "body" => original_body}) do
    original_envelope = %{src: src, dest: dest}
    # Strip out what we consider envelope parameters from the body,
    # resulting in a unified envelope and a minimal body.
    @body_envelope_keys
    |> Enum.reduce({original_envelope, original_body}, fn key, {envelope, body} ->
      {value, body} = Map.pop(body, Atom.to_string(key))
      {Map.put(envelope, key, value), body}
    end)
  end

  defp process_message(%{type: "init"} = envelope, %{"node_id" => node_id}, state) do
    send_reply(envelope, state, type: "init_ok")

    {:ok, %{node_id: node_id}}
  end

  defp process_message(%{type: "echo"} = envelope, %{"echo" => echo}, state) do
    send_reply(envelope, state, type: "echo_ok", echo: echo)

    {:ok, %{}}
  end

  defp process_message(envelope, _body, _state),
    do: {:error, "Unknown message type in envelope: #{inspect(envelope)}"}

  defp increment_message_id(state) do
    Map.update!(state, :next_message_id, &(&1 + 1))
  end

  defp send_reply(envelope, state, body_items) do
    log("Sending message ID #{envelope.msg_id}")

    body =
      body_items
      |> Map.new()
      |> Map.merge(%{msg_id: state.next_message_id, in_reply_to: envelope.msg_id})

    %{src: envelope.dest, dest: envelope.src, body: body}
    |> Jason.encode!()
    |> IO.puts()
  end

  defp log(message), do: IO.puts(:stderr, message)
end
