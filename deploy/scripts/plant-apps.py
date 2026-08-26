#!/usr/bin/env python3
"""apps/*/hackertone.yaml → 카탈로그. 코드는 apps/ 에만 둔다."""
from __future__ import annotations

import hashlib
import json
import os
import sys
from pathlib import Path
from typing import Optional

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))
from helm_contract import planted_hub_tags  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"
OUT_VALUES = ROOT / "deploy" / "chart" / "values-games.yaml"
BOARD_SLOTS = ROOT / "apps" / "server-board" / "project" / "web" / "slots.json"
ENV_FILE = ROOT / "deploy" / "env.yaml"
REPO = "dalsoop/openai-game-hackerton-2026-mono"
HUB_REGISTRY = "harbor.50.internal.xz/library"

# Colyseus presence 는 Redis logical DB. ioredis keyPrefix 는 pub/sub 가 4002.
# Redis 는 이름 DB 를 못 쓰므로 URL 에는 숫자만 붙는다. 표는 슬롯 이름을 하드코딩하지 않는다.
# prod 만 1. 나머지는 values-games.yaml redis.slots 를 유지하고, 새 id 는 빈 번호를 받는다.
PROD_SLOT_ID = "prod"
PROD_REDIS_DB = 1
REDIS_DB_MIN = 1
REDIS_DB_MAX = 15


# 익스포트 산출물. 태그에 넣으면 ship(익스포트 후)과 helm(클린 트리) 태그가 갈라진다.
_HUB_TAG_SKIP = frozenset({"godot", ".next", "node_modules"})


