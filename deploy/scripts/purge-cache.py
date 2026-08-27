#!/usr/bin/env python3
"""Cloudflare에서 슬롯 호스트 캐시를 지운다. helm 직후 게이트다.

자격 정본: 환경변수, 없으면 러너 파일 `/etc/hackertone/cloudflare.env`.
대상 정본: argv(올려진 슬롯) 또는 apps/*/hackertone.yaml 공개 URL.
GitHub Actions 에서는 자격이 없으면 생략하지 않고 실패한다.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

APPS = Path(__file__).resolve().parents[2] / "apps"
RUNNER_CREDS = Path("/etc/hackertone/cloudflare.env")


def hosts_from_apps() -> list[str]:
    out = []
    for path in sorted(APPS.glob("*/hackertone.yaml")):
        name = path.parent.name
        if name.startswith(("server-", "dagul-")):
            out.append(f"https://{name}.external.kr/")
    return out


def require_purge() -> bool:
    return os.environ.get("GITHUB_ACTIONS") == "true" or os.environ.get("HACKERTONE_REQUIRE_PURGE") == "1"


def creds_from_file(path: Path) -> tuple[str, str]:
    token = ""
    zone = ""
    try:
        text = path.read_text()
    except OSError:
        return token, zone
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip("'").strip('"')
        if key == "CLOUDFLARE_API_TOKEN":
            token = val
        elif key == "CLOUDFLARE_ZONE_ID":
            zone = val
    return token, zone


def cloudflare_creds() -> tuple[str, str]:
    token = os.environ.get("CLOUDFLARE_API_TOKEN", "").strip()
    zone = os.environ.get("CLOUDFLARE_ZONE_ID", "").strip()
    if token and zone:
        return token, zone
    extra = os.environ.get("HACKERTONE_CLOUDFLARE_ENV", "").strip()
    paths = [Path(extra)] if extra else []
    paths.append(RUNNER_CREDS)
    for path in paths:
        file_token, file_zone = creds_from_file(path)
        token = token or file_token
        zone = zone or file_zone
        if token and zone:
            return token, zone
    return token, zone


def main() -> int:
    token, zone = cloudflare_creds()
    if not token or not zone:
        print("CLOUDFLARE_API_TOKEN / CLOUDFLARE_ZONE_ID 없음. 퍼지 생략")
        if require_purge():
            print("helm 게이트: 퍼지 자격이 없으면 배포를 끝내지 않는다", file=sys.stderr)
            return 1
        return 0
    prefixes = sys.argv[1:] or hosts_from_apps()
    body = json.dumps({"prefixes": prefixes}).encode()
    req = urllib.request.Request(
        f"https://api.cloudflare.com/client/v4/zones/{zone}/purge_cache",
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            print(res.read().decode()[:400])
    except urllib.error.HTTPError as exc:
        print(exc.read().decode()[:400], file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
