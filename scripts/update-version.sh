#!/usr/bin/env bash
set -euo pipefail

# scripts/update-version.sh [TARGET_VERSION]
# Updates pkgs/pvpn.nix to TARGET_VERSION (or latest upstream if omitted),
# recalculates source and vendor hashes, and verifies the build.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_FILE="${REPO_ROOT}/pkgs/pvpn.nix"
CHECK_SCRIPT="${REPO_ROOT}/scripts/check-version.sh"

TARGET_VERSION="${1:-}"

if [[ ! -f "$PACKAGE_FILE" ]]; then
  echo "Error: package file not found at ${PACKAGE_FILE}" >&2
  exit 1
fi

CURRENT_VERSION=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$PACKAGE_FILE" | head -n1)

if [[ -z "$TARGET_VERSION" ]]; then
  echo "No target version specified. Detecting latest upstream version..."
  LATEST_JSON=$("$CHECK_SCRIPT" --json)
  TARGET_VERSION=$(echo "$LATEST_JSON" | jq -r '.latest_version')
fi

# Strip leading 'v'
TARGET_VERSION="${TARGET_VERSION#v}"

echo "Current version : ${CURRENT_VERSION}"
echo "Target version  : ${TARGET_VERSION}"

if [[ "$CURRENT_VERSION" == "$TARGET_VERSION" ]]; then
  echo "Package is already at version ${TARGET_VERSION}. Nothing to do."
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "updated=false" >> "$GITHUB_OUTPUT"
    echo "version=${TARGET_VERSION}" >> "$GITHUB_OUTPUT"
  fi
  exit 0
fi

echo "Updating pvpn: ${CURRENT_VERSION} -> ${TARGET_VERSION}..."

cd "$REPO_ROOT"

# Use nix-update to update version, source hash, and vendor hash
nix run nixpkgs#nix-update -- --flake --version "$TARGET_VERSION" pvpn

echo "Verifying flake evaluation..."
nix flake check

echo "Building updated package..."
nix build .#pvpn

BUILT_VERSION=$("./result/bin/pvpn" --version | awk '{print $2}')
echo "Verified built pvpn binary version: ${BUILT_VERSION}"
rm -f result

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "old_version=${CURRENT_VERSION}" >> "$GITHUB_OUTPUT"
  echo "new_version=${TARGET_VERSION}" >> "$GITHUB_OUTPUT"
  echo "updated=true" >> "$GITHUB_OUTPUT"
fi

echo "Successfully updated pvpn from ${CURRENT_VERSION} to ${TARGET_VERSION}!"
