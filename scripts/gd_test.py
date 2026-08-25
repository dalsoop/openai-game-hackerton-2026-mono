#!/usr/bin/env python3
"""GD 유닛테스트 드라이버 — project/tests/run_tests.gd 를 헤드리스로 실행한다.

Godot 바이너리 탐색은 deploy/scripts/apply-apps.py 의 godot_bin() 을 재사용한다
(하이픈 파일명이라 importlib 로 로드). 출력에서 GDTEST 줄을 파싱해 exit code 를 결정.

사용: python3 scripts/gd_test.py [project_root]
  (기본: apps/server-yjh-dev1/project)
"""
import importlib.util
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / (sys.argv[1] if len(sys.argv) > 1 else "apps/server-yjh-dev1/project")
GDTEST_RE = re.compile(r"^GDTEST (PASS|FAIL) (.+)$")
SUMMARY_RE = re.compile(r"^GDTEST SUMMARY pass=(\d+) fail=(\d+)$")


def load_godot_bin():
    spec = importlib.util.spec_from_file_location(
        "apply_apps", ROOT / "deploy" / "scripts" / "apply-apps.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # if __name__ 가드 있어 임포트 안전
    return module.godot_bin()


def main() -> int:
    godot = load_godot_bin()
    print(f"godot: {godot}")
    proc = subprocess.run(
        [str(godot), "--headless", "--path", str(PROJECT), "--script", "res://tests/run_tests.gd"],
        capture_output=True,
        text=True,
        timeout=300,
    )
    passed = failed = 0
    for line in (proc.stdout + proc.stderr).splitlines():
        m = GDTEST_RE.match(line.strip())
        if m:
            print(line)
            if m.group(1) == "PASS":
                passed += 1
            else:
                failed += 1
            continue
        s = SUMMARY_RE.match(line.strip())
        if s:
            print(line)
            passed, failed = int(s.group(1)), int(s.group(2))
    if passed == 0 and failed == 0:
        print("gd_test: GDTEST 출력 없음 — 러너가 죽었다. stderr 마지막 줄:")
        tail = (proc.stderr or proc.stdout).strip().splitlines()[-5:]
        print("\n".join(tail))
        return 1
    print(f"gd_test: {passed} passed, {failed} failed")
    return 1 if failed > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
