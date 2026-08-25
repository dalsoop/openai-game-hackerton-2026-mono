#!/usr/bin/env sh
set -eu
if command -v godot >/dev/null 2>&1; then EXE=godot
elif command -v godot4 >/dev/null 2>&1; then EXE=godot4
else echo "Godot 4.7.1 executable was not found in PATH." >&2; exit 1
fi
exec "$EXE" --path "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/ingame/gang-up"
