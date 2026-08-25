#!/usr/bin/env python3
"""GDScript supplementary linter — catches what gdlint misses.

Rules:
  file-length       : file > MAX_FILE_LINES (default 700)
  nesting-depth     : if/for/while/match nesting > MAX_NESTING (default 2)
  function-length   : function body > MAX_FUNC_LINES (default 40)
  magic-color       : inline Color("...") outside ui_theme.gd
  banned-file       : 폐기된 오프라인 UI/사장 사본 부활 금지 (온라인 단일 구성)
  lobby-verb        : GD에서 로비 동사 송신 금지 — 로비는 web/(React+허브) 소유
  ws-client-dup     : GD 자체 WebSocket 금지 — 네트워크는 페이지 브릿지 경유
  core-games        : core/ 가 games/ 를 참조 금지 — 셸은 게임을 모른다
  dead-autoload-api : autoload 공개 멤버(전 프로젝트 사용 0회) — # lint-gd: public-api 로 예외

Baseline (래칫):
  --baseline PATH          규칙별 위반 수가 baseline 초과면 exit 1 (이하면 통과)
  --update-baseline PATH   현재 위반 수로 baseline 파일을 갱신
"""
import argparse
import json
import pathlib
import re
import sys

MAX_NESTING = 2
MAX_FUNC_LINES = 40
MAX_FILE_LINES = 700

RE_FUNC = re.compile(r'^(func |static func )')
RE_BLOCK = re.compile(r'^\t*(if |elif |else:|for |while |match )')
RE_MAGIC_COLOR = re.compile(r'Color\("[0-9A-Fa-f]{6}"\)')
RE_PUBLIC_MEMBER = re.compile(r'^(?:func |signal |const |var )([A-Za-z_]\w*)')
RE_AUTOLOAD_SECTION = re.compile(r'^\[autoload\]$')

# --- SSOT rules (온라인 단일 구성 · 정본 수정 강제) ---
BANNED_FILES = {
    'core/net/hub_client.gd': '사장 WS 클라이언트 — 네트워크는 브릿지(network_manager) 경유',
    'scripts/net/hub_client.gd': '사장 WS 클라이언트 — 네트워크는 브릿지(network_manager) 경유',
    'scripts/ui/flow_screens.gd': '오프라인 로비 UI — React(web/)가 대체',
    'scripts/ui/lobby_builder.gd': '오프라인 로비 UI — React(web/)가 대체',
    'scripts/ui/room_builder.gd': '오프라인 대기실 UI — React(web/)가 대체',
}
RE_LOBBY_VERB = re.compile(r'"t"\s*:\s*"(create|join|rooms|kick|mode|chat)"')
RE_WS_NEW = re.compile(r'WebSocketPeer\.new\(\)')
RE_GAMES_REF = re.compile(r'res://games/')


def indent_level(line: str) -> int:
    return len(line) - len(line.lstrip('\t'))


def lint_file(path: pathlib.Path):
    """한 파일의 위반 [(line_no, rule, message)] — rule은 ':' 앞 키."""
    lines = path.read_text(encoding='utf-8').splitlines()
    findings = []

    if len(lines) > MAX_FILE_LINES:
        findings.append((1, 'file-length', f"{len(lines)} lines (max {MAX_FILE_LINES}) — split into modules"))

    func_name = ""
    func_start = 0
    func_indent = 0

    def check_func_end(end_line):
        if func_name and (end_line - func_start) > MAX_FUNC_LINES:
            findings.append((func_start, 'function-length',
                             f"`{func_name}` is {end_line - func_start} lines (max {MAX_FUNC_LINES})"))

    for i, line in enumerate(lines, 1):
        stripped = line.lstrip('\t')
        if not stripped or stripped.startswith('#'):
            continue

        if RE_FUNC.match(stripped):
            check_func_end(i - 1)
            func_name = stripped.split('(')[0].replace('func ', '').replace('static ', '').strip()
            func_start = i
            func_indent = indent_level(line)

        if RE_BLOCK.match(stripped):
            depth = indent_level(line) - func_indent
            if depth > MAX_NESTING:
                findings.append((i, 'nesting-depth', f"depth {depth} in `{func_name}` (max {MAX_NESTING})"))

        if RE_MAGIC_COLOR.search(line) and 'ui_theme' not in path.name:
            findings.append((i, 'magic-color', 'inline Color() — use UiTheme constant'))

        m = RE_LOBBY_VERB.search(line)
        if m:
            findings.append((i, 'lobby-verb', f'"{m.group(1)}" 송신은 web/lib/hub(React) 소유 — GD에서 금지'))

        if RE_WS_NEW.search(line):
            findings.append((i, 'ws-client-dup', 'GD 자체 WebSocket 금지 — 네트워크는 페이지 브릿지(network_manager) 경유'))

        if 'core' in path.parts and RE_GAMES_REF.search(line) and path.name not in ('game_registry.gd', 'boot.gd'):
            findings.append((i, 'core-games', 'core/ 는 games/ 를 참조할 수 없다 — 계약(GameModule)으로 우회'))

    check_func_end(len(lines) + 1)
    return findings


