#!/usr/bin/env python3
"""CI가 슬롯을 병렬로 올린다. 개발자는 apps/ 만 푸시한다."""
from __future__ import annotations

import importlib.util
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"
CHART = ROOT / "deploy" / "chart"
ENV = ROOT / "deploy" / "env.yaml"
PLANT = Path(__file__).with_name("plant-apps.py")
REMOTE_DIR = "/data/hackertone/g"


def plant_mod():
    spec = importlib.util.spec_from_file_location("plant_apps", PLANT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def on_pve() -> bool:
    if os.environ.get("HACKERTONE_APPLY_HOST") == "pve":
        return True
    try:
        return Path("/etc/hostname").read_text().strip() == "pve"
    except OSError:
        return False


def k3s_argv(cmd: str) -> list[str]:
    if on_pve():
        return [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "StrictHostKeyChecking=no",
            "10.0.50.100",
            cmd,
        ]
    return [
        "ssh",
        "-o",
        "BatchMode=yes",
        "pve-lan",
        "ssh -o BatchMode=yes -o StrictHostKeyChecking=no 10.0.50.100 " + cmd,
    ]


def remote(cmd: str) -> subprocess.CompletedProcess:
    return subprocess.run(k3s_argv(cmd), check=False, capture_output=True, text=True)


def remote_ok(cmd: str) -> None:
    proc = remote(cmd)
    if proc.returncode:
        raise SystemExit(proc.stderr or proc.stdout or f"remote 실패: {cmd}")


def parse_folder(mod, folder: str) -> dict:
    path = APPS / folder / "hackertone.yaml"
    if not path.is_file():
        raise SystemExit(f"{folder}: hackertone.yaml 없음")
    return mod.parse_yaml(path.read_text())


def run_plant() -> None:
    sys.argv = [str(PLANT)]
    plant_mod().main()


def push_web(folder: str) -> None:
    mod = plant_mod()
    data = parse_folder(mod, folder)
    web = data.get("web") or {}
    export = APPS / folder / str(web.get("exportDir", "project/web"))
    if not web.get("enabled") or not export.is_dir():
        print(f"skip web {folder}")
        return
    html = export / "index.html"
    if html.is_file():
        match = re.search(r'"mainPack"\s*:\s*"([^"]+)"', html.read_text(errors="ignore"))
        if match and not (export / match.group(1)).is_file():
            raise SystemExit(f"{folder}: mainPack {match.group(1)} 이 export 폴더에 없음")
    digest = mod.tree_hash(export)
    dest = f"{REMOTE_DIR}/{folder}"
    remote_ok(f"mkdir -p {dest}")
    have = remote(f"cat {dest}/.export-hash 2>/dev/null || true")
    if have.stdout.strip() == digest:
        print(f"skip web {folder} ({digest})")
        return
    with tempfile.NamedTemporaryFile(suffix=".tar") as tmp:
        with tarfile.open(tmp.name, "w") as tar:
            tar.add(export, arcname=".")
        proc = subprocess.Popen(k3s_argv(f"tar -xf - -C {dest}"), stdin=subprocess.PIPE)
        with open(tmp.name, "rb") as fh:
            proc.communicate(fh.read())
        if proc.returncode:
            raise SystemExit(f"{folder} 올리기 실패")
    hashed = subprocess.run(
        k3s_argv(f"tee {dest}/.export-hash >/dev/null"),
        input=digest + "\n",
        text=True,
        check=False,
    )
    if hashed.returncode:
        print(f"warn {folder}: .export-hash 기록 실패")
    print(f"pushed {folder} ({digest})")


def build_hub(folder: str) -> None:
    mod = plant_mod()
    data = parse_folder(mod, folder)
    hub = data.get("hub") or {}
    if not hub.get("enabled"):
        print(f"skip hub {folder}")
        return
    docker = APPS / folder / str(hub.get("dockerfile", "Dockerfile"))
    if not docker.is_file():
        raise SystemExit(f"{folder}: Dockerfile 없음")
    image = f"harbor.50.internal.xz/library/{folder}"
    tag = mod.hub_image_tag(APPS / folder)
    ref = f"{image}:{tag}"
    listed = remote(f"k3s ctr images ls -q | grep -F {ref} || true")
    if listed.stdout.strip():
        print(f"skip hub {folder} ({ref})")
        return
    subprocess.run(["docker", "build", "-t", ref, str(APPS / folder)], check=True)
    save = subprocess.Popen(["docker", "save", ref], stdout=subprocess.PIPE)
    load = subprocess.run(k3s_argv("k3s ctr images import -"), stdin=save.stdout, check=False)
    save.wait()
    if save.returncode or load.returncode:
        raise SystemExit(f"{folder} 이미지 올리기 실패")
    print(f"image {ref}")


def hub_refs(mod) -> list[str]:
    refs = []
    for path in sorted(APPS.glob("*/hackertone.yaml")):
        folder = path.parent.name
        if not folder.startswith("server-"):
            continue
        data = mod.parse_yaml(path.read_text())
        if not (data.get("hub") or {}).get("enabled"):
            continue
        refs.append(f"harbor.50.internal.xz/library/{folder}:{mod.hub_image_tag(path.parent)}")
    return refs


def assert_hub_images(mod) -> None:
    listed = remote("k3s ctr images ls -q")
    have = listed.stdout
    missing = [ref for ref in hub_refs(mod) if ref not in have]
    if missing:
        raise SystemExit("helm 중단. 클러스터에 허브 이미지 없음:\n" + "\n".join(missing))


def helm_upgrade() -> None:
    run_plant()
    assert_hub_images(plant_mod())
    if on_pve():
        dest = Path(tempfile.mkdtemp(prefix="hackertone-chart-"))
        env_copy = dest / "hackertone-env.yaml"
        subprocess.run(["rsync", "-a", f"{CHART}/", f"{dest}/"], check=True)
        shutil.copy2(ENV, env_copy)
        helm = [
            "helm",
            "upgrade",
            "--install",
            "hackertone-games",
            str(dest),
            "-n",
            "hackertone-games-dev1",
            "--create-namespace",
            "-f",
            str(dest / "values.yaml"),
            "-f",
            str(dest / "values-games.yaml"),
            "-f",
            str(env_copy),
            "--set",
            "env=dev1",
        ]
        subprocess.run(helm, check=True)
    else:
        helm = (
            "helm upgrade --install hackertone-games /tmp/hackertone-chart "
            "-n hackertone-games-dev1 --create-namespace "
            "-f /tmp/hackertone-chart/values.yaml "
            "-f /tmp/hackertone-chart/values-games.yaml "
            "-f /tmp/hackertone-env.yaml "
            "--set env=dev1"
        )
        subprocess.run(
            ["rsync", "-az", "--delete", f"{CHART}/", "pve-lan:/tmp/hackertone-chart/"],
            check=True,
        )
        subprocess.run(["rsync", "-az", str(ENV), "pve-lan:/tmp/hackertone-env.yaml"], check=True)
        subprocess.run(["ssh", "-o", "BatchMode=yes", "pve-lan", helm], check=True)
    print("helm ok")


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print("개발자는 apps/ 를 푸시하면 됩니다. 로컬 전체 적용은 CI와 같습니다.", file=sys.stderr)
        print("usage: apply-apps.py plant|hub <folder>|web <folder>|ship [folders...]|helm", file=sys.stderr)
        return 2
    cmd = args[0]
    if cmd == "plant":
        run_plant()
        return 0
    if cmd == "hub" and len(args) == 2:
        build_hub(args[1])
        return 0
    if cmd == "web" and len(args) == 2:
        push_web(args[1])
        return 0
    if cmd == "ship":
        for folder in args[1:]:
            build_hub(folder)
            push_web(folder)
        return 0
    if cmd == "helm":
        helm_upgrade()
        return 0
    print("usage: apply-apps.py plant|hub <folder>|web <folder>|ship [folders...]|helm", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
