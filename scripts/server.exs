# Harness for starting and driving one of our Maelstrom server implementations.
#
# 1. Starts a server based on the value of the command-line argument.
# 2. Sends each newline-separated chunk from stdin to the server.
# 3. Prints the response of the server to stdout if the server replies :ok or
#    stderr otherwise.
IO.puts(:stderr, "Starting server…")
{:ok, pid} = GenServer.start_link(Maelstrom.Server, nil)

Enum.each(IO.stream(:stdio, :line), fn message ->
  case GenServer.call(pid, {:msg, message}) do
    {:ok, reply} -> IO.puts(reply)
    {:error, reply} -> IO.puts(:stderr, reply)
  end
end)
