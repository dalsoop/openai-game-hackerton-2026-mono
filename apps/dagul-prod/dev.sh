#!/usr/bin/env bash
# 로컬 개발 실행 — 웹 플랫폼(허브+로비+Godot 로딩)은 apps/dagul-prod/web 이 정본.
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$APP_DIR"
WEB="$APP/web"
SRC="$APP/project/web"
PROJECT="$APP/project"
PORT="${PORT:-3100}"

# Godot export → 카탈로그 pack 폴더 심링크 (정본: web/scripts/publish-godot-assets.mjs)
setup_godot_symlinks() {
  if [ ! -f "$SRC/index.wasm" ]; then
    echo "[dev] ⚠ Godot export 없음: $SRC — cd $WEB && npm run godot:build"
    return 1
  fi
  (cd "$WEB" && node scripts/publish-godot-assets.mjs --link)
  if [ ! -f "$SRC/manifest.json" ]; then
    echo "[dev] ⚠ manifest.json 없음 — cd $WEB && npm run godot:build 를 먼저 실행하세요"
  fi
}

# 소스(.gd·project.godot)가 팩보다 새면 웹 익스포트를 다시 한다.
ensure_godot_fresh() {
  local pck="$SRC/index.pck"
  if [ ! -f "$pck" ]; then
    echo "[dev] Godot 팩 없음 — 익스포트합니다"
    (cd "$WEB" && npm run godot:build)
    setup_godot_symlinks
    return
  fi
  local newer
  newer="$(find "$PROJECT" \( -name '*.gd' -o -name 'project.godot' \) -newer "$pck" | head -1)" || true
  if [ -z "$newer" ]; then
    return
  fi
  echo "[dev] Godot 소스가 팩보다 새다 ($newer) — 익스포트합니다"
  (cd "$WEB" && npm run godot:build)
  setup_godot_symlinks
}

# LISTEN 만 하고 /health 가 죽으면 브라우저가 옛 엔진을 붙잡는다. 그런 프로세스는 교체한다.
free_stale_port() {
  local pids
  pids="$(lsof -nP -iTCP:"$PORT" -sTCP:LISTEN -t 2>/dev/null || true)"
  if [ -z "$pids" ]; then
    return 0
  fi
  if curl -sf --max-time 1 "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q '"ok":true'; then
    echo "[dev] :$PORT 이미 응답 중 — 팩만 최신으로 연결했습니다. 브라우저를 새로고침하세요."
    return 0
  fi
  echo "[dev] :$PORT 가 응답하지 않습니다. 옛 리스너를 교체합니다: $pids"
  # shellcheck disable=SC2086
  kill $pids 2>/dev/null || true
  sleep 0.4
  # shellcheck disable=SC2086
  kill -9 $pids 2>/dev/null || true
}

port_healthy() {
  curl -sf --max-time 1 "http://127.0.0.1:$PORT/health" 2>/dev/null | grep -q '"ok":true'
}

ensure_deps() {
  if [ ! -d "$WEB/node_modules" ]; then
    echo "[dev] npm install (web)..."
    (cd "$WEB" && npm install)
  fi
}

setup_godot_symlinks
ensure_godot_fresh
ensure_deps

# 검증 전용 모드: 서버는 띄우지 않는다
if [ "${SKIP_SERVER:-}" = "1" ]; then
  echo "[dev] SKIP_SERVER=1 — 준비만 완료"
  exit 0
fi

free_stale_port
if port_healthy; then
  echo "[dev] http://localhost:$PORT 가 이미 켜져 있습니다 (새 팩은 심링크됨)."
  exit 0
fi

echo ""
echo "==================================="
echo "  다굴 플랫폼 개발 서버 (dagul-prod)"
echo "  http://localhost:$PORT"
echo "==================================="
cd "$WEB"
exec env PORT="$PORT" npx tsx server.ts