def tree_hash(root: Path, skip_parts: frozenset[str] | None = None) -> str:
    digest = hashlib.sha256()
    if not root.exists():
        return "missing"
    skip = skip_parts or frozenset()
    files = [root] if root.is_file() else sorted(p for p in root.rglob("*") if p.is_file())
    for path in files:
        if "__pycache__" in path.parts or path.suffix == ".pyc":
            continue
        if any(part in skip for part in path.parts):
            continue
        rel = path.name if root.is_file() else path.relative_to(root).as_posix()
        digest.update(rel.encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()[:12]


def load_redis_slots(text: str) -> dict[str, int]:
    data = parse_yaml(text)
    raw = ((data.get("redis") or {}).get("slots") or {})
    if not isinstance(raw, dict):
        return {}
    out: dict[str, int] = {}
    for key, val in raw.items():
        try:
            db = int(val)
        except (TypeError, ValueError):
            continue
        if REDIS_DB_MIN <= db <= REDIS_DB_MAX:
            out[str(key)] = db
    return out


def _next_free_db(used: set[int]) -> int:
    db = REDIS_DB_MIN
    while db in used:
        db += 1
    if db > REDIS_DB_MAX:
        raise SystemExit("Redis logical DB 1-15 가 소진됐다. Redis databases 를 늘린다.")
    return db


def assign_redis_slots(slot_ids: list[str], persisted: Optional[dict[str, int]] = None) -> dict[str, int]:
    """prod 는 항상 1. 이미 심은 id 는 번호를 유지한다. 새 id 만 빈 칸을 받는다."""
    kept = dict(persisted or {})
    assigned: dict[str, int] = {}
    used: set[int] = set()
    ids = list(dict.fromkeys(slot_ids))

    if PROD_SLOT_ID in ids:
        assigned[PROD_SLOT_ID] = PROD_REDIS_DB
        used.add(PROD_REDIS_DB)

    for slot_id in ids:
        if slot_id in assigned:
            continue
        prev = kept.get(slot_id)
        if prev is None or prev == PROD_REDIS_DB or prev in used:
            continue
        assigned[slot_id] = prev
        used.add(prev)

    for slot_id in ids:
        if slot_id in assigned:
            continue
        db = _next_free_db(used)
        assigned[slot_id] = db
        used.add(db)
    return assigned


def project_source_hash(folder: Path) -> str:
    digest = hashlib.sha256()
    for part in (folder / "project" / "games", folder / "project" / "core"):
        digest.update(tree_hash(part).encode())
    return digest.hexdigest()[:12]


def hub_image_tag(folder: Path) -> str:
    data = parse_yaml((folder / "hackertone.yaml").read_text()) if (folder / "hackertone.yaml").is_file() else {}
    docker_rel = str((data.get("hub") or {}).get("dockerfile") or "Dockerfile")
    docker = folder / docker_rel
    # 슬롯 루트 Dockerfile 은 기존 태그 공식을 유지한다. 하위 경로(web/)만 새 트리를 해시한
    if docker.parent.resolve() == folder.resolve():
        parts = [
            docker,
            folder / "package.json",
            folder / "package-lock.json",
            folder / "src",
            folder / "public",
        ]
    else:
        ctx = docker.parent
        parts = [
            docker,
            ctx / "package.json",
            ctx / "package-lock.json",
            ctx / "src",
            ctx / "app",
            ctx / "lib",
            ctx / "components",
            ctx / "hooks",
            ctx / "messages",
            ctx / "public",
            ctx / "scripts",
            ctx / "server.ts",
            ctx / "alias-register.ts",
            ctx / "next.config.ts",
            ctx / "tsconfig.server.json",
            folder / "project" / "games",
            folder / "project" / "core",
            folder / "project" / "addons" / "colyseus" / "bin",
        ]
    digest = hashlib.sha256()
    for part in parts:
        digest.update(tree_hash(part, _HUB_TAG_SKIP).encode())
    return digest.hexdigest()[:12]


def parse_yaml(text: str) -> dict:
    try:
        import yaml  # type: ignore

        data = yaml.safe_load(text) or {}
        if not isinstance(data, dict):
            raise ValueError("root must be a mapping")
        return data
    except ImportError:
        pass
    root: dict = {}
    stack: list[tuple[int, dict]] = [(-1, root)]
    for raw in text.splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        key, _, rest = raw.lstrip().partition(":")
        val = rest.strip()
        while stack and indent <= stack[-1][0]:
            stack.pop()
        parent = stack[-1][1]
        if val == "":
            child: dict = {}
            parent[key] = child
            stack.append((indent, child))
            continue
        if val in ("true", "false"):
            parent[key] = val == "true"
        elif val.startswith('"') and val.endswith('"'):
            parent[key] = val[1:-1]
        else:
            parent[key] = val
    return root


def ship_folders() -> set[str]:
    return {name for name in os.environ.get("HACKERTONE_SHIP_FOLDERS", "").split() if name}


def _hub_tag_for_plant(folder: Path, existing: dict[str, str]) -> str:
    name = folder.name
    if name in ship_folders() or name not in existing:
        return hub_image_tag(folder)
    return existing[name]


def main() -> None:
    games = []
    slots = []
    hubs = []
    existing_tags = planted_hub_tags(OUT_VALUES.read_text()) if OUT_VALUES.is_file() else {}
    for path in sorted(APPS.glob("*/hackertone.yaml")):
        folder = path.parent.name
        if not folder.startswith("server-"):
            continue
        data = parse_yaml(path.read_text())
        kind = data.get("kind")
        web = data.get("web") or {}
        export_dir = path.parent / str(web.get("exportDir", "project/web"))
        has_export = export_dir.is_dir() and any(export_dir.iterdir())
        hub_on = bool((data.get("hub") or {}).get("enabled"))
        host = f"{folder}.external.kr"
        slots.append(
            {
                "folder": folder,
                "id": data.get("id", folder),
                "title": data.get("title", folder),
                "blurb": data.get("blurb", ""),
                "web": bool(web.get("enabled")),
                "hub": hub_on,
                "hasExport": has_export,
                "url": f"https://{host}/",
            }
        )
        if kind == "game" and web.get("enabled"):
            gid = data["id"]
            games.append(
                {
                    "folder": folder,
                    "id": gid,
                    "title": data.get("title", gid),
                    "blurb": data.get("blurb", ""),
                    "players": data.get("players", ""),
                }
            )
        if (data.get("hub") or {}).get("enabled"):
            hubs.append(
                {
                    "folder": folder,
                    "id": data["id"],
                    "pathPrefix": (data.get("hub") or {}).get("pathPrefix", "/gang-up"),
                    "image": f"{HUB_REGISTRY}/{folder}",
                    "tag": _hub_tag_for_plant(path.parent, existing_tags),
                }
            )
    persisted = load_redis_slots(OUT_VALUES.read_text()) if OUT_VALUES.is_file() else {}
    redis_slots = assign_redis_slots([item["id"] for item in hubs], persisted)
    for item in hubs:
        item["redisDb"] = redis_slots[item["id"]]
    env = "dev1"
    if ENV_FILE.is_file():
        for line in ENV_FILE.read_text().splitlines():
            if line.startswith("env:"):
                env = line.split(":", 1)[1].strip() or env
                break
    catalog = {
        "repo": REPO,
        "env": env,
        "hubFolder": hubs[0]["folder"] if hubs else "",
        "hubFolders": [item["folder"] for item in hubs],
        "board": "https://server-board.external.kr/",
        "slots": slots,
    }
    slots_text = json.dumps(catalog, ensure_ascii=False, indent=2) + "\n"
    BOARD_SLOTS.parent.mkdir(parents=True, exist_ok=True)
    BOARD_SLOTS.write_text(slots_text)
    lines = ["# generated by deploy/scripts/plant-apps.py — do not edit", "redis:", "  slots:"]
    if redis_slots:
        ordered = []
        if PROD_SLOT_ID in redis_slots:
            ordered.append(PROD_SLOT_ID)
        ordered.extend(sorted(sid for sid in redis_slots if sid != PROD_SLOT_ID))
        for slot_id in ordered:
            lines.append(f"    {slot_id}: {redis_slots[slot_id]}")
    else:
        lines.append("    {}")
    lines.append("games:")
    if not games:
        lines.append("  []")
    for g in games:
        lines.append(f"  - folder: {g['folder']}")
        lines.append(f"    id: {g['id']}")
    lines.append("hubs:")
    if not hubs:
        lines.append("  []")
    for item in hubs:
        lines.append(f"  - folder: {item['folder']}")
        lines.append(f"    id: {item['id']}")
        lines.append(f"    pathPrefix: {item['pathPrefix']}")
        lines.append(f"    image: {item['image']}")
        # 숫자로만 된 해시 태그가 YAML 숫자로 읽혀 지수 표기로 깨지지 않게 항상 따옴표.
        lines.append(f"    tag: \"{item['tag']}\"")
    OUT_VALUES.write_text("\n".join(lines) + "\n")
    print(f"wrote {BOARD_SLOTS.relative_to(ROOT)} ({len(slots)} slots)")
    print(f"wrote {OUT_VALUES.relative_to(ROOT)}")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "source-hash":
        print(project_source_hash(APPS / sys.argv[2]))
        raise SystemExit(0)
    main()
