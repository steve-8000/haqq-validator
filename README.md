# haqq-validator

Build
```docker build \
  --build-arg DAEMON_NAME=haqqd \
  --build-arg COSMOVISOR_VERSION=v1.7.1 \
  --build-arg BINARY_URL="https://github.com/haqq-network/haqq/releases/download/v1.8.5/haqq_1.8.5_linux_amd64.tar.gz" \
  -t haqqd-cosmovisor:1.0 .

Run
```mkdir -p /srv/nodes/haqq/haqqd-main
docker run -d --name haqqd-cosmovisor-mainnet --network host \
  -v /srv/nodes/haqq/haqqd-main:/data/.haqqd \
  -e MONIKER="A41" -e PORT="26" \
  -e CHAIN_ID="haqq_11235-1" \
  -e GENESIS_URL="https://raw.githubusercontent.com/haqq-network/mainnet/master/genesis.json" \
  -e ADDRBOOK_URL="https://raw.githubusercontent.com/haqq-network/mainnet/master/addrbook.json" \
  haqqd-cosmovisor:1.0

Log
```docker logs -f haqqd-cosmovisor-mainnet

syscinfo
```docker exec -it haqqd-cosmovisor-mainnet haqqd status | jq .SyncInfo

Snapshot
```chmod +x snapshot.sh
./snapshot.sh haqqd-cosmovisor-mainnet /path/to/haqq_height.tar.lz4

docker cmd
```docker exec -it haqqd-cosmovisor-mainnet bash
docker stop haqqd-cosmovisor-mainnet
docker start haqqd-cosmovisor-mainnet
docker restart haqqd-cosmovisor-mainnet

docker rm
``` docker rm -f haqqd-cosmovisor-mainnet
docker rmi haqqd-cosmovisor:1.0
sudo rm -rf /srv/nodes/haqq/haqqd-main
