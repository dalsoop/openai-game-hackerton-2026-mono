#!/usr/bin/env bash
# 로컬 개발 실행 — 웹 플랫폼(허브+로비+Godot 로딩)은 apps/server-prod/web 이 정본.
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$APP_DIR"
WEB="$APP/web"
SRC="$APP/project/web"

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

ensure_deps() {
  if [ ! -d "$WEB/node_modules" ]; then
    echo "[dev] npm install (web)..."
    (cd "$WEB" && npm install)
  fi
}

setup_godot_symlinks
ensure_deps

# 검증 전용 모드: 서버는 띄우지 않는다
if [ "${SKIP_SERVER:-}" = "1" ]; then
  echo "[dev] SKIP_SERVER=1 — 준비만 완료"
  exit 0
fi

echo ""
echo "==================================="
echo "  다굴 플랫폼 개발 서버 (server-prod)"
echo "  http://localhost:3100"
echo "==================================="
cd "$WEB"
exec env PORT="${PORT:-3100}" npx tsx server.ts
