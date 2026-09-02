#!/usr/bin/env bash
set -euo pipefail

# scripts/check-version.sh
# Checks the current packaged version against upstream YourDoritos/pVPN release.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_FILE="${REPO_ROOT}/pkgs/pvpn.nix"
UPSTREAM_REPO="YourDoritos/pVPN"

# Options
EXIT_CODE_ON_UPDATE=0
QUIET=0
JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --exit-code)
      EXIT_CODE_ON_UPDATE=1
      shift
      ;;
    --quiet|-q)
      QUIET=1
      shift
      ;;
    --json)
      JSON=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --exit-code   Exit with status 2 if an update is available"
      echo "  --quiet, -q   Suppress human-readable output"
      echo "  --json        Output result in JSON format"
      echo "  -h, --help    Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$PACKAGE_FILE" ]]; then
  echo "Error: package file not found at ${PACKAGE_FILE}" >&2
  exit 1
fi

CURRENT_VERSION=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$PACKAGE_FILE" | head -n1)

CURL_ARGS=(-sSL)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  CURL_ARGS+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

UPSTREAM_DATA=$(curl "${CURL_ARGS[@]}" "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" 2>/dev/null || true)

if [[ -z "$UPSTREAM_DATA" ]] || echo "$UPSTREAM_DATA" | grep -q "API rate limit exceeded"; then
  UPSTREAM_TAG=$(curl "${CURL_ARGS[@]}" "https://api.github.com/repos/${UPSTREAM_REPO}/tags" | jq -r '.[0].name' 2>/dev/null || true)
else
  UPSTREAM_TAG=$(echo "$UPSTREAM_DATA" | jq -r '.tag_name // empty' 2>/dev/null || true)
fi

if [[ -z "$UPSTREAM_TAG" || "$UPSTREAM_TAG" == "null" ]]; then
  echo "Error: Failed to fetch upstream version from GitHub" >&2
  exit 1
fi

LATEST_VERSION="${UPSTREAM_TAG#v}"

NEEDS_UPDATE="false"
if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
  NEEDS_UPDATE="true"
fi

# Export to GITHUB_OUTPUT if present
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "current_version=${CURRENT_VERSION}" >> "$GITHUB_OUTPUT"
  echo "latest_version=${LATEST_VERSION}" >> "$GITHUB_OUTPUT"
  echo "needs_update=${NEEDS_UPDATE}" >> "$GITHUB_OUTPUT"
fi

if [[ "$JSON" -eq 1 ]]; then
  jq -n \
    --arg current "$CURRENT_VERSION" \
    --arg latest "$LATEST_VERSION" \
    --arg needs_update "$NEEDS_UPDATE" \
    '{current_version: $current, latest_version: $latest, needs_update: ($needs_update == "true")}'
elif [[ "$QUIET" -eq 0 ]]; then
  echo "Current version : ${CURRENT_VERSION}"
  echo "Latest version  : ${LATEST_VERSION}"
  if [[ "$NEEDS_UPDATE" == "true" ]]; then
    echo "Status          : Update available (${CURRENT_VERSION} -> ${LATEST_VERSION})"
  else
    echo "Status          : Up to date"
  fi
fi

if [[ "$EXIT_CODE_ON_UPDATE" -eq 1 && "$NEEDS_UPDATE" == "true" ]]; then
  exit 2
fi

exit 0
