#!/usr/bin/env bash
# 호환 래퍼 — 팩 목록은 catalog.ts, 배치는 publish-godot-assets.mjs 가 정본.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec node "$HERE/publish-godot-assets.mjs"
