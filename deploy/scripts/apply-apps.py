#!/usr/bin/env python3
"""CI가 슬롯을 올린다. 개발자는 apps/ 만 푸시한다. Godot 웹도 여기서 익스포트한다."""
from __future__ import annotations

import importlib.util
import os
import shutil
import ssl
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.error
import urllib.request
import json
import re
from pathlib import Path

_SCRIPTS = Path(__file__).resolve().parent
if str(_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS))
from export_web import (  # noqa: E402
    export_platform_web,
    export_web,
    godot_bin,
    platform_web_pipeline,
)
from helm_contract import (  # noqa: E402
    NAMESPACE,
    SMOKE_FOLDERS,
    create_public_address_ok,
    create_room_id,
    create_url,
    deploy_image_tags,
    health_url,
    helm_diff_cmd,
    helm_upgrade_cmd,
    hubp_health_url,
    hubp_metrics_url,
    metrics_url,
    image_drift,
    matchmake_create_ok,
    parse_deploy_env,
    planted_hub_ids,
    planted_hub_tags,
    planted_redis_slots,
    replace_unshipped_hub_tags,
    redis_url_ok,
    rooms_listed,
    rooms_stayed,
    rooms_url,
)
from hub_images import folder_from_hub_ref, missing_hub_refs  # noqa: E402
from status import hub_health_ok, hub_metrics_ok, probe  # noqa: E402

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


def run_plant(ship_folders: list[str] | None = None) -> None:
    previous = os.environ.get("HACKERTONE_SHIP_FOLDERS")
    if ship_folders is not None:
        os.environ["HACKERTONE_SHIP_FOLDERS"] = " ".join(ship_folders)
    try:
        sys.argv = [str(PLANT)]
        plant_mod().main()
    finally:
        if ship_folders is not None:
            if previous is None:
                os.environ.pop("HACKERTONE_SHIP_FOLDERS", None)
            else:
                os.environ["HACKERTONE_SHIP_FOLDERS"] = previous



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
        raise SystemExit(f"{folder}: .export-hash 기록 실패")
    print(f"pushed {folder} ({digest})")



def docker_push(ref: str, attempts: int = 3) -> bool:
    for attempt in range(1, attempts + 1):
        ran = subprocess.run(["docker", "push", ref], check=False)
        if ran.returncode == 0:
            print(f"pushed {ref}")
            return True
        print(f"harbor push 실패 ({attempt}/{attempts}) {ref}", file=sys.stderr)
    return False


def ready_node_count() -> int:
    listed = remote("kubectl get nodes --no-headers")
    if listed.returncode:
        return 0
    return len([line for line in listed.stdout.splitlines() if line.strip()])


def require_registry_or_single_node(ref: str) -> None:
    nodes = ready_node_count()
    if nodes == 1:
        print(f"warn {ref}: harbor 없음 — 단일 노드 ctr import")
        return
    raise SystemExit(f"{ref}: harbor push 실패 (nodes={nodes})")


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
    context = APPS / folder
    subprocess.run(
        ["docker", "build", "-t", ref, "-f", str(docker), str(context)],
        check=True,
    )
    if not docker_push(ref):
        require_registry_or_single_node(ref)
    save = subprocess.Popen(["docker", "save", ref], stdout=subprocess.PIPE)
    load = subprocess.run(k3s_argv("k3s ctr images import -"), stdin=save.stdout, check=False)
    save.wait()
    if save.returncode or load.returncode:
        raise SystemExit(f"{folder} 이미지 올리기 실패")
    print(f"image {ref}")


def hub_refs(mod) -> list[str]:
    planted = planted_hub_tags((CHART / "values-games.yaml").read_text())
    refs = []
    for path in sorted(APPS.glob("*/hackertone.yaml")):
        folder = path.parent.name
        if not folder.startswith(("server-", "dagul-")):
            continue
        data = mod.parse_yaml(path.read_text())
        if not (data.get("hub") or {}).get("enabled"):
            continue
        tag = planted.get(folder) or mod.hub_image_tag(path.parent)
        refs.append(f"harbor.50.internal.xz/library/{folder}:{tag}")
    return refs


