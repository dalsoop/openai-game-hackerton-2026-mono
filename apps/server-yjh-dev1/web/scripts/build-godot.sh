#!/usr/bin/env bash
# Godot 웹 빌드 파이프라인 정본: export → 사전압축 → 버전 매니페스트.
# 세 산출물(js/wasm/pck)은 하나의 버전으로 묶인다 — 혼합 로드 불가.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$HERE/../../project"
OUT="$PROJECT/web"
GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

echo "[1/4] 스크립트 파스 게이트 (--import 는 파스 에러를 못 잡는다)"
PARSE_LOG=$("$GODOT" --headless --path "$PROJECT" --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error" || true)
if [ -n "$PARSE_LOG" ]; then
  echo "$PARSE_LOG"
  echo "build-godot: GDScript 파스 에러 — export 중단"
  exit 1
fi

echo "[2/4] Godot export"
(cd "$PROJECT" && "$GODOT" --headless --export-release "Web" > /dev/null 2>&1)

echo "[3/4] brotli/gzip 사전압축"
(cd "$OUT" && for f in index.wasm index.pck index.js index.side.wasm; do
  brotli -f -q 9 -o "$f.br" "$f"
  gzip -kf -9 "$f"
done)

echo "[4/4] 버전 매니페스트"
node "$HERE/gen-godot-manifest.mjs" "$OUT"

cat "$OUT/manifest.json"
