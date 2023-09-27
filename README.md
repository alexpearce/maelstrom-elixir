# Maelstrom in Elixir

An Elixir implementation of servers that handle [Maelstrom][maelstrom]
workloads.

[maelstrom]: https://github.com/jepsen-io/maelstrom

## Running

This project uses [Nix][nix] to define its dependencies and [direnv][direnv] to
automatically load them upon entering the project directory.

Clone the repository, enter the directory, and run `direnv allow` to get
get the environment up and running.

Run `bin/maelstrom` to run the tests against the echo server.

[nix]: https://nixos.org/
[direnv]: https://direnv.net/

## Concepts

Abstract:

- Server receives message.
- Server spawns a process to handle the message. Server is then able to receive
  subsequent messages immediately.
- Process emits messages as required.
- Some messages produce results which must be remembered by the server to be
  passed to subsequent messages.

Concrete:

- GenServer 1 receives messages.
- GenServer 1 calls GenServer 2, GenServer 2 spawns the handling process.
- Handling process emits messages as required.
- Upon completion, the handling process can choose to send a message to
  GenServer 1 ask it to update its state.