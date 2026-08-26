#!/usr/bin/env bash
# Godot 웹 빌드 정본: 테스트 → export → 압축 → 매니페스트.
# 호출: npm run godot:build (cwd=슬롯/web) 또는 bash build-godot.sh <슬롯절대경로>
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

if [ "${1:-}" != "" ]; then
  SLOT_ROOT="$(cd "$1" && pwd)"
elif [ -f "$(pwd)/../project/project.godot" ]; then
  SLOT_ROOT="$(cd "$(pwd)/.." && pwd)"
else
  echo "build-godot: 슬롯 경로가 없습니다. web/ 에서 실행하거나 슬롯 절대경로를 넘깁니다."
  exit 1
fi

SLOT="$(basename "$SLOT_ROOT")"
PROJECT="$SLOT_ROOT/project"
OUT="$PROJECT/web"
WEB="$SLOT_ROOT/web"
GODOT="${GODOT_BIN:-${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}}"

if [ ! -f "$PROJECT/project.godot" ]; then
  echo "build-godot: project.godot 없음: $PROJECT"
  exit 1
fi
if [ ! -x "$GODOT" ] && ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "build-godot: Godot 바이너리 없음: $GODOT"
  exit 1
fi

echo "[1/4] 스크립트 게이트 — $SLOT"
# class_name(WebContract 등)은 .godot 캐시가 있어야 --script 파스가 산다.
"$GODOT" --headless --path "$PROJECT" --import --quit
TEST_LOG=$("$GODOT" --headless --path "$PROJECT" --script res://tests/run_tests.gd 2>&1 || true)
if echo "$TEST_LOG" | grep -E "GDTEST FAIL|SCRIPT ERROR|Parse Error"; then
  echo "$TEST_LOG" | grep -E "GDTEST FAIL|SCRIPT ERROR|Parse Error" || true
  echo "build-godot: GD 테스트/파스 실패 — export 중단"
  exit 1
fi
if ! echo "$TEST_LOG" | grep -q "GDTEST SUMMARY"; then
  echo "$TEST_LOG"
  echo "build-godot: 테스트 러너 미기동 — export 중단"
  exit 1
fi

echo "[2/4] Godot export"
mkdir -p "$OUT"
if ! "$GODOT" --headless --path "$PROJECT" --export-release "Web" "$OUT/index.html"; then
  echo "build-godot: export-release 실패"
  exit 1
fi
if [ ! -f "$OUT/index.pck" ] || [ ! -f "$OUT/index.wasm" ] || [ ! -f "$OUT/index.js" ]; then
  echo "build-godot: 산출물 없음 ($OUT). js/wasm/pck 가 한 세트여야 합니다."
  ls -la "$OUT" || true
  exit 1
fi

echo "[3/4] brotli/gzip 사전압축"
for f in index.wasm index.pck index.js index.side.wasm; do
  if [ ! -f "$OUT/$f" ]; then
    continue
  fi
  if command -v brotli >/dev/null 2>&1; then
    brotli -f -q 9 -o "$OUT/$f.br" "$OUT/$f"
  else
    echo "build-godot: brotli 없음 — $f.br 생략"
  fi
  gzip -kf -9 "$OUT/$f"
done

echo "[4/4] 버전 매니페스트"
SOURCE_HASH="$(python3 "$ROOT/deploy/scripts/plant-apps.py" source-hash "$SLOT")"
node "$WEB/scripts/gen-godot-manifest.mjs" "$OUT" "$SOURCE_HASH"
cat "$OUT/manifest.json"
