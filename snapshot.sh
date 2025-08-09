#!/usr/bin/env bash
set -euo pipefail
CN="${1:-}"
SRC="${2:-}"
if [ -z "$CN" ] || [ -z "$SRC" ]; then
  echo "usage: snapshot.sh <container-name> <path/to/snapshot.lz4 | https-url>"
  exit 1
fi
ENVV="$(docker inspect "$CN" --format '{{range .Config.Env}}{{println .}}{{end}}' || true)"
DAEMON_HOME="$(printf "%s\n" "$ENVV" | awk -F= '/^DAEMON_HOME=/{print $2; exit}')"
DAEMON_NAME="$(printf "%s\n" "$ENVV" | awk -F= '/^DAEMON_NAME=/{print $2; exit}')"
IMAGE="$(docker inspect "$CN" --format '{{.Config.Image}}' || true)"
USEROPT="$(docker inspect "$CN" --format '{{.Config.User}}' || true)"
[ -n "$DAEMON_NAME" ] || DAEMON_NAME="haqqd"
[ -n "$DAEMON_HOME" ] || DAEMON_HOME="/data/.${DAEMON_NAME}"
[ -n "$IMAGE" ] || { echo "ERROR: image not found for $CN"; exit 1; }
MAP="$(docker inspect "$CN" --format '{{range .Mounts}}{{println .Destination " " .Source}}{{end}}')"
HOST_DIR="$(printf "%s\n" "$MAP" | awk -v d="$DAEMON_HOME" '$1==d{print $2; exit}')"
[ -n "$HOST_DIR" ] || { echo "ERROR: bind mount for ${DAEMON_HOME} not found"; exit 1; }
RUNAS=()
if [ -n "$USEROPT" ]; then RUNAS=(-u "$USEROPT"); fi
docker stop "$CN"
if [[ "$SRC" =~ ^https?:// ]]; then
  docker run --rm "${RUNAS[@]}" -e DAEMON_NAME="$DAEMON_NAME" -e DAEMON_HOME="$DAEMON_HOME" -v "$HOST_DIR:$DAEMON_HOME" "$IMAGE" /bin/bash -lc '
    set -euo pipefail
    TMP="$(mktemp -d)"; trap "rm -rf \"$TMP\"" EXIT
    curl -fL --retry 3 -o "$TMP/snap.lz4" "'"$SRC"'"
    if [ -s "'"$DAEMON_HOME"'/data/priv_validator_state.json" ]; then cp "'"$DAEMON_HOME"'/data/priv_validator_state.json" "'"$DAEMON_HOME"'/priv_validator_state.json"; fi
    "'"$DAEMON_NAME"'" tendermint unsafe-reset-all --home "'"$DAEMON_HOME"'" --keep-addr-book
    lz4 -dc "$TMP/snap.lz4" | tar -x -C "'"$DAEMON_HOME"'"
    if [ -s "'"$DAEMON_HOME"'/priv_validator_state.json" ]; then cp "'"$DAEMON_HOME"'/priv_validator_state.json" "'"$DAEMON_HOME"'/data/priv_validator_state.json"; fi
  '
else
  ABS="$(readlink -f "$SRC")"; DIR="$(dirname "$ABS")"; FILE="$(basename "$ABS")"
  docker run --rm "${RUNAS[@]}" -e DAEMON_NAME="$DAEMON_NAME" -e DAEMON_HOME="$DAEMON_HOME" -v "$HOST_DIR:$DAEMON_HOME" -v "$DIR:/snap" "$IMAGE" /bin/bash -lc '
    set -euo pipefail
    if [ -s "'"$DAEMON_HOME"'/data/priv_validator_state.json" ]; then cp "'"$DAEMON_HOME"'/data/priv_validator_state.json" "'"$DAEMON_HOME"'/priv_validator_state.json"; fi
    "'"$DAEMON_NAME"'" tendermint unsafe-reset-all --home "'"$DAEMON_HOME"'" --keep-addr-book
    lz4 -dc "/snap/'"$FILE"'" | tar -x -C "'"$DAEMON_HOME"'"
    if [ -s "'"$DAEMON_HOME"'/priv_validator_state.json" ]; then cp "'"$DAEMON_HOME"'/priv_validator_state.json" "'"$DAEMON_HOME"'/data/priv_validator_state.json"; fi
  '
fi
docker start "$CN"
echo "done"
