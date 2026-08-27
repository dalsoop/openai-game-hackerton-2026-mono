#!/usr/bin/env bash
# restart-dev.sh — 로컬 개발 서버를 최신 코드로 재시작한다.
# 기존 프로세스를 PID 기반으로 정확히 죽이고, 포트·버전 검증까지 한 번에 처리한다.
# 사용: bash scripts/restart-dev.sh        (포그라운드 — Ctrl+C로 종료)
#       bash scripts/restart-dev.sh --bg   (백그라운드 — 로그는 /tmp/dagul-dev.log)
set -euo pipefail

PORT="${PORT:-3100}"
LOG="${DAGUL_DEV_LOG:-/tmp/dagul-dev.log}"
WAIT_SEC=15
# Colyseus Server 는 gracefullyShutdown 기본값 true 로 SIGTERM 에서 matchMaker를
# 정리(Redis 방 등록 해제)한다. 기존엔 바로 kill -9(SIGKILL) 를 써서 이 정리를
# 건너뛰었다 — 재시작마다 Redis 에 낡은 방 등록이 남아, 다음 프로세스가 새
# 스키마로 그 방을 이어받거나 매치메이커가 죽은 방을 찾는 사고로 이어졌다.
GRACEFUL_WAIT_SEC="${GRACEFUL_WAIT_SEC:-10}"

cd "$(dirname "$0")/.."

# 1. 포트를 리슨 중인 node 프로세스를 SIGTERM으로 먼저 내린다(Colyseus 가
#    gracefullyShutdown 으로 Redis 방 등록을 지울 시간을 준다). 그 안에 안
#    죽으면 그때만 SIGKILL 로 강제 종료한다. Chrome 등 비 node 프로세스는 건너뛴다.
kill_old() {
  local pids
  pids=$(lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null || true)
  local node_pids=""
  for pid in $pids; do
    local cmd
    cmd=$(ps -o comm= -p "$pid" 2>/dev/null || true)
    if [[ "$cmd" == *node* ]]; then
      node_pids="$node_pids $pid"
    fi
  done
  if [ -z "$node_pids" ]; then
    return 0
  fi
  # shellcheck disable=SC2086
  kill -TERM $node_pids 2>/dev/null || true
  echo "SIGTERM sent to old server PID=$node_pids — Colyseus gracefulShutdown 대기 중"
  local i=0
  while [ -n "$(lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null)" ]; do
    sleep 0.3
    i=$((i + 1))
    if [ "$i" -gt $((GRACEFUL_WAIT_SEC * 10 / 3)) ]; then
      echo "WARN: graceful shutdown 안 끝남(${GRACEFUL_WAIT_SEC}s) — SIGKILL 로 강제 종료"
      # shellcheck disable=SC2086
      kill -9 $node_pids 2>/dev/null || true
      break
    fi
  done
  # SIGKILL 로 내렸다면 포트 해제까지 다시 짧게 대기.
  local j=0
  while [ -n "$(lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null)" ]; do
    sleep 0.3
    j=$((j + 1))
    if [ "$j" -gt 10 ]; then echo "WARN: port $PORT still held after 3s"; break; fi
  done
}

# 2. 서버 기동
start_server() {
  export DAGUL_SKILLS="${DAGUL_SKILLS:-on}"
  if [[ "${1:-}" == "--bg" ]]; then
    nohup npm run dev > "$LOG" 2>&1 &
    echo "started in background PID=$! log=$LOG"
  else
    exec npm run dev
  fi
}

# 3. 포트 리슨 + /api/version 검증
verify() {
  echo -n "waiting for :$PORT ..."
  local i=0
  while ! curl -sf "http://127.0.0.1:$PORT/api/version" > /dev/null 2>&1; do
    sleep 1
    i=$((i + 1))
    if [ "$i" -ge "$WAIT_SEC" ]; then
      echo " TIMEOUT (${WAIT_SEC}s)"
      exit 1
    fi
  done
  echo " OK"
  local ver
  ver=$(curl -s "http://127.0.0.1:$PORT/api/version")
  # LISTEN 상태만 — 남의 CLOSED 소켓 잔재(예: VS Code 헬퍼)를 서버로 오인하지 않는다.
  local pid
  pid=$(lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null | head -1)
  local started
  started=$(ps -o lstart= -p "$pid" 2>/dev/null || echo "?")
  echo "version: $ver"
  echo "PID=$pid started=$started"
}

# --- main ---
kill_old

if [[ "${1:-}" == "--bg" ]]; then
  start_server --bg
  verify
else
  start_server
fi