def assert_hub_images(mod) -> None:
    listed = remote("k3s ctr images ls -q")
    have = listed.stdout
    missing = missing_hub_refs(hub_refs(mod), have)
    if missing:
        raise SystemExit("helm 중단. 클러스터에 허브 이미지 없음:\n" + "\n".join(missing))


def ensure_hub_images(mod) -> None:
    listed = remote("k3s ctr images ls -q").stdout
    for ref in missing_hub_refs(hub_refs(mod), listed):
        folder = folder_from_hub_ref(ref)
        print(f"build missing hub {ref}")
        build_hub(folder)


def _helm_shell(argv: list[str]) -> str:
    return " ".join(shlex_quote(part) for part in argv)


def shlex_quote(part: str) -> str:
    if re.fullmatch(r"[A-Za-z0-9_./:=+-]+", part):
        return part
    return "'" + part.replace("'", "'\\''") + "'"


def helm_host(cmd: str) -> subprocess.CompletedProcess:
    if on_pve():
        return subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return subprocess.run(
        ["ssh", "-o", "BatchMode=yes", "pve-lan", cmd],
        capture_output=True,
        text=True,
    )


def helm_has_diff() -> bool:
    listed = helm_host("helm plugin list")
    return listed.returncode == 0 and "diff" in listed.stdout


def run_helm_argv(argv: list[str], *, check: bool = True) -> subprocess.CompletedProcess:
    if on_pve():
        proc = subprocess.run(argv, check=False)
    else:
        proc = subprocess.run(
            ["ssh", "-o", "BatchMode=yes", "pve-lan", _helm_shell(argv)],
            check=False,
        )
    if check and proc.returncode:
        raise SystemExit(f"helm 실패: {proc.returncode}")
    return proc


def kubectl_json(resource: str) -> dict:
    proc = remote(
        f"KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n {NAMESPACE} get {resource} -o json"
    )
    if proc.returncode:
        raise SystemExit(proc.stderr or proc.stdout or f"kubectl get {resource} 실패")
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"kubectl json 파싱 실패: {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"kubectl json 이 object 가 아니다: {resource}")
    return data


def live_hub_image_lines(deploy_list: dict) -> str:
    lines = []
    for item in deploy_list.get("items") or []:
        name = str((item.get("metadata") or {}).get("name") or "")
        containers = (
            ((item.get("spec") or {}).get("template") or {}).get("spec") or {}
        ).get("containers") or []
        image = str((containers[0] or {}).get("image") or "") if containers else ""
        lines.append(f"{name}\t{image}")
    return "\n".join(lines)


def legacy_hub_deploy_names(deploy_list: dict) -> list[str]:
    names: list[str] = []
    for item in deploy_list.get("items") or []:
        name = str((item.get("metadata") or {}).get("name") or "")
        if name.endswith("-hub") and not name.endswith("-hub-static"):
            names.append(name)
    return names


def drop_legacy_hub_deployments() -> None:
    """같은 이름의 Deployment 가 있으면 StatefulSet 업그레이드가 막힌다."""
    names = legacy_hub_deploy_names(kubectl_json("deploy"))
    for name in names:
        print(f"drop deploy/{name}")
        remote_ok(
            f"KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n {NAMESPACE} "
            f"delete deploy {name} --ignore-not-found --wait=true"
        )


def live_hub_workloads() -> dict:
    items: list[dict] = []
    for kind in ("statefulset", "deploy"):
        data = kubectl_json(kind)
        items.extend(data.get("items") or [])
    return {"items": items}


def live_deploy_env_lines(deploy: dict) -> str:
    containers = (
        ((deploy.get("spec") or {}).get("template") or {}).get("spec") or {}
    ).get("containers") or []
    env = (containers[0] or {}).get("env") or [] if containers else []
    return "\n".join(f"{item.get('name')}={item.get('value') or ''}" for item in env)


