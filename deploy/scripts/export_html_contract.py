"""Godot 웹 익스포트 HTML 계약 — 공식 Custom HTML shell.

정본: https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html
필수 플레이스홀더 $GODOT_URL, $GODOT_CONFIG 가 셸에 있고, 익스포트 결과에는 남아 있지 않아야 한다.
생성 HTML 을 손으로 고치지 않는다. Html / Custom Html Shell 만 쓴다.
"""
from __future__ import annotations

# 공식 문서 Setup — required
REQUIRED_PLACEHOLDERS = ("$GODOT_URL", "$GODOT_CONFIG")
# 공식 optional + 스레드 프리셋이 넣는 값
OPTIONAL_PLACEHOLDERS = (
    "$GODOT_HEAD_INCLUDE",
    "$GODOT_PROJECT_NAME",
    "$GODOT_SPLASH",
    "$GODOT_SPLASH_COLOR",
    "$GODOT_SPLASH_CLASSES",
    "$GODOT_THREADS_ENABLED",
)
ALL_PLACEHOLDERS = REQUIRED_PLACEHOLDERS + OPTIONAL_PLACEHOLDERS


def leftover_placeholders(html: str) -> list[str]:
    return [token for token in ALL_PLACEHOLDERS if token in html]


def assert_shell_template(folder: str, shell: str) -> None:
    missing = [token for token in REQUIRED_PLACEHOLDERS if token not in shell]
    if missing:
        raise SystemExit(f"{folder}: custom_shell.html 에 공식 플레이스홀더 없음 {missing}")


def shell_body_token(shell: str) -> str:
    """Godot 가 치환하지 않는 한 줄 — 기본 엔진 HTML 과 슬롯 셸을 가른다."""
    for raw in shell.splitlines():
        line = raw.strip()
        if len(line) < 16 or "$GODOT_" in line:
            continue
        if line.startswith("<!--") or line.startswith("*") or line.startswith("/*"):
            continue
        return line
    return ""


def simulate_export(shell: str) -> str:
    """테스트용 — 공식 플레이스홀더를 익스포트가 채운 것처럼 치환한다."""
    repl = {
        "$GODOT_URL": "index.js",
        "$GODOT_CONFIG": "{executable:'index'}",
        "$GODOT_HEAD_INCLUDE": "",
        "$GODOT_PROJECT_NAME": "game",
        "$GODOT_SPLASH": "splash.png",
        "$GODOT_SPLASH_COLOR": "#000000",
        "$GODOT_SPLASH_CLASSES": "show-image--true",
        "$GODOT_THREADS_ENABLED": "true",
    }
    out = shell
    for token, value in repl.items():
        out = out.replace(token, value)
    return out


def assert_export_html(folder: str, exported: str, shell: str | None) -> None:
    left = leftover_placeholders(exported)
    if left:
        raise SystemExit(f"{folder}: Godot 이 HTML 셸 플레이스홀더를 치환하지 않음 {left}")
    if shell is None:
        return
    assert_shell_template(folder, shell)
    token = shell_body_token(shell)
    if token and token not in exported:
        raise SystemExit(
            f"{folder}: export HTML 이 Custom Html Shell 과 다름. not pushing default page."
        )
    if "function bootFromHub" not in shell:
        return
    if "localStorage.getItem('gangup_from_hub')" not in exported:
        return
    boot = exported[exported.find("function bootFromHub") : exported.find("function bootFromHub") + 500]
    if "localStorage.getItem('gangup_from_hub') === '1'" in boot and "launchGodot()" in boot:
        raise SystemExit(f"{folder}: export HTML still auto-launches on leftover from_hub. not pushing.")
