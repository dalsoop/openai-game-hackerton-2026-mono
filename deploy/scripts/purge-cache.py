#!/usr/bin/env python3
"""Cloudflare에서 슬롯 호스트 캐시를 지운다. helm 직후 게이트다.

자격 정본: CLOUDFLARE_API_TOKEN 또는 이미 쓰는 CF_API_TOKEN.
존: CLOUDFLARE_ZONE_ID / CF_ZONE_ID, 없으면 존 이름(기본 external.kr)으로 조회.
파일 폴백: /etc/hackertone/cloudflare.env
대상: argv(올려진 슬롯) 또는 apps/*/hackertone.yaml 공개 URL.
GitHub Actions 에서는 자격이 없으면 생략하지 않고 실패한다.
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

APPS = Path(__file__).resolve().parents[2] / "apps"
RUNNER_CREDS = Path("/etc/hackertone/cloudflare.env")
DEFAULT_ZONE_NAME = "external.kr"
TOKEN_KEYS = ("CLOUDFLARE_API_TOKEN", "CF_API_TOKEN")
ZONE_ID_KEYS = ("CLOUDFLARE_ZONE_ID", "CF_ZONE_ID")
ZONE_NAME_KEYS = ("CLOUDFLARE_ZONE_NAME", "CF_ZONE_NAME")
EMAIL_KEYS = ("CLOUDFLARE_EMAIL", "CF_EMAIL", "CLOUD_FLARE_EMAIL")
GLOBAL_KEY_KEYS = ("CLOUDFLARE_API_KEY", "CLOUD_FLARE_API_KEY")


def hosts_from_apps() -> list[str]:
    out = []
    for path in sorted(APPS.glob("*/hackertone.yaml")):
        name = path.parent.name
        if name.startswith(("server-", "dagul-")):
            out.append(f"https://{name}.external.kr/")
    return out


def require_purge() -> bool:
    return os.environ.get("GITHUB_ACTIONS") == "true" or os.environ.get("HACKERTONE_REQUIRE_PURGE") == "1"


def _env_first(keys: tuple[str, ...], file_map: dict[str, str]) -> str:
    for key in keys:
        val = os.environ.get(key, "").strip() or file_map.get(key, "").strip()
        if val:
            return val
    return ""


def creds_from_file(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    try:
        text = path.read_text()
    except OSError:
        return out
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        out[key.strip()] = val.strip().strip("'").strip('"')
    return out


def file_cred_map() -> dict[str, str]:
    extra = os.environ.get("HACKERTONE_CLOUDFLARE_ENV", "").strip()
    paths = [Path(extra)] if extra else []
    paths.append(RUNNER_CREDS)
    merged: dict[str, str] = {}
    for path in paths:
        for key, val in creds_from_file(path).items():
            if key not in merged and val:
                merged[key] = val
    return merged


def auth_headers(file_map: dict[str, str]) -> dict[str, str] | None:
    token = _env_first(TOKEN_KEYS, file_map)
    if token:
        return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    email = _env_first(EMAIL_KEYS, file_map)
    key = _env_first(GLOBAL_KEY_KEYS, file_map)
    if email and key:
        return {
            "X-Auth-Email": email,
            "X-Auth-Key": key,
            "Content-Type": "application/json",
        }
    return None


def cf_json(url: str, headers: dict[str, str], data: bytes | None = None) -> dict:
    req = urllib.request.Request(url, data=data, method="GET" if data is None else "POST", headers=headers)
    with urllib.request.urlopen(req, timeout=30) as res:
        return json.loads(res.read().decode())


def resolve_zone_id(headers: dict[str, str], file_map: dict[str, str]) -> str:
    zone = _env_first(ZONE_ID_KEYS, file_map)
    if zone:
        return zone
    name = _env_first(ZONE_NAME_KEYS, file_map) or DEFAULT_ZONE_NAME
    q = urllib.parse.urlencode({"name": name, "status": "active"})
    body = cf_json(f"https://api.cloudflare.com/client/v4/zones?{q}", headers)
    rows = body.get("result") or []
    if not rows:
        raise SystemExit(f"cloudflare zone 없음: {name}")
    return str(rows[0]["id"])


def main() -> int:
    file_map = file_cred_map()
    headers = auth_headers(file_map)
    if headers is None:
        print("Cloudflare 자격 없음 (CLOUDFLARE_API_TOKEN 또는 CF_API_TOKEN). 퍼지 생략")
        if require_purge():
            print("helm 게이트: 퍼지 자격이 없으면 배포를 끝내지 않는다", file=sys.stderr)
            return 1
        return 0
    try:
        zone = resolve_zone_id(headers, file_map)
    except (urllib.error.HTTPError, SystemExit, KeyError, IndexError, TypeError) as exc:
        print(f"cloudflare zone 조회 실패: {type(exc).__name__}", file=sys.stderr)
        return 1
    prefixes = sys.argv[1:] or hosts_from_apps()
    files = []
    for host in prefixes:
        base = host.rstrip("/")
        files.extend([base + "/", base, base + "/godot/dagul/manifest.json"])
    print(f"purge hosts={len(prefixes)} zone={DEFAULT_ZONE_NAME}")
    # free 플랜은 files. prefixes 는 Business 이상.
    payloads = [{"files": files}, {"prefixes": prefixes}]
    last_err = "purge 실패"
    for payload in payloads:
        try:
            out = cf_json(
                f"https://api.cloudflare.com/client/v4/zones/{zone}/purge_cache",
                headers,
                json.dumps(payload).encode(),
            )
        except urllib.error.HTTPError as exc:
            raw = exc.read().decode()[:300]
            last_err = raw
            if exc.code in (401, 403):
                print("cloudflare 토큰에 Cache Purge 권한이 없습니다", file=sys.stderr)
                return 1
            continue
        if out.get("success"):
            print("purge ok", next(iter(payload)))
            return 0
        last_err = json.dumps({"success": False})[:200]
    print(last_err[:300], file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
