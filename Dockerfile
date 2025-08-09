FROM golang:1.23 AS builder
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl jq lz4 tar bash git && rm -rf /var/lib/apt/lists/*
RUN go env -w GOMODCACHE=/go/pkg/mod
ARG COSMOVISOR_VERSION="v1.7.1"
RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@${COSMOVISOR_VERSION}
ARG DAEMON_NAME="haqqd"
ARG BINARY_URL="https://github.com/haqq-network/haqq/releases/download/v1.8.5/haqq_1.8.5_linux_amd64.tar.gz"
RUN set -eux; \
    test -n "${BINARY_URL}"; \
    curl -fsSL "${BINARY_URL}" -o /tmp/asset.tar.gz; \
    mkdir -p /tmp/asset && tar -xzf /tmp/asset.tar.gz -C /tmp/asset; \
    BIN_PATH="$(find /tmp/asset -maxdepth 3 -type f -name "${DAEMON_NAME}" -perm -111 | head -n1)"; \
    if [ -z "$BIN_PATH" ]; then BIN_PATH="$(find /tmp/asset -maxdepth 3 -type f -perm -111 -name '*d' | head -n1)"; fi; \
    test -n "$BIN_PATH"; \
    install -m 0755 "$BIN_PATH" /usr/local/bin/${DAEMON_NAME}; \
    /usr/local/bin/${DAEMON_NAME} version || true

FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl jq lz4 tini bash sed && rm -rf /var/lib/apt/lists/*
ENV PATH="/usr/local/bin:${PATH}"
ENV CHAIN_ID="haqq_11235-1"
ENV MONIKER="A41"
ENV PORT="26"
ENV GENESIS_URL="https://raw.githubusercontent.com/haqq-network/mainnet/master/genesis.json"
ENV ADDRBOOK_URL="https://raw.githubusercontent.com/haqq-network/mainnet/master/addrbook.json"
ENV TZ="Asia/Seoul"
WORKDIR /work
COPY start.sh /start.sh
COPY cosmovisor-upgrade.sh /usr/local/bin/cosmovisor-upgrade
COPY --from=builder /go/bin/cosmovisor /usr/local/bin/cosmovisor
ARG DAEMON_NAME="haqqd"
COPY --from=builder /usr/local/bin/${DAEMON_NAME} /usr/local/bin/${DAEMON_NAME}
RUN chmod +x /start.sh /usr/local/bin/cosmovisor-upgrade
ENTRYPOINT ["/usr/bin/tini","-g","--"]
CMD ["/start.sh"]
