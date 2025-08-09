#!/usr/bin/env bash
set -euo pipefail
PLAN="${1:-}"
ASSET_URL="${2:-}"
[ -n "$PLAN" ] || { echo "usage: cosmovisor-upgrade <plan_name> <asset_url>"; exit 1; }
[ -n "$ASSET_URL" ] || { echo "asset_url required"; exit 1; }
DAEMON_NAME="${DAEMON_NAME:-haqqd}"
DAEMON_HOME="${DAEMON_HOME:-/data/.${DAEMON_NAME}}"
mkdir -p "${DAEMON_HOME}/cosmovisor/upgrades/${PLAN}/bin"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$ASSET_URL" -o "$TMP/asset.tar.gz"
mkdir -p "$TMP/asset" && tar -xzf "$TMP/asset.tar.gz" -C "$TMP/asset"
BIN_PATH="$(find "$TMP/asset" -maxdepth 3 -type f -name "${DAEMON_NAME}" -perm -111 | head -n1)"
[ -n "$BIN_PATH" ] || BIN_PATH="$(find "$TMP/asset" -maxdepth 3 -type f -perm -111 -name '*d' | head -n1)"
[ -n "$BIN_PATH" ] || { ls -R "$TMP/asset"; echo "daemon binary not found"; exit 1; }
install -m 0755 "$BIN_PATH" "${DAEMON_HOME}/cosmovisor/upgrades/${PLAN}/bin/${DAEMON_NAME}"
echo "installed upgrade binary -> ${DAEMON_HOME}/cosmovisor/upgrades/${PLAN}/bin/${DAEMON_NAME}"
