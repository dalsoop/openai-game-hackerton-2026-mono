#!/usr/bin/env python3
"""Godot 웹 익스포트. apply-apps 는 이 모듈만 부른다."""
from __future__ import annotations

import importlib.util
import os
import shutil
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

from export_html_contract import assert_export_html

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"
PLANT = Path(__file__).with_name("plant-apps.py")
GODOT_VERSION = "4.7.1"
GODOT_CACHE = ROOT / "deploy" / ".godot-cache"
GODOT_LINUX_URL = (
    f"https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}-stable/"
    f"Godot_v{GODOT_VERSION}-stable_linux.x86_64.zip"
)
GODOT_TEMPLATES_URL = (
    f"https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}-stable/"
    f"Godot_v{GODOT_VERSION}-stable_export_templates.tpz"
)


def plant_mod():
    spec = importlib.util.spec_from_file_location("plant_apps", PLANT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def parse_folder(mod, folder: str) -> dict:
    path = APPS / folder / "hackertone.yaml"
    if not path.is_file():
        raise SystemExit(f"{folder}: hackertone.yaml 없음")
    return mod.parse_yaml(path.read_text())


def templates_dir() -> Path:
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/Godot/export_templates" / f"{GODOT_VERSION}.stable"
    return Path.home() / ".local/share/godot/export_templates" / f"{GODOT_VERSION}.stable"


def _download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"download {url}")
    with urllib.request.urlopen(url, timeout=120) as src, dest.open("wb") as out:
        shutil.copyfileobj(src, out)


def ensure_linux_godot() -> Path:
    name = f"Godot_v{GODOT_VERSION}-stable_linux.x86_64"
    binary = GODOT_CACHE / name
    if binary.is_file() and os.access(binary, os.X_OK):
        return binary
    zpath = GODOT_CACHE / f"{name}.zip"
    if not zpath.is_file():
        _download(GODOT_LINUX_URL, zpath)
    with zipfile.ZipFile(zpath) as zf:
        zf.extractall(GODOT_CACHE)
    binary.chmod(0o755)
    if not binary.is_file():
        raise SystemExit(f"godot 압축에 {name} 없음")
    return binary


def ensure_templates() -> None:
    dest = templates_dir()
    marker = dest / "web_nothreads_release.zip"
    if marker.is_file() or (dest / "web_release.zip").is_file():
        return
    tpz = GODOT_CACHE / f"Godot_v{GODOT_VERSION}-stable_export_templates.tpz"
    if not tpz.is_file():
        _download(GODOT_TEMPLATES_URL, tpz)
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(tpz) as zf:
        for info in zf.infolist():
            name = Path(info.filename)
            if name.parts and name.parts[0] == "templates":
                target = dest / Path(*name.parts[1:])
            else:
                target = dest / name
            if info.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(info) as src, target.open("wb") as out:
                shutil.copyfileobj(src, out)
    if not marker.is_file() and not (dest / "web_release.zip").is_file():
        raise SystemExit(f"웹 익스포트 템플릿 없음: {dest}")
    print(f"templates {dest}")


def godot_bin() -> str:
    env = os.environ.get("GODOT") or os.environ.get("GODOT_BIN")
    candidates: list[Path] = []
    if env:
        candidates.append(Path(env).expanduser())
    for name in ("godot", "godot4"):
        found = shutil.which(name)
        if found:
            candidates.append(Path(found))
    mac = Path("/Applications/Godot.app/Contents/MacOS/Godot")
    if mac.is_file():
        candidates.append(mac)
    linux_cache = GODOT_CACHE / f"Godot_v{GODOT_VERSION}-stable_linux.x86_64"
    if linux_cache.is_file():
        candidates.append(linux_cache)
    for cand in candidates:
        if cand.is_file() and os.access(cand, os.X_OK):
            return str(cand)
    if sys.platform.startswith("linux"):
        return str(ensure_linux_godot())
    raise SystemExit("godot 4.7.1 이 없다. GODOT 경로를 지정한다.")


def platform_web_pipeline(folder: str) -> bool:
    web = parse_folder(plant_mod(), folder).get("web") or {}
    return str(web.get("pipeline", "")) == "platform"


def export_platform_web(folder: str) -> None:
    """Next 슬롯: deploy/scripts/build-godot.sh → public/godot 복사."""
    ensure_templates()
    godot = godot_bin()
    web = APPS / folder / "web"
    script = ROOT / "deploy" / "scripts" / "build-godot.sh"
    env = os.environ.copy()
    env["GODOT_BIN"] = godot
    env["GODOT"] = godot
    print(f"export platform {folder} with {godot}")
    subprocess.run(["bash", str(script), str(APPS / folder)], env=env, check=True)
    subprocess.run(["node", str(web / "scripts" / "publish-godot-assets.mjs")], cwd=str(web), check=True)
    packs = list((web / "public" / "godot").glob("*/index.pck"))
    if not packs:
        raise SystemExit(f"{folder}: publish 후 public/godot/*/index.pck 없음")
    export_dir = APPS / folder / "project" / "web"
    html = export_dir / "index.html"
    if html.is_file():
        shell_file = APPS / folder / "project" / "custom_shell.html"
        shell = shell_file.read_text(errors="ignore") if shell_file.is_file() else None
        assert_export_html(folder, html.read_text(errors="ignore"), shell)
    print(f"platform pack {folder}: " + ", ".join(p.parent.name for p in packs))


def export_web(folder: str) -> None:
    mod = plant_mod()
    data = parse_folder(mod, folder)
    web = data.get("web") or {}
    if not web.get("enabled"):
        print(f"skip web export {folder} (disabled)")
        return
    if platform_web_pipeline(folder):
        export_platform_web(folder)
        return
    project = APPS / folder / "project"
    presets = project / "export_presets.cfg"
    if not (project / "project.godot").is_file() or not presets.is_file():
        print(f"skip web export {folder} (no godot project)")
        return
    ensure_templates()
    godot = godot_bin()
    export_dir = APPS / folder / str(web.get("exportDir", "project/web"))
    export_dir.mkdir(parents=True, exist_ok=True)
    html = export_dir / "index.html"
    rel = os.path.relpath(html, project)
    if html.is_file():
        html.unlink()
        print(f"deleted stale {html}")
    print(f"export {folder} with {godot}")
    subprocess.run([godot, "--headless", "--path", str(project), "--import", "--quit"], check=True)
    subprocess.run(
        [godot, "--headless", "--path", str(project), "--export-release", "Web", rel],
        check=True,
    )
    if not html.is_file():
        raise SystemExit(f"{folder}: 웹 익스포트가 index.html 을 만들지 않음")
    exported = html.read_text(errors="ignore")
    shell_file = project / "custom_shell.html"
    shell = shell_file.read_text(errors="ignore") if shell_file.is_file() else None
    assert_export_html(folder, exported, shell)
    game_html = export_dir / "game.html"
    if game_html.exists() or (APPS / folder / "public" / "index.html").is_file():
        game_html.write_bytes(html.read_bytes())
        print(f"copied export html -> {game_html}")