def post_json(url: str, payload: dict) -> tuple[int, str]:
    ctx = ssl.create_default_context()
    raw = json.dumps(payload).encode()
    req = urllib.request.Request(
        url,
        data=raw,
        method="POST",
        headers={
            "User-Agent": "hackertone-helm-verify/1",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=12, context=ctx) as res:
            return res.status, res.read(4096).decode("utf-8", "replace")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read(4096).decode("utf-8", "replace") if exc.fp else str(exc.reason)
    except Exception as exc:
        return 0, str(exc)


def assert_live_matches_plant() -> None:
    games = (CHART / "values-games.yaml").read_text()
    planted = planted_hub_tags(games)
    live = deploy_image_tags(live_hub_image_lines(live_hub_workloads()))
    drift = image_drift(planted, live)
    if drift:
        raise SystemExit("live 이미지가 values-games 태그와 다르다:\n" + "\n".join(drift))
    slots = planted_redis_slots(games)
    id_by_folder = planted_hub_ids(games)
    redis_fail = []
    for folder, slot_id in sorted(id_by_folder.items()):
        db = slots.get(slot_id)
        if db is None:
            redis_fail.append(f"{folder}: redis.slots.{slot_id} 없음")
            continue
        env = parse_deploy_env(live_deploy_env_lines(kubectl_json(f"sts/{folder}-hub")))
        url = env.get("REDIS_URL", "")
        if not redis_url_ok(url, db):
            redis_fail.append(f"{folder}: REDIS_URL={url or '없음'} expected /{db}")
    if redis_fail:
        raise SystemExit("REDIS_URL 슬롯 DB 불일치:\n" + "\n".join(redis_fail))
    print(f"live tags ok ({len(planted)} hubs)")


def smoke_folders() -> list[str]:
    shipped = [folder for folder in shipped_folders() if hub_enabled(folder)]
    if shipped:
        return shipped
    return [folder for folder in SMOKE_FOLDERS if hub_enabled(folder)]


def assert_smoke_hubs() -> None:
    failed = []
    folders = smoke_folders()
    if not folders:
        print("smoke skip (ship 한 허브 없음)")
        return
    for folder in folders:
        status, body = 0, ""
        for attempt in range(4):
            status, body = probe(health_url(folder))
            if 200 <= status < 400 and hub_health_ok(folder, body):
                break
            time.sleep(3 * (attempt + 1))
        else:
            failed.append(f"{folder} health {status} {body[:120]}")
            continue
        pin_status, pin_body = 0, ""
        for attempt in range(4):
            pin_status, pin_body = probe(hubp_health_url(folder))
            if 200 <= pin_status < 400 and hub_health_ok(folder, pin_body):
                break
            time.sleep(3 * (attempt + 1))
        else:
            failed.append(f"{folder} hubp-0 {pin_status} {pin_body[:120]}")
            continue
        if folder.startswith("dagul-"):
            met_status, met_body = 0, ""
            for attempt in range(4):
                met_status, met_body = probe(metrics_url(folder))
                if hub_metrics_ok(folder, met_status, met_body):
                    break
                time.sleep(3 * (attempt + 1))
            else:
                failed.append(f"{folder} metrics {met_status} {met_body[:120]}")
                continue
            pin_met_status, pin_met_body = 0, ""
            for attempt in range(4):
                pin_met_status, pin_met_body = probe(hubp_metrics_url(folder))
                if hub_metrics_ok(folder, pin_met_status, pin_met_body):
                    break
                time.sleep(3 * (attempt + 1))
            else:
                failed.append(f"{folder} hubp-0 metrics {pin_met_status} {pin_met_body[:120]}")
                continue
        created = False
        last = ""
        seat = ""
        room_id = ""
        for attempt in range(3):
            status, body = post_json(create_url(folder), {})
            last = f"{status} {body[:160]}"
            if matchmake_create_ok(status, body) and create_public_address_ok(folder, body):
                created = True
                seat = body
                room_id = create_room_id(body)
                break
            time.sleep(2 * (attempt + 1))
        if not created:
            failed.append(f"{folder} create {last}")
            continue
        seen: list[bool] = []
        for _ in range(2):
            _st, listed = probe(rooms_url(folder))
            seen.append(rooms_listed(listed, room_id))
            time.sleep(4)
        if seen[0] and not rooms_stayed(seen):
            failed.append(f"{folder} rooms dropped {room_id} {seat[:80]}")
    if failed:
        raise SystemExit("helm 이후 스모크 실패:\n" + "\n".join(failed))
    print("smoke create ok " + ",".join(folders))


def kube(cmd: str) -> subprocess.CompletedProcess:
    return remote(f"KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n {NAMESPACE} {cmd}")


def shipped_folders() -> list[str]:
    return [name for name in os.environ.get("HACKERTONE_SHIP_FOLDERS", "").split() if name]


def hub_enabled(folder: str) -> bool:
    try:
        return bool((parse_folder(plant_mod(), folder).get("hub") or {}).get("enabled"))
    except SystemExit:
        return False


def wait_folders() -> list[str]:
    return smoke_folders()


def dump_cluster() -> None:
    print("kubectl dump")
    for cmd in (
        "get pods,sts,deploy,ing -o wide",
        "get events --sort-by=.lastTimestamp | tail -n 40",
        "describe sts/dagul-prod-hub",
        "logs --tail=80 -l hackertone-games/slot=dagul-prod --all-containers",
    ):
        print(f"$ kubectl {cmd}")
        proc = kube(cmd)
        text = (proc.stdout or "") + (proc.stderr or "")
        print(text[-8000:] if text else f"exit {proc.returncode}")


def restart_hub_workloads(folder: str) -> None:
    if not hub_enabled(folder):
        print(f"skip restart {folder} (no hub)")
        return
    if kube(f"get sts {folder}-hub").returncode:
        print(f"skip restart sts/{folder}-hub")
        return
    print(f"restart sts/{folder}-hub")
    remote_ok(
        f"KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n {NAMESPACE} "
        f"rollout restart sts/{folder}-hub"
    )
    static = kube(f"get deploy {folder}-hub-static")
    if static.returncode == 0:
        print(f"restart deploy/{folder}-hub-static")
        remote_ok(
            f"KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl -n {NAMESPACE} "
            f"rollout restart deploy/{folder}-hub-static"
        )


def wait_hub_workloads(folder: str) -> None:
    if not hub_enabled(folder):
        print(f"skip wait {folder} (no hub)")
        return
    print(f"wait sts/{folder}-hub")
    status = kube(f"rollout status sts/{folder}-hub --timeout=180s")
    if status.returncode:
        raise SystemExit(status.stderr or status.stdout or f"sts/{folder}-hub 대기 실패")
    static = kube(f"get deploy {folder}-hub-static")
    if static.returncode:
        return
    print(f"wait deploy/{folder}-hub-static")
    ready = kube(f"rollout status deploy/{folder}-hub-static --timeout=180s")
    if ready.returncode:
        raise SystemExit(ready.stderr or ready.stdout or f"deploy/{folder}-hub-static 대기 실패")


def seed_unshipped_tags_from_live() -> None:
    live = deploy_image_tags(live_hub_image_lines(live_hub_workloads()))
    path = CHART / "values-games.yaml"
    updated = replace_unshipped_hub_tags(path.read_text(), live, set(shipped_folders()))
    if updated != path.read_text():
        path.write_text(updated)
        print("seeded unshipped hub tags from live")


def helm_upgrade() -> None:
    try:
        seed_unshipped_tags_from_live()
        run_plant()
        print("helm: 태그만 plant. 이미지는 ship 이 만든 것만 쓴다")
        assert_hub_images(plant_mod())
        if on_pve():
            dest = Path(tempfile.mkdtemp(prefix="hackertone-chart-"))
            env_copy = dest / "hackertone-env.yaml"
            subprocess.run(["rsync", "-a", f"{CHART}/", f"{dest}/"], check=True)
            shutil.copy2(ENV, env_copy)
            chart, values, games, envf = (
                str(dest),
                str(dest / "values.yaml"),
                str(dest / "values-games.yaml"),
                str(env_copy),
            )
        else:
            subprocess.run(
                ["rsync", "-az", "--delete", f"{CHART}/", "pve-lan:/tmp/hackertone-chart/"],
                check=True,
            )
            subprocess.run(["rsync", "-az", str(ENV), "pve-lan:/tmp/hackertone-env.yaml"], check=True)
            chart, values, games, envf = (
                "/tmp/hackertone-chart",
                "/tmp/hackertone-chart/values.yaml",
                "/tmp/hackertone-chart/values-games.yaml",
                "/tmp/hackertone-env.yaml",
            )
        if helm_has_diff():
            print("helm diff")
            diffed = run_helm_argv(helm_diff_cmd(chart, values, games, envf), check=False)
            if diffed.returncode >= 2:
                raise SystemExit("helm diff 실패")
        else:
            print("helm diff skip (plugin 없음)")
        drop_legacy_hub_deployments()
        run_helm_argv(helm_upgrade_cmd(chart, values, games, envf))
        for folder in shipped_folders():
            restart_hub_workloads(folder)
        for folder in wait_folders():
            wait_hub_workloads(folder)
        assert_live_matches_plant()
        assert_smoke_hubs()
        purge_cloudflare()
        print("helm ok")
    except SystemExit:
        dump_cluster()
        raise


def purge_cloudflare() -> None:
    script = Path(__file__).with_name("purge-cache.py")
    argv = [sys.executable, str(script)]
    for folder in shipped_folders():
        argv.append(f"https://{folder}.external.kr/")
    ran = subprocess.run(argv, check=False)
    if ran.returncode:
        # dagul-prod 는 DNS-only 라 HTTP 가 CF 엣지를 거치지 않는다.
        # 퍼지 자격·401이 배포를 막지 않는다. 신선함은 origin no-store 가 담당한다.
        print("cloudflare 퍼지 실패 — origin no-store 로 계속", file=sys.stderr)


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print("정본은 로컬 apply-apps.py 이다. GitHub Actions 는 이미지를 만들지 않는다.", file=sys.stderr)
        print(
            "usage: apply-apps.py plant|hub <folder>|web <folder>|export <folder>|"
            "ship [folders...]|helm [--no-rebuild]",
            file=sys.stderr,
        )
        return 2
    cmd = args[0]
    if cmd == "plant":
        run_plant()
        return 0
    if cmd == "hub" and len(args) == 2:
        build_hub(args[1])
        return 0
    if cmd == "web" and len(args) == 2:
        export_web(args[1])
        push_web(args[1])
        return 0
    if cmd == "export" and len(args) == 2:
        export_web(args[1])
        return 0
    if cmd == "ship":
        failed: list[str] = []
        for folder in args[1:]:
            try:
                export_web(folder)
                build_hub(folder)
                push_web(folder)
            except SystemExit as exc:
                print(f"FAIL {folder}: {exc}", file=sys.stderr)
                failed.append(folder)
        if failed:
            raise SystemExit("ship 실패: " + ", ".join(failed))
        run_plant(args[1:])
        return 0
    if cmd == "helm":
        if "--rebuild" in args:
            raise SystemExit("helm 은 이미지를 만들지 않는다. apply-apps.py ship 을 먼저 실행한다.")
        helm_upgrade()
        return 0
    print(
        "usage: apply-apps.py plant|hub <folder>|web <folder>|export <folder>|"
        "ship [folders...]|helm [--no-rebuild]",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
