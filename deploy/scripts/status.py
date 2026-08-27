#!/usr/bin/env python3
"""apps/ 폴더 → 서브도메인이 살아 있는지 본다."""
from __future__ import annotations

import json
import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"
ENV_FILE = ROOT / "deploy" / "env.yaml"


def env_name() -> str:
    for line in ENV_FILE.read_text().splitlines():
        if line.startswith("env:"):
            return line.split(":", 1)[1].strip()
    return "dev1"


def folders() -> list[tuple[str, str]]:
    out = []
    for path in sorted(APPS.glob("*/hackertone.yaml")):
        if not path.parent.name.startswith(("server-", "dagul-")):
            continue
        text = path.read_text().replace("\r\n", "\n")
        web_on = "web:\n  enabled: true" in text
        if "hub:\n  enabled: true" in text:
            out.append((path.parent.name, "hub"))
        if web_on:
            out.append((path.parent.name, "game"))
    return out


def hub_health_ok(folder: str, body: str) -> bool:
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        return False
    if not isinstance(data, dict):
        return False
    if str(data.get("slot") or "") != folder:
        return False
    if folder.startswith("dagul-"):
        return "ccu" in data and "cap" in data and "admit" in data
    return True


def hub_metrics_ok(folder: str, status: int, body: str) -> bool:
    """구버전 Next 가 /metrics 를 locale 페이지로 주면 HTML 404 가 나온다. 그걸 통과시키지 않는다."""
    if not (200 <= status < 400):
        return False
    lower = body.lower()
    if "<html" in lower or "__next" in lower:
        return False
    if "dagul_ccu" not in body:
        return False
    return f'slot="{folder}"' in body or f"slot={folder}" in body


def probe(url: str) -> tuple[int, str]:
    ctx = ssl.create_default_context()
    req = urllib.request.Request(
        url,
        method="GET",
        headers={"User-Agent": "hackertone-status/1"},
    )
    try:
        with urllib.request.urlopen(req, timeout=8, context=ctx) as res:
            body = res.read(2048).decode("utf-8", "replace").replace("\n", " ")
            return res.status, body
    except urllib.error.HTTPError as exc:
        return exc.code, str(exc.reason)
    except Exception as exc:
        return 0, str(exc)


def main() -> int:
    env = env_name()
    rows = folders()
    if not rows:
        print("apps/ 에 배포할 앱이 없습니다")
        return 1
    failed = 0
    print(f"env={env}")
    for folder, kind in rows:
        host = f"{folder}.external.kr"
        url = f"https://{host}/health" if kind == "hub" else f"https://{host}/"
        status, detail = 0, ""
        ok = False
        for attempt in range(4):
            status, detail = probe(url)
            ok = 200 <= status < 400
            if ok:
                break
            if status not in (0, 502, 503, 504):
                break
            time.sleep(3 * (attempt + 1))
        if kind == "hub" and ok and not hub_health_ok(folder, detail):
            ok = False
            detail = f"공유 허브 또는 slot 불일치 {detail}"
        mark = "OK" if ok else "FAIL"
        if not ok:
            failed += 1
        print(f"{mark:4}  {url}  {status}  {detail[:80]}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
