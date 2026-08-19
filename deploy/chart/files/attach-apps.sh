#!/bin/sh
# GitHub apps/*/hackertone.yaml 의 웹보내기를 /srv/g/<폴더> 에 덮어쓴다. 없는 폴더는 지우지 않는다.
set -eu
REPO="${GIT_REPO:-https://github.com/dalsoop/openai-game-hackerton-2026-mono}"
REV="${GIT_REVISION:-main}"
DEST="${GAMES_DIR:-/srv/g}"
SLEEP="${GIT_SYNC_SECONDS:-60}"

stage_repo() {
  src="$1"
  mkdir -p "$DEST"
  for yml in "$src"/apps/*/hackertone.yaml; do
    [ -f "$yml" ] || continue
    folder=$(basename "$(dirname "$yml")")
    case "$folder" in
      server-*) ;;
      *) continue ;;
    esac
    enabled=$(awk '
      $1=="web:" { w=1; next }
      w && $1=="enabled:" { print $2; exit }
    ' "$yml")
    [ "$enabled" = "true" ] || continue
    export_dir=$(awk '
      $1=="web:" { w=1; next }
      w && $1=="exportDir:" { print $2; exit }
    ' "$yml")
    export_dir=${export_dir:-project/web}
    from="$src/apps/$folder/$export_dir"
    [ -d "$from" ] || continue
    mkdir -p "$DEST/$folder"
    cp -a "$from"/. "$DEST/$folder"/
    echo "attached $folder"
  done
}

pull_once() {
  if ! command -v wget >/dev/null 2>&1; then
    echo "attach-apps: wget 없음. /srv/g hostPath 시드만 사용"
    return 0
  fi
  tmp=$(mktemp -d)
  url="${REPO%/}/archive/refs/heads/${REV}.tar.gz"
  if ! wget -qO- "$url" | tar -xz -C "$tmp" --strip-components=1; then
    echo "attach-apps: $url 를 받지 못했습니다" >&2
    rm -rf "$tmp"
    return 1
  fi
  stage_repo "$tmp"
  rm -rf "$tmp"
}

pull_once || true
if [ "${GIT_SYNC_ONCE:-}" = "1" ]; then
  exit 0
fi
while true; do
  sleep "$SLEEP"
  pull_once || true
done
