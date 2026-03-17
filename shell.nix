{ pkgs ? import <nixpkgs> { }, version ? null }:

let
  vite-plus = import ./default.nix { inherit pkgs version; };
in
pkgs.mkShell {
  buildInputs = [
    vite-plus
  ];

  shellHook = ''
    echo "Vite+ ${vite-plus.version} is available. Run 'vp help' to get started."
  '';
}

