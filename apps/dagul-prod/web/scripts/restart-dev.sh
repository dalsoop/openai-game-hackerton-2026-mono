#!/usr/bin/env bash
# restart-dev.sh — 로컬 개발 서버를 최신 코드로 재시작한다.
# 기존 프로세스를 PID 기반으로 정확히 죽이고, 포트·버전 검증까지 한 번에 처리한다.
# 사용: bash scripts/restart-dev.sh        (포그라운드 — Ctrl+C로 종료)
#       bash scripts/restart-dev.sh --bg   (백그라운드 — 로그는 /tmp/dagul-dev.log)
set -euo pipefail

PORT="${PORT:-3100}"
LOG="${DAGUL_DEV_LOG:-/tmp/dagul-dev.log}"
WAIT_SEC=15

cd "$(dirname "$0")/.."

# 1. 포트를 리슨 중인 node 프로세스를 전부 죽인다 (Chrome 등 비 node, CLOSED 소켓 잔재 제외).
kill_old() {
  local pids
  pids=$(lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null || true)
  for pid in $pids; do
    local cmd
    cmd=$(ps -o comm= -p "$pid" 2>/dev/null || true)
    if [[ "$cmd" == *node* ]]; then
      kill -9 "$pid" 2>/dev/null || true
      echo "killed old server PID=$pid"
    fi
  done
  # 포트 해제 대기
  local i=0
  while [ -n "$(lsof -ti :"$PORT" -sTCP:LISTEN 2>/dev/null)" ]; do
    sleep 0.3
    i=$((i + 1))
    if [ "$i" -gt 10 ]; then echo "WARN: port $PORT still held after 3s"; break; fi
  done
}

# 2. 서버 기동
start_server() {
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
