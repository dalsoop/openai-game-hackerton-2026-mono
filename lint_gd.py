#!/usr/bin/env python3
"""GDScript supplementary linter — catches what gdlint misses.

Rules:
  file-length     : file > MAX_FILE_LINES (default 700)
  nesting-depth   : if/for/while/match nesting > MAX_NESTING (default 3)
  function-length : function body > MAX_FUNC_LINES (default 40)
  magic-color     : inline Color("...") outside ui_theme.gd
"""
import re, sys, pathlib

MAX_NESTING = 3
MAX_FUNC_LINES = 40
MAX_FILE_LINES = 700

RE_FUNC = re.compile(r'^(func |static func )')
RE_BLOCK = re.compile(r'^\t*(if |elif |else:|for |while |match )')
RE_MAGIC_COLOR = re.compile(r'Color\("[0-9A-Fa-f]{6}"\)')

def indent_level(line: str) -> int:
    return len(line) - len(line.lstrip('\t'))

def lint_file(path: pathlib.Path):
    lines = path.read_text(encoding='utf-8').splitlines()
    findings = []

    if len(lines) > MAX_FILE_LINES:
        findings.append((1, f"file-length: {len(lines)} lines (max {MAX_FILE_LINES}) — split into modules"))

    func_name = ""
    func_start = 0
    func_indent = 0

    for i, line in enumerate(lines, 1):
        stripped = line.lstrip('\t')
        if not stripped or stripped.startswith('#'):
            continue

        if RE_FUNC.match(stripped):
            if func_name and (i - 1 - func_start) > MAX_FUNC_LINES:
                findings.append((func_start, f"function-length: `{func_name}` is {i - 1 - func_start} lines (max {MAX_FUNC_LINES})"))
            func_name = stripped.split('(')[0].replace('func ', '').replace('static ', '').strip()
            func_start = i
            func_indent = indent_level(line)

        if RE_BLOCK.match(stripped):
            depth = indent_level(line) - func_indent
            if depth > MAX_NESTING:
                findings.append((i, f"nesting-depth: depth {depth} in `{func_name}` (max {MAX_NESTING})"))

        if RE_MAGIC_COLOR.search(line) and 'ui_theme' not in path.name:
            findings.append((i, f"magic-color: inline Color() — use UiTheme constant"))

    if func_name and (len(lines) + 1 - func_start) > MAX_FUNC_LINES:
        findings.append((func_start, f"function-length: `{func_name}` is {len(lines) + 1 - func_start} lines (max {MAX_FUNC_LINES})"))

    return findings

def main():
    root = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path('scripts')
    files = sorted(root.rglob('*.gd'))
    total = 0
    for f in files:
        rel = f.relative_to(root.parent) if root.is_dir() else f
        for line_no, msg in lint_file(f):
            print(f"{rel}:{line_no}: {msg}")
            total += 1
    print(f"\n--- {total} finding(s) ---")
    sys.exit(1 if total > 0 else 0)

if __name__ == '__main__':
    main()
