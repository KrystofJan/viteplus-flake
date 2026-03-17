{
  description = "Vite+ - The Unified Toolchain for the Web";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Load version info from JSON
      versionsFile = builtins.fromJSON (builtins.readFile ./versions.json);
      latestVersion = versionsFile.latest;
      availableVersions = builtins.attrNames versionsFile.versions;

      supportedSystems = builtins.attrNames versionsFile.platforms;

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Helper to create a package for a specific version
      mkVitePlus = pkgs: version: import ./default.nix { inherit pkgs version; };

    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Create versioned packages (e.g., vite-plus-0_1_12)
          versionedPackages = builtins.listToAttrs (map (version: {
            name = "vite-plus-${builtins.replaceStrings ["."] ["_"] version}";
            value = mkVitePlus pkgs version;
          }) availableVersions);
        in
        versionedPackages // {
          vite-plus = mkVitePlus pkgs null;  # latest
          default = mkVitePlus pkgs null;    # latest
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = import ./shell.nix { inherit pkgs; };
        }
      );

      # Expose the lib for programmatic access to versions
      lib = {
        inherit latestVersion availableVersions;
        mkVitePlus = pkgs: version: mkVitePlus pkgs version;
      };
    };
}
