# Harness for starting and driving one of our Maelstrom server implementations.
#
# 1. Starts a server based on the value of the command-line argument.
# 2. Sends each newline-separated chunk from stdin to the server.
# 3. Prints the response of the server to stdout if the server replies :ok or
#    stderr otherwise.
IO.puts(:stderr, "Starting server…")
{:ok, pid} = Maelstrom.Server.start_link()
IO.puts(:stderr, "Server started.")

IO.stream(:stdio, :line)
  |> Enum.each(&Maelstrom.Server.process(pid, &1))
