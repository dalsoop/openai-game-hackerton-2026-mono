#!/usr/bin/env python3
"""Helm 값 파일·클러스터 이미지가 같은 정본인지 본다. kubectl set image 는 정본이 아니다."""
from __future__ import annotations

import json

RELEASE = "hackertone-games"
NAMESPACE = "hackertone-games-dev1"
HELM_WAIT_TIMEOUT = "10m"
SMOKE_FOLDERS = ("server-prod", "server-yjh-dev1")


def helm_value_flags(values: str, games: str, env: str) -> list[str]:
    return ["-f", values, "-f", games, "-f", env, "--set", "env=dev1"]


def helm_upgrade_cmd(chart: str, values: str, games: str, env: str) -> list[str]:
    # --reset-values: 예전에 남은 --set / reuse-values 를 버린다.
    # --atomic 은 Redis PVC 롤백을 키우므로 쓰지 않는다.
    return [
        "helm",
        "upgrade",
        "--install",
        RELEASE,
        chart,
        "-n",
        NAMESPACE,
        "--create-namespace",
        "--reset-values",
        "--wait",
        "--timeout",
        HELM_WAIT_TIMEOUT,
        *helm_value_flags(values, games, env),
    ]


def helm_diff_cmd(chart: str, values: str, games: str, env: str) -> list[str]:
    return [
        "helm",
        "diff",
        "upgrade",
        RELEASE,
        chart,
        "-n",
        NAMESPACE,
        "--reset-values",
        "--allow-unreleased",
        *helm_value_flags(values, games, env),
    ]


def planted_hub_tags(text: str) -> dict[str, str]:
    section = text.split("\nhubs:\n", 1)[-1] if "\nhubs:" in text else ""
    tags: dict[str, str] = {}
    folder = ""
    for line in section.splitlines():
        stripped = line.strip()
        if stripped.startswith("- folder:"):
            folder = stripped.split(":", 1)[1].strip()
        elif folder and stripped.startswith("tag:"):
            tags[folder] = stripped.split(":", 1)[1].strip()
            folder = ""
    return tags


def planted_hub_ids(text: str) -> dict[str, str]:
    section = text.split("\nhubs:\n", 1)[-1] if "\nhubs:" in text else ""
    ids: dict[str, str] = {}
    folder = ""
    for line in section.splitlines():
        stripped = line.strip()
        if stripped.startswith("- folder:"):
            folder = stripped.split(":", 1)[1].strip()
        elif folder and stripped.startswith("id:"):
            ids[folder] = stripped.split(":", 1)[1].strip()
            folder = ""
    return ids


def planted_redis_slots(text: str) -> dict[str, int]:
    section = text.split("\ngames:", 1)[0]
    slots: dict[str, int] = {}
    in_slots = False
    for line in section.splitlines():
        if line.startswith("  slots:"):
            in_slots = True
            continue
        if not in_slots:
            continue
        if not line.startswith("    ") or ":" not in line:
            break
        key, _, raw = line.strip().partition(":")
        raw = raw.strip()
        if key and raw.isdigit():
            slots[key] = int(raw)
    return slots


def deploy_image_tags(kubectl_text: str) -> dict[str, str]:
    """`name\\timage` 줄. *-hub-static 은 건너뛴다."""
    out: dict[str, str] = {}
    for line in kubectl_text.splitlines():
        if "\t" not in line:
            continue
        name, image = line.split("\t", 1)
        name, image = name.strip(), image.strip()
        if not name.endswith("-hub") or name.endswith("-hub-static"):
            continue
        folder = name[: -len("-hub")]
        out[folder] = image.rsplit(":", 1)[-1]
    return out


def image_drift(planted: dict[str, str], live: dict[str, str]) -> list[str]:
    msgs = []
    for folder, tag in sorted(planted.items()):
        got = live.get(folder)
        if got != tag:
            msgs.append(f"{folder}: plant={tag} live={got or '없음'}")
    return msgs


def redis_url_ok(url: str, db: int) -> bool:
    return url.rstrip("/").endswith(f"/{db}")


def parse_deploy_env(kubectl_env: str) -> dict[str, str]:
    env: dict[str, str] = {}
    for line in kubectl_env.splitlines():
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        env[key.strip()] = val.strip()
    return env


def matchmake_create_ok(status: int, body: str) -> bool:
    if status != 200:
        return False
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        return False
    if not isinstance(data, dict):
        return False
    return bool(data.get("roomId") or data.get("room") or data.get("sessionId"))


def lobby_room_name(folder: str) -> str:
    return f"{folder}-lobby"


def health_url(folder: str) -> str:
    return f"https://{folder}.external.kr/health"


def create_url(folder: str) -> str:
    return f"https://{folder}.external.kr/matchmake/create/{lobby_room_name(folder)}"
