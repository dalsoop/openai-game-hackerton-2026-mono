#!/usr/bin/env bash
# CI/배포용: Godot export 산출물을 web/public/godot/dagul 에 실파일로 채운다.
# 로컬 개발은 심링크(dev.sh)로 충분하지만, Docker 빌드 컨텍스트(web/)는
# 레포 밖을 참조할 수 없으므로 docker build 전에 이 스크립트를 실행한다.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WEB="$HERE/.."
SRC="$WEB/../project/web"
DEST="$WEB/public/godot/dagul"

if [ ! -f "$SRC/index.wasm" ]; then
  echo "prepare-godot-assets: Godot export가 없습니다: $SRC" >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"
# -L: 심링크 역참조 — 실파일로 복사
cp -L "$SRC"/index.js "$SRC"/index.wasm "$SRC"/index.pck "$SRC"/manifest.json "$DEST"/
cp -L "$SRC"/index.audio.worklet.js "$SRC"/index.audio.position.worklet.js "$DEST"/ 2>/dev/null || true
# 사전 압축본 (server.ts 가 Content-Encoding 협상에 사용)
cp -L "$SRC"/*.br "$SRC"/*.gz "$DEST"/ 2>/dev/null || true

echo "prepare-godot-assets: $(ls "$DEST" | wc -l | tr -d ' ')개 파일 → $DEST"
