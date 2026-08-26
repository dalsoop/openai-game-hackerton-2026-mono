#!/usr/bin/env python3
"""이미지 빌드와 분리된 슬롯 web eslint. plan 잡에서 돌린다."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"


def main() -> int:
    folders = [name for name in sys.argv[1:] if name.startswith(("server-", "dagul-"))]
    if not folders:
        print("lint-web skip (folder 없음)")
        return 0
    for folder in folders:
        web = APPS / folder / "web"
        if not (web / "package.json").is_file():
            print(f"lint-web skip {folder} (web/package.json 없음)")
            continue
        print(f"lint-web {folder}")
        subprocess.run(["npm", "ci"], cwd=web, check=True)
        subprocess.run(["npm", "run", "lint"], cwd=web, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
