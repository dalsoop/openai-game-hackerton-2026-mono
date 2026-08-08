#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import csv, json, sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def err(message: str) -> None:
    errors.append(message)

for path in ROOT.rglob("*.json"):
    try:
        json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        err(f"JSON parse: {path.relative_to(ROOT)}: {exc}")

check_json = ROOT / "checklists" / "implementation_checklist.json"
if check_json.exists():
    items = json.loads(check_json.read_text(encoding="utf-8"))
    required = {"id","game","milestone","subsystem","priority","source_status","title","precondition","steps","expected","automation","evidence","owner","trace","status"}
    ids: set[str] = set()
    for i,item in enumerate(items):
        missing = required - set(item)
        if missing:
            err(f"checklist[{i}] missing {sorted(missing)}")
        item_id = str(item.get("id",""))
        if item_id in ids:
            err(f"duplicate checklist id: {item_id}")
        ids.add(item_id)
        if item.get("priority") not in {"P0","P1","P2"}:
            err(f"bad priority: {item_id}")

project = ROOT / "project"
must_exist = [
    project/"project.godot",
    project/"scenes/main.tscn",
    project/"scripts/game_root.gd",
    project/"scripts/sim/game_world.gd",
    project/"scripts/sim/seeded_rng.gd",
    project/"scripts/sim/event_log.gd",
    project/"scripts/render/debug_renderer.gd",
    project/"scripts/ui/hud.gd",
    project/"tests/smoke_test.gd",
]
for path in must_exist:
    if not path.exists():
        err(f"missing file: {path.relative_to(ROOT)}")

if (project/"project.godot").exists():
    text=(project/"project.godot").read_text(encoding="utf-8")
    if text.count("[application]") != 1:
        err("project.godot must contain exactly one [application] section")
    if 'run/main_scene="res://scenes/main.tscn"' not in text:
        err("main scene not configured")
    if "common/physics_ticks_per_second=60" not in text:
        err("physics tick is not fixed to 60")

for path in project.rglob("*.gd"):
    text=path.read_text(encoding="utf-8")
    if path.parts[-2] in {"sim","systems"}:
        for forbidden in ("randf(", "randi(", "randomize(", "await "):
            if forbidden in text:
                err(f"forbidden simulation token {forbidden!r}: {path.relative_to(ROOT)}")
    # Lightweight delimiter audit; Godot itself remains the authoritative parser.
    pairs={")":"(","]":"[","}":"{"}
    stack=[]
    in_string=None
    escaped=False
    for line_no,line in enumerate(text.splitlines(),1):
        stripped=line.lstrip()
        if stripped.startswith("#"):
            continue
        for ch in line:
            if in_string:
                if escaped:
                    escaped=False
                elif ch=="\\":
                    escaped=True
                elif ch==in_string:
                    in_string=None
                continue
            if ch in ('"',"'"):
                in_string=ch
            elif ch in "([{":
                stack.append((ch,line_no))
            elif ch in ")]}":
                if not stack or stack[-1][0] != pairs[ch]:
                    err(f"delimiter mismatch: {path.relative_to(ROOT)}:{line_no}")
                    stack=[]
                    break
                stack.pop()
    if stack:
        err(f"unclosed delimiter: {path.relative_to(ROOT)}:{stack[-1][1]}")

if errors:
    print("VALIDATION_FAILED")
    for e in errors:
        print(" -",e)
    sys.exit(1)
print("VALIDATION_OK")
