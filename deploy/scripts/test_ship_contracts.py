#!/usr/bin/env python3
"""공식 Custom HTML shell 계약 — 슬롯 실파일 + 문서 최소 템플릿."""
from __future__ import annotations

import re
import unittest
from pathlib import Path

from status import hub_health_ok
from export_html_contract import (
    REQUIRED_PLACEHOLDERS,
    assert_export_html,
    assert_shell_template,
    leftover_placeholders,
    shell_body_token,
    simulate_export,
)

ROOT = Path(__file__).resolve().parents[2]
APPS = ROOT / "apps"

# https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html
OFFICIAL_MIN_SHELL = """<!DOCTYPE html>
<html>
<head><title>My Template</title></head>
<body>
<canvas></canvas>
<script src="$GODOT_URL"></script>
<script>
var engine = new Engine($GODOT_CONFIG);
engine.startGame();
</script>
</body>
</html>
"""

DEFAULT_ENGINE_HTML = """<!DOCTYPE html>
<html><head><title>Godot</title></head>
<body>
<canvas id="canvas"></canvas>
<script src="index.js"></script>
<script>const GODOT_CONFIG = {executable:'index'}; new Engine(GODOT_CONFIG).startGame();</script>
</body></html>
"""


def slot_shell(folder: str) -> str:
    return (APPS / folder / "project" / "custom_shell.html").read_text()


def slot_preset(folder: str) -> str:
    return (APPS / folder / "project" / "export_presets.cfg").read_text()


class OfficialTemplate(unittest.TestCase):
    def test_docs_min_shell_has_required_placeholders(self) -> None:
        assert_shell_template("docs", OFFICIAL_MIN_SHELL)

    def test_docs_min_shell_passes_after_substitution(self) -> None:
        assert_export_html("docs", simulate_export(OFFICIAL_MIN_SHELL), OFFICIAL_MIN_SHELL)

    def test_unsubstituted_official_shell_fails(self) -> None:
        with self.assertRaises(SystemExit) as ctx:
            assert_export_html("docs", OFFICIAL_MIN_SHELL, OFFICIAL_MIN_SHELL)
        self.assertIn("$GODOT_URL", str(ctx.exception))


class SlotShells(unittest.TestCase):
    def test_fig_and_pjh_presets_point_at_custom_shell(self) -> None:
        for folder in ("server-fig-dev1", "server-pjh-dev1"):
            self.assertIn('html/custom_html_shell="custom_shell.html"', slot_preset(folder))

    def test_fig_shell_is_official_and_exports_without_want_game(self) -> None:
        shell = slot_shell("server-fig-dev1")
        self.assertNotIn("wantGame", shell)
        for token in REQUIRED_PLACEHOLDERS:
            self.assertIn(token, shell)
        exported = simulate_export(shell)
        self.assertEqual(leftover_placeholders(exported), [])
        assert_export_html("server-fig-dev1", exported, shell)

    def test_pjh_shell_keeps_gangup_body_after_export(self) -> None:
        shell = slot_shell("server-pjh-dev1")
        self.assertIn("wantGame", shell)
        exported = simulate_export(shell)
        assert_export_html("server-pjh-dev1", exported, shell)
        self.assertIn("wantGame", exported)

    def test_default_engine_html_rejected_when_slot_has_shell(self) -> None:
        shell = slot_shell("server-fig-dev1")
        with self.assertRaises(SystemExit) as ctx:
            assert_export_html("server-fig-dev1", DEFAULT_ENGINE_HTML, shell)
        self.assertIn("Custom Html Shell", str(ctx.exception))

    def test_no_shell_allows_engine_default(self) -> None:
        assert_export_html("server-yjh-hexclash", DEFAULT_ENGINE_HTML, None)

    def test_hexclash_preset_has_no_custom_shell(self) -> None:
        text = slot_preset("server-yjh-hexclash")
        self.assertTrue(
            re.search(r'html/custom_html_shell=""', text),
            "hexclash 는 공식 기본 HTML 을 쓴다",
        )


class HubHealth(unittest.TestCase):
    def test_plain_ok_fails_slot_contract(self) -> None:
        self.assertFalse(hub_health_ok("server-yjh-dev1", "ok"))

    def test_json_slot_matches(self) -> None:
        self.assertTrue(hub_health_ok("server-yjh-dev1", '{"ok":true,"slot":"server-yjh-dev1"}'))

    def test_wrong_slot_fails(self) -> None:
        self.assertFalse(hub_health_ok("server-prod", '{"ok":true,"slot":"server-yjh-dev1"}'))


class BodyToken(unittest.TestCase):
    def test_body_token_ignores_placeholder_lines(self) -> None:
        token = shell_body_token(OFFICIAL_MIN_SHELL)
        self.assertTrue(token)
        self.assertNotIn("$GODOT_", token)


if __name__ == "__main__":
    unittest.main()
