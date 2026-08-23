#!/usr/bin/env python3
"""Cloudflare에서 슬롯 호스트 캐시를 지운다. CI 시크릿만 사용한다."""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

APPS = Path(__file__).resolve().parents[2] / "apps"


def hosts_from_apps() -> list[str]:
    out = []
    for path in sorted(APPS.glob("*/hackertone.yaml")):
        if path.parent.name.startswith("server-"):
            out.append(f"https://{path.parent.name}.external.kr/")
    return out


def main() -> int:
    token = os.environ.get("CLOUDFLARE_API_TOKEN", "").strip()
    zone = os.environ.get("CLOUDFLARE_ZONE_ID", "").strip()
    if not token or not zone:
        print("CLOUDFLARE_API_TOKEN / CLOUDFLARE_ZONE_ID 없음. 퍼지 생략")
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
