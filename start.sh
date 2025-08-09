#!/usr/bin/env bash
set -euo pipefail
DAEMON_NAME="${DAEMON_NAME:-haqqd}"
DAEMON_HOME="${DAEMON_HOME:-/data/.${DAEMON_NAME}}"
CHAIN_ID="${CHAIN_ID:-haqq_11235-1}"
MONIKER="${MONIKER:-A41}"
PORT="${PORT:-26}"
GENESIS_URL="${GENESIS_URL:-https://raw.githubusercontent.com/haqq-network/mainnet/master/genesis.json}"
ADDRBOOK_URL="${ADDRBOOK_URL:-https://raw.githubusercontent.com/haqq-network/mainnet/master/addrbook.json}"
TZ="${TZ:-Asia/Seoul}"
export TZ
export HOME="${HOME:-/root}"
NODE_HOME="${DAEMON_HOME}"
mkdir -p "${NODE_HOME}/cosmovisor/genesis/bin"
if [ ! -x "${NODE_HOME}/cosmovisor/genesis/bin/${DAEMON_NAME}" ]; then
  install -m 0755 "/usr/local/bin/${DAEMON_NAME}" "${NODE_HOME}/cosmovisor/genesis/bin/${DAEMON_NAME}"
fi
if [ ! -f "${NODE_HOME}/.initialized" ]; then
  "${DAEMON_NAME}" config chain-id "${CHAIN_ID}" --home "${NODE_HOME}"
  "${DAEMON_NAME}" init "${MONIKER}" --chain-id "${CHAIN_ID}" --home "${NODE_HOME}"
  curl -fsSL "${GENESIS_URL}" -o "${NODE_HOME}/config/genesis.json"
  curl -fsSL "${ADDRBOOK_URL}" -o "${NODE_HOME}/config/addrbook.json"
  touch "${NODE_HOME}/.initialized"
fi
CONFIG_DIR="${NODE_HOME}/config"
sed -i -e "s/^moniker *=.*/moniker = \"${MONIKER}\"/" "${CONFIG_DIR}/config.toml" || true
sed -i "s/laddr = \"tcp:\/\/0\.0\.0\.0:26656\"/laddr = \"tcp:\/\/0\.0\.0\.0:${PORT}656\"/" "${CONFIG_DIR}/config.toml" || true
sed -i "s/laddr = \"tcp:\/\/127\.0\.0\.1:26657\"/laddr = \"tcp:\/\/127\.0\.0\.1:${PORT}657\"/" "${CONFIG_DIR}/config.toml" || true
sed -i "s/^proxy_app = .*/proxy_app = \"tcp:\/\/127\.0\.0\.1:${PORT}658\"/" "${CONFIG_DIR}/config.toml" || true
sed -i "s/^pprof_laddr = .*/pprof_laddr = \"0.0.0.0:${PORT}060\"/" "${CONFIG_DIR}/config.toml" || true
sed -i "s/prometheus_listen_addr = \".*\"/prometheus_listen_addr = \"0.0.0.0:${PORT}660\"/" "${CONFIG_DIR}/config.toml" || true
sed -i -E "/^\[json-rpc\]/,/^\[/{ s#^address *= *\".*\"#address = \"0.0.0.0:${PORT}545\"#; s#^ws-address *= *\".*\"#ws-address = \"0.0.0.0:${PORT}546\"# }" "${CONFIG_DIR}/app.toml" || true
sed -i "s/^rpc-dial-url *=.*/rpc-dial-url = \"http:\/\/localhost:${PORT}551\"/" "${CONFIG_DIR}/app.toml" || true
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" "${CONFIG_DIR}/config.toml" || true
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" "${CONFIG_DIR}/app.toml" || true
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" "${CONFIG_DIR}/app.toml" || true
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" "${CONFIG_DIR}/app.toml" || true
sed -i "s|laddr = \"tcp://127.0.0.1:${PORT}657\"|laddr = \"tcp://0.0.0.0:${PORT}657\"|" "${CONFIG_DIR}/config.toml" || true
export DAEMON_HOME="${NODE_HOME}"
export DAEMON_NAME="${DAEMON_NAME}"
UPPER="$(printf "%s" "${DAEMON_NAME}" | tr '[:lower:]' '[:upper:]')"
export "${UPPER}_HOME"="${NODE_HOME}"
exec cosmovisor run start --home "${NODE_HOME}"
