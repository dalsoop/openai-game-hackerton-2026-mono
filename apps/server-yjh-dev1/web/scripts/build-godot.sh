#!/usr/bin/env bash
# Godot 웹 빌드 파이프라인 정본: export → 사전압축 → 버전 매니페스트.
# 세 산출물(js/wasm/pck)은 하나의 버전으로 묶인다 — 혼합 로드 불가.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$HERE/../../project"
OUT="$PROJECT/web"
GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

echo "[1/4] 스크립트 게이트 — 유닛테스트 러너로 전체 파스+검증"
# --quit 파스 체크는 sim 스크립트를 로드하지 않아 미정의 함수 결함(2026-08-25)을
# 놓쳤다. run_tests.gd 는 모든 sim 모듈을 로드·실행하므로 파스 에러도 여기서 잡힌다.
TEST_LOG=$("$GODOT" --headless --path "$PROJECT" --script res://tests/run_tests.gd 2>&1 || true)
echo "$TEST_LOG" | grep -E "GDTEST FAIL|SCRIPT ERROR|Parse Error" && {
  echo "build-godot: GD 테스트/파스 실패 — export 중단"
  exit 1
}
echo "$TEST_LOG" | grep "GDTEST SUMMARY" || {
  echo "build-godot: 테스트 러너 미기동 — export 중단"
  exit 1
}

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
