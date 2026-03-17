# Vite+ Nix Flake

Nix flake for [Vite+](https://viteplus.dev) — The Unified Toolchain for the Web.

## Usage

### In a Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    viteplus.url = "github:KrystofJan/viteplus-flake";
  };

  outputs = { nixpkgs, viteplus, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          viteplus.packages.${system}.vite-plus        # latest
          # viteplus.packages.${system}.vite-plus-0_1_12  # specific version
        ];
      };
    };
}
```

### Standalone

```bash
nix shell github:KrystofJan/viteplus-flake
nix run github:KrystofJan/viteplus-flake -- help
```

## Updating

```bash
./update.sh          # add latest version
./update.sh 0.1.13   # add specific version
```

The script updates `versions.json` and sets the `latest` pointer.

## Available Packages

- `vite-plus` / `default` — latest version
- `vite-plus-X_Y_Z` — specific version (e.g., `vite-plus-0_1_12`)

