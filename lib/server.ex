defmodule Maelstrom.Server do
  @moduledoc """
  A server/node process which acts on input messages.
  """
  use GenServer

  def start_link() do
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
    message
    |> Jason.decode!()
    |> process_message(state)
    |> create_reply()
  end

  defp process_message(%{"body" => %{"type" => "init"}} = message, state) do
    initialise(message, state)
  end

  defp process_message(%{"body" => %{"type" => "echo"}} = message, state) do
    echo(message, state)
  end

  defp process_message(%{"body" => %{"type" => message_type}}, state),
    do: {:error, "Unknown message type #{message_type}", state}

  defp create_reply({status, response, state}) do
    response = {status, Jason.encode!(response)}
    {:reply, response, increment_message_id(state)}
  end

  defp increment_message_id(%{next_message_id: next_message_id} = state) do
    %{state | next_message_id: next_message_id + 1}
  end

  defp initialise(%{"body" => %{"node_id" => node_id}} = message, state) do
    IO.puts(:stderr, "Initialising node to ID #{node_id}")

    state = %{state | node_id: node_id}

    response =
      message
      |> create_response(state)
      |> set_type("init_ok")

    {:ok, response, state}
  end

  defp echo(message, state) do
    response =
      message
      |> create_response(state)
      |> set_body("echo", message["body"]["echo"])
      |> set_type("echo_ok")

    {:ok, response, state}
  end

  defp create_response(
         %{"src" => src, "body" => %{"msg_id" => incoming_message_id}},
         %{next_message_id: outgoing_message_id, node_id: node_id} = _state
       ) do
    %{"src" => node_id, "dest" => src, "body" => %{}}
    |> set_body("msg_id", outgoing_message_id)
    |> set_body("in_reply_to", incoming_message_id)
  end

  defp set_body(message, key, value) do
    message
    |> put_in(["body", key], value)
  end

  defp set_type(message, type) do
    message
    |> set_body("type", type)
  end
end
