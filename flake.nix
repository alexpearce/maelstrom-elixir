{
  description = "Elixir + Maelstrom environment.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        maelstrom =
          let
            jre = pkgs.openjdk19;
          in
          pkgs.stdenv.mkDerivation rec {
            name = "maelstrom";
            version = "0.2.2";
            src = pkgs.fetchzip {
              url = "https://github.com/jepsen-io/${name}/releases/download/v${version}/maelstrom.tar.bz2";
              sha256 = "sha256-v4kZbEu1l3YPFgYhLrdNZOvKBOWnq8lAJRPf1JVQWEE=";
            };
            nativeBuildInputs = [ pkgs.makeWrapper ];
            # Run the Maelstrom jar file under a JRE and include graphviz and
            # gnuplot as runtime dependencies.
            # Inspired by:
            # https://github.com/NixOS/nixpkgs/blob/32a93b58b2eab85e31cff79662c4e6056f18d9fd/pkgs/development/tools/java/cfr/default.nix
            buildCommand = ''
              jar=$out/share/java/${name}_${version}.jar
              install -Dm444 $src/lib/maelstrom.jar $jar
              install -Dm444 $src/maelstrom $out/maelstrom-wrapper
              makeWrapper ${jre}/bin/java $out/bin/maelstrom \
                --add-flags "-Djava.awt.headless=true -jar $jar" \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.graphviz pkgs.gnuplot ]}
            '';
          };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # For our server implementation.
            beam.packages.erlangR25.elixir_1_14
            # For Maelstrom.
            maelstrom
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Support Elixir file system watcher on macOS.
            pkgs.darwin.apple_sdk.frameworks.CoreFoundation
            pkgs.darwin.apple_sdk.frameworks.CoreServices
          ];
        };
      });
}
