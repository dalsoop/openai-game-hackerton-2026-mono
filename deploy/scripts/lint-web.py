#!/usr/bin/env python3
"""이미지 빌드와 분리된 슬롯 web tsc+eslint+vitest. apply 가 이 잡을 기다린다.

vitest 는 노드만으로 도는 단위테스트라 여기서 돌린다. GDScript 쪽(tests/run_tests.gd)은
러너에 Godot 바이너리가 없어 이 잡에서는 아직 안 돈다 — 로컬 pre-commit 훅(.githooks/pre-commit)
과 npm run verify 가 그 부분을 대신 커버한다.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"


def folders_from_argv(argv: list[str]) -> list[str]:
    return [name for name in argv if name.startswith(("server-", "dagul-"))]


def typecheck_cmds(web: Path) -> list[list[str]]:
    cmds = [
        ["npm", "ci"],
        ["npx", "tsc", "--noEmit"],
    ]
    if (web / "tsconfig.server.json").is_file():
        cmds.append(["npx", "tsc", "--project", "tsconfig.server.json", "--noEmit"])
    cmds.append(["npm", "run", "lint"])
    if (web / "vitest.config.ts").is_file():
        cmds.append(["npx", "vitest", "run"])
    return cmds


def main() -> int:
    folders = folders_from_argv(sys.argv[1:])
    if not folders:
        print("lint-web skip (folder 없음)")
        return 0
    for folder in folders:
        web = APPS / folder / "web"
        if not (web / "package.json").is_file():
            print(f"lint-web skip {folder} (web/package.json 없음)")
            continue
        print(f"lint-web {folder}")
        for cmd in typecheck_cmds(web):
            subprocess.run(cmd, cwd=web, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
