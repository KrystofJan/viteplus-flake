{ pkgs, version ? null }:

let
  # Load version and platform info from JSON
  versionsFile = builtins.fromJSON (builtins.readFile ./versions.json);

  # Use provided version or default to latest
  resolvedVersion = if version == null then versionsFile.latest else version;

  # Platform mappings (nix system -> npm platform name)
  platformMappings = versionsFile.platforms;

  # Get hashes for the selected version
  versionHashes = versionsFile.versions.${resolvedVersion} or
    (throw "Unknown version: ${resolvedVersion}. Available: ${builtins.concatStringsSep ", " (builtins.attrNames versionsFile.versions)}");

  system = pkgs.stdenv.hostPlatform.system;
  npmPlatform = platformMappings.${system} or (throw "Unsupported system: ${system}");
  sha256 = versionHashes.${system} or (throw "No hash for system ${system} in version ${resolvedVersion}");

in
pkgs.stdenv.mkDerivation {
  pname = "vite-plus";
  version = resolvedVersion;

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@voidzero-dev/vite-plus-cli-${npmPlatform}/-/vite-plus-cli-${npmPlatform}-${resolvedVersion}.tgz";
    inherit sha256;
  };

  nativeBuildInputs = [ pkgs.gnutar ];

  # Unpack the npm tarball (it has a 'package' directory inside)
  unpackPhase = ''
    mkdir -p source
    tar xzf $src -C source --strip-components=1
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp source/vp $out/bin/vp
    chmod +x $out/bin/vp
  '';

  meta = with pkgs.lib; {
    description = "Vite+ - The Unified Toolchain for the Web";
    longDescription = ''
      Vite+ is the unified toolchain and entry point for web development.
      It manages your runtime, package manager, and frontend toolchain in one place
      by combining Vite, Vitest, Oxlint, Oxfmt, Rolldown, tsdown, and Vite Task.
    '';
    homepage = "https://viteplus.dev";
    license = licenses.mit;
    platforms = builtins.attrNames platformMappings;
    mainProgram = "vp";
  };
}

