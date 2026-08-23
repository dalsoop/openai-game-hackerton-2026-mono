#!/usr/bin/env python3
"""바뀐 apps/server-* 와 helm 필요 여부를 CI JSON 으로 낸다."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"
HUB_MARKERS = {
    "src",
    "Dockerfile",
    "package.json",
    "package-lock.json",
    "public",
}


def folders() -> list[str]:
    return sorted(
        p.parent.name
        for p in APPS.glob("*/hackertone.yaml")
        if p.parent.name.startswith("server-")
    )


def diff_names(before: str, after: str) -> list[str]:
    proc = subprocess.run(
        ["git", "diff", "--name-only", before, after, "--", "apps/", "deploy/"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    return [line for line in proc.stdout.splitlines() if line]


def analyze(before: str, after: str, all_mode: bool) -> tuple[list[str], bool]:
    known = folders()
    if all_mode or not before or before == "0" * 40:
        return known, True
    picked: set[str] = set()
    helm = False
    for line in diff_names(before, after):
        parts = Path(line).parts
        if not parts:
            continue
        if parts[0] == "apps" and len(parts) >= 2 and parts[1].startswith("server-"):
            picked.add(parts[1])
            rest = parts[2:]
            if rest and (rest[0] in HUB_MARKERS or rest[0] == "hackertone.yaml"):
                helm = True
            continue
        if parts[0] == "deploy":
            helm = True
            name = Path(line).name
            if name in {"plant-apps.py", "slots.json"}:
                picked.add("server-board")
    return [name for name in known if name in picked], helm


def main() -> int:
    all_mode = "--all" in sys.argv
    args = [a for a in sys.argv[1:] if a not in {"--all", "--changed"}]
    before, after = "", "HEAD"
    if len(args) >= 2:
        before, after = args[0], args[1]
    picked, helm = analyze(before, after, all_mode)
    print(json.dumps({"folder": picked, "helm": helm}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
