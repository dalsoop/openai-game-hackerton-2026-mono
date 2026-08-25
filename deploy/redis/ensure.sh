#!/bin/sh
# 로컬 Redis 1대. docker compose 가 되면 그걸 쓰고, 아니면 redis-server.
set -e
ROOT=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
if nc -z 127.0.0.1 6379 >/dev/null 2>&1; then
  echo "redis already on 127.0.0.1:6379"
  exit 0
fi
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  docker compose -f "$ROOT/compose.yaml" up -d --wait
  exit 0
fi
if command -v redis-server >/dev/null 2>&1; then
  redis-server --daemonize yes --port 6379 --bind 127.0.0.1 --maxmemory-policy noeviction --save ""
  echo "redis-server on 127.0.0.1:6379"
  exit 0
fi
echo "Redis 를 못 띄웠습니다. OrbStack/Docker 를 켜거나 brew install redis 하세요." >&2
exit 1