def collect_autoloads(project_root: pathlib.Path):
    """project.godot [autoload] → {이름: autoload 스크립트 경로}."""
    autoloads = {}
    cfg = project_root / 'project.godot'
    if not cfg.is_file():
        return autoloads
    in_section = False
    for line in cfg.read_text(encoding='utf-8').splitlines():
        if line.startswith('['):
            in_section = RE_AUTOLOAD_SECTION.match(line) is not None
            continue
        if in_section and '=' in line:
            name, value = line.split('=', 1)
            res = value.strip().strip('"').lstrip('*')
            if res.endswith('.gd'):
                autoloads[name.strip()] = project_root / res.replace('res://', '')
    return autoloads


def lint_dead_autoload_api(project_root: pathlib.Path, files):
    """2패스: autoload 공개 멤버 수집 → 전 프로젝트 `Name.member` 사용 0회 보고."""
    findings = []
    all_text = {f: f.read_text(encoding='utf-8') for f in files}
    for name, script_path in collect_autoloads(project_root).items():
        if not script_path.is_file():
            continue
        for i, line in enumerate(script_path.read_text(encoding='utf-8').splitlines(), 1):
            stripped = line.split('#')[0].rstrip()
            # 클래스 레벨(들여쓰기 0) 선언만 — 함수 지역변수는 제외
            m = RE_PUBLIC_MEMBER.match(stripped) if indent_level(line) == 0 else None
            if not m:
                continue
            member = m.group(1)
            if member.startswith('_'):
                continue
            if '# lint-gd: public-api' in line:
                continue
            usage = re.compile(rf'\b{re.escape(name)}\.{re.escape(member)}\b')
            if not any(usage.search(text) for text in all_text.values()):
                findings.append((script_path, i, 'dead-autoload-api',
                                 f'{name}.{member} — 전 프로젝트 사용 0회 (웹 노출 API면 `# lint-gd: public-api`)'))
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', nargs='?', default='.', help='Godot 프로젝트 루트 (구 scripts/ 경로도 허용)')
    parser.add_argument('--baseline', help='규칙별 위반 수 baseline JSON — 초과 시 실패')
    parser.add_argument('--update-baseline', help='현재 위반 수로 baseline 갱신')
    args = parser.parse_args()

    root = pathlib.Path(args.root)
    project_root = root.parent if root.name == 'scripts' else root
    files = []
    for sub in ('core', 'games', 'scripts', 'autoload'):
        d = project_root / sub
        if d.is_dir():
            files += list(d.rglob('*.gd'))
    files = sorted(set(files))

    findings = []  # (rel_path, line_no, rule, message)
    for rel, why in BANNED_FILES.items():
        if (project_root / rel).exists():
            findings.append((rel, 1, 'banned-file', f'폐기된 파일 부활 금지 — {why}'))
    for f in files:
        rel = f.relative_to(project_root)
        for line_no, rule, msg in lint_file(f):
            findings.append((str(rel), line_no, rule, msg))
    findings += [(str(p.relative_to(project_root)), i, rule, msg)
                 for p, i, rule, msg in lint_dead_autoload_api(project_root, files)]

    counts = {}
    for _, _, rule, _ in findings:
        counts[rule] = counts.get(rule, 0) + 1
    total = len(findings)

    for rel, line_no, rule, msg in sorted(findings):
        print(f"{rel}:{line_no}: {rule}: {msg}")
    print(f"\n--- {total} finding(s) ---")

    if args.update_baseline:
        pathlib.Path(args.update_baseline).write_text(json.dumps(counts, indent=2, sort_keys=True) + '\n')
        print(f"baseline updated: {args.update_baseline} {json.dumps(counts, sort_keys=True)}")
        sys.exit(0)

    if args.baseline:
        baseline = json.loads(pathlib.Path(args.baseline).read_text(encoding='utf-8'))
        over = {r: (counts.get(r, 0), baseline.get(r, 0)) for r in set(counts) | set(baseline)
                if counts.get(r, 0) > baseline.get(r, 0)}
        if over:
            for rule, (now, base) in sorted(over.items()):
                print(f"ratchet FAIL: {rule} {now}건 > baseline {base}건")
            sys.exit(1)
        print(f"ratchet OK: 전 규칙 baseline 이하 — {json.dumps(counts, sort_keys=True)}")
        sys.exit(0)  # 래칫 모드는 baseline 이하면 통과 (잔여 부채는 baseline 이 관리)

    sys.exit(1 if total > 0 else 0)


if __name__ == '__main__':
    main()
