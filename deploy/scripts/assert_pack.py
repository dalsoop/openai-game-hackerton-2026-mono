#!/usr/bin/env python3
"""yjh·prod 팩 manifest.sourceHash 가 project/games+core 와 같은지 본다."""
from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"
PLANT = Path(__file__).with_name("plant-apps.py")
FOLDERS = ("server-prod", "server-yjh-dev1")


def plant_mod():
    spec = importlib.util.spec_from_file_location("plant_apps", PLANT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def assert_folder(folder: str) -> None:
    src = plant_mod().project_source_hash(APPS / folder)
    godot = APPS / folder / "web" / "public" / "godot"
    manifests = sorted(godot.glob("*/manifest.json")) if godot.is_dir() else []
    if not manifests:
        raise SystemExit(f"{folder}: web/public/godot 팩이 없다. npm run godot:build")
    for man in manifests:
        got = str(json.loads(man.read_text()).get("sourceHash") or "")
        if got != src:
            raise SystemExit(
                f"{folder}: {man.relative_to(ROOT)} sourceHash={got or '없음'} "
                f"project={src}. web 에서 npm run godot:build 후 팩을 커밋한다."
            )


def main() -> int:
    folders = sys.argv[1:] or list(FOLDERS)
    for folder in folders:
        assert_folder(folder)
    print("pack sourceHash ok " + ",".join(folders))
    return 0


if __name__ == "__main__":
    sys.exit(main())
