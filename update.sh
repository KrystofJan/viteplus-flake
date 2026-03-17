#!/usr/bin/env bash
# Update script for vite-plus Nix package
# This script fetches versions and updates versions.json
#
# Usage: ./update.sh [version]
#   version: Optional specific version to add (default: latest from npm)
#
# Examples:
#   ./update.sh           # Add/update latest version
#   ./update.sh 0.1.11    # Add specific version

set -euo pipefail

VERSION="${1:-latest}"
NPM_REGISTRY="https://registry.npmjs.org"
VERSIONS_FILE="versions.json"

# Platform mappings: nix-system -> npm-platform
declare -A PLATFORMS=(
  ["x86_64-linux"]="linux-x64-gnu"
  ["aarch64-linux"]="linux-arm64-gnu"
  ["x86_64-darwin"]="darwin-x64"
  ["aarch64-darwin"]="darwin-arm64"
)

# Fetch the resolved version from npm
echo "Fetching version info..."
if [ "$VERSION" = "latest" ]; then
  RESOLVED_VERSION=$(curl -s "${NPM_REGISTRY}/vite-plus/latest" | jq -r '.version')
else
  RESOLVED_VERSION="$VERSION"
fi

echo "Adding version: $RESOLVED_VERSION"

# Check if version already exists
if [ -f "$VERSIONS_FILE" ]; then
  EXISTING=$(jq -r ".versions.\"${RESOLVED_VERSION}\" // empty" "$VERSIONS_FILE")
  if [ -n "$EXISTING" ]; then
    echo "Version $RESOLVED_VERSION already exists in $VERSIONS_FILE"
    read -p "Overwrite? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 0
    fi
  fi
fi

# Fetch SHA256 for each platform
declare -A HASHES
for NIX_SYSTEM in "${!PLATFORMS[@]}"; do
  NPM_PLATFORM="${PLATFORMS[$NIX_SYSTEM]}"
  TARBALL_URL="${NPM_REGISTRY}/@voidzero-dev/vite-plus-cli-${NPM_PLATFORM}/-/vite-plus-cli-${NPM_PLATFORM}-${RESOLVED_VERSION}.tgz"

  echo "Fetching hash for ${NIX_SYSTEM} (${NPM_PLATFORM})..."
  HASHES[$NIX_SYSTEM]=$(nix-prefetch-url "$TARBALL_URL" 2>/dev/null)
done

# Build version hashes JSON object
VERSION_HASHES=$(jq -n \
  --arg linux_x64 "${HASHES[x86_64-linux]}" \
  --arg linux_arm64 "${HASHES[aarch64-linux]}" \
  --arg darwin_x64 "${HASHES[x86_64-darwin]}" \
  --arg darwin_arm64 "${HASHES[aarch64-darwin]}" \
  '{
    "x86_64-linux": $linux_x64,
    "aarch64-linux": $linux_arm64,
    "x86_64-darwin": $darwin_x64,
    "aarch64-darwin": $darwin_arm64
  }')

# Update or create versions.json
if [ -f "$VERSIONS_FILE" ]; then
  # Update existing file
  jq --arg ver "$RESOLVED_VERSION" \
     --argjson hashes "$VERSION_HASHES" \
     '.latest = $ver | .versions[$ver] = $hashes' \
     "$VERSIONS_FILE" > "${VERSIONS_FILE}.tmp"
  mv "${VERSIONS_FILE}.tmp" "$VERSIONS_FILE"
else
  # Create new file
  jq -n \
    --arg ver "$RESOLVED_VERSION" \
    --argjson hashes "$VERSION_HASHES" \
    '{
      latest: $ver,
      platforms: {
        "x86_64-linux": "linux-x64-gnu",
        "aarch64-linux": "linux-arm64-gnu",
        "x86_64-darwin": "darwin-x64",
        "aarch64-darwin": "darwin-arm64"
      },
      versions: {
        ($ver): $hashes
      }
    }' > "$VERSIONS_FILE"
fi

echo ""
echo "Updated $VERSIONS_FILE"
echo ""
cat "$VERSIONS_FILE"

