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

