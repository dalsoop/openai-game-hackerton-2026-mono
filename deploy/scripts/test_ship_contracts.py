#!/usr/bin/env python3
"""공식 Custom HTML shell 계약 — 슬롯 실파일 + 문서 최소 템플릿."""
from __future__ import annotations

import re
import unittest
from pathlib import Path

from helm_contract import (
    create_public_address_ok,
    create_room_id,
    helm_upgrade_cmd,
    hubp_health_url,
    image_drift,
    matchmake_create_ok,
    planted_hub_ids,
    planted_hub_tags,
    planted_redis_slots,
    redis_url_ok,
    rooms_listed,
    rooms_stayed,
    rooms_url,
)
from hub_images import folder_from_hub_ref, missing_hub_refs
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

    def test_yjh_and_prod_shells_have_official_placeholders(self) -> None:
        for folder in ("server-yjh-dev1", "server-prod"):
            shell = slot_shell(folder)
            for token in REQUIRED_PLACEHOLDERS:
                self.assertIn(token, shell)
            exported = simulate_export(shell)
            self.assertEqual(leftover_placeholders(exported), [])
            assert_export_html(folder, exported, shell)

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


def plant_mod():
    import importlib.util

    path = Path(__file__).with_name("plant-apps.py")
    spec = importlib.util.spec_from_file_location("plant_apps", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class SlotRedis(unittest.TestCase):
    def test_prod_is_always_one(self) -> None:
        plant = plant_mod()
        got = plant.assign_redis_slots(["yjh-dev1", "prod", "fig-dev1"], {})
        self.assertEqual(got["prod"], 1)
        self.assertEqual(len(got), len(set(got.values())))

    def test_keeps_persisted_numbers(self) -> None:
        plant = plant_mod()
        got = plant.assign_redis_slots(
            ["prod", "yjh-dev1", "fig-dev1"],
            {"prod": 9, "yjh-dev1": 4, "fig-dev1": 2},
        )
        self.assertEqual(got["prod"], 1)
        self.assertEqual(got["yjh-dev1"], 4)
        self.assertEqual(got["fig-dev1"], 2)

    def test_new_id_takes_next_free(self) -> None:
        plant = plant_mod()
        got = plant.assign_redis_slots(["prod", "new-slot"], {"prod": 1})
        self.assertEqual(got["prod"], 1)
        self.assertEqual(got["new-slot"], 2)

    def test_vacates_one_when_it_was_not_prod(self) -> None:
        plant = plant_mod()
        got = plant.assign_redis_slots(["prod", "fig-dev1"], {"fig-dev1": 1})
        self.assertEqual(got["prod"], 1)
        self.assertEqual(got["fig-dev1"], 2)

    def test_project_source_hash_is_twelve_hex(self) -> None:
        plant = plant_mod()
        digest = plant.project_source_hash(plant.APPS / "server-yjh-dev1")
        self.assertEqual(len(digest), 12)
        self.assertTrue(all(ch in "0123456789abcdef" for ch in digest))

    def test_load_redis_slots_reads_id_map(self) -> None:
        plant = plant_mod()
        text = "redis:\n  slots:\n    prod: 1\n    yjh-dev1: 4\n"
        self.assertEqual(plant.load_redis_slots(text), {"prod": 1, "yjh-dev1": 4})


class CiPlan(unittest.TestCase):
    def test_godot_script_change_requires_helm(self) -> None:
        import importlib.util

        path = Path(__file__).with_name("ci-plan.py")
        spec = importlib.util.spec_from_file_location("ci_plan", path)
        plan = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(plan)
        picked, helm = plan.analyze(
            "aaa",
            "bbb",
            False,
            ["apps/server-yjh-dev1/project/games/dagul/game.gd"],
        )
        self.assertEqual(picked, ["server-yjh-dev1"])
        self.assertTrue(helm)

    def test_workflow_change_requires_helm(self) -> None:
        import importlib.util

        path = Path(__file__).with_name("ci-plan.py")
        spec = importlib.util.spec_from_file_location("ci_plan", path)
        plan = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(plan)
        picked, helm = plan.analyze(
            "aaa",
            "bbb",
            False,
            [".github/workflows/apps.yml"],
        )
        self.assertEqual(picked, [])
        self.assertTrue(helm)


class HelmContract(unittest.TestCase):
    GAMES = (
        "redis:\n  slots:\n    prod: 1\n    yjh-dev1: 4\n"
        "games:\n  - folder: server-prod\n    id: prod\n"
        "hubs:\n  - folder: server-prod\n    id: prod\n    tag: abc\n"
        "  - folder: server-yjh-dev1\n    id: yjh-dev1\n    tag: def\n"
    )

    def test_upgrade_resets_and_waits_planted_files(self) -> None:
        cmd = helm_upgrade_cmd("/chart", "/v.yaml", "/g.yaml", "/e.yaml")
        self.assertIn("--reset-values", cmd)
        self.assertIn("--wait", cmd)
        self.assertNotIn("--atomic", cmd)
        self.assertEqual(cmd[cmd.index("-f") : cmd.index("-f") + 6], ["-f", "/v.yaml", "-f", "/g.yaml", "-f", "/e.yaml"])

    def test_planted_maps(self) -> None:
        self.assertEqual(planted_hub_tags(self.GAMES), {"server-prod": "abc", "server-yjh-dev1": "def"})
        self.assertEqual(planted_hub_ids(self.GAMES), {"server-prod": "prod", "server-yjh-dev1": "yjh-dev1"})
        self.assertEqual(planted_redis_slots(self.GAMES), {"prod": 1, "yjh-dev1": 4})

    def test_image_drift_and_redis(self) -> None:
        self.assertEqual(
            image_drift({"server-prod": "abc"}, {"server-prod": "old"}),
            ["server-prod: plant=abc live=old"],
        )
        self.assertTrue(redis_url_ok("redis://redis:6379/1", 1))
        self.assertFalse(redis_url_ok("redis://redis:6379", 1))
        self.assertTrue(matchmake_create_ok(200, '{"roomId":"x"}'))
        self.assertFalse(matchmake_create_ok(523, "{}"))
        self.assertEqual(
            hubp_health_url("server-prod"),
            "https://server-prod.external.kr/hubp/server-prod-hub-0/health",
        )
        self.assertTrue(
            create_public_address_ok(
                "server-prod",
                '{"roomId":"x","room":{"publicAddress":"server-prod.external.kr/hubp/server-prod-hub-0"}}',
            )
        )
        self.assertFalse(
            create_public_address_ok(
                "server-prod",
                '{"roomId":"x","room":{"publicAddress":"server-prod.external.kr/hubp/hash-pod"}}',
            )
        )
        self.assertEqual(rooms_url("server-prod"), "https://server-prod.external.kr/rooms")
        self.assertEqual(create_room_id('{"roomId":"LOh_VE43u"}'), "LOh_VE43u")
        self.assertTrue(rooms_listed('{"rooms":[{"roomId":"LOh_VE43u"}]}', "LOh_VE43u"))
        self.assertFalse(rooms_listed('{"rooms":[]}', "LOh_VE43u"))
        self.assertTrue(rooms_stayed([True, True]))
        self.assertFalse(rooms_stayed([True, False]))

    def test_platform_pipeline_is_yjh_and_prod(self) -> None:
        import importlib.util

        path = Path(__file__).with_name("apply-apps.py")
        spec = importlib.util.spec_from_file_location("apply_apps", path)
        apply = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(apply)
        self.assertTrue(apply.platform_web_pipeline("server-yjh-dev1"))
        self.assertTrue(apply.platform_web_pipeline("server-prod"))
        self.assertFalse(apply.platform_web_pipeline("server-pjh-dev1"))
        self.assertEqual(
            apply.legacy_hub_deploy_names(
                {
                    "items": [
                        {"metadata": {"name": "server-prod-hub"}},
                        {"metadata": {"name": "server-prod-hub-static"}},
                    ]
                }
            ),
            ["server-prod-hub"],
        )
        apps_py = path.read_text()
        self.assertIn("drop_legacy_hub_deployments", apps_py)
        self.assertIn("delete deploy", apps_py)
        self.assertIn("rebuild_images", apps_py)
        self.assertIn("--no-rebuild", apps_py)

class PlatformGodotPipeline(unittest.TestCase):
    def test_next_slots_export_on_ship(self) -> None:
        root = APPS.parent
        self.assertTrue((root / "deploy" / "scripts" / "build-godot.sh").is_file())
        self.assertTrue((root / "deploy" / "scripts" / "export_web.py").is_file())
        self.assertFalse((root / "deploy" / "scripts" / "assert_pack.py").is_file())
        build = (root / "deploy" / "scripts" / "build-godot.sh").read_text()
        self.assertIn("--import --quit", build)
        apps_yml = (root / ".github" / "workflows" / "apps.yml").read_text()
        self.assertIn("if: ${{ !cancelled() }}", apps_yml)
        self.assertIn("apply-apps.py helm", apps_yml)
        self.assertIn("helm --no-rebuild", apps_yml)
        for folder in ("server-yjh-dev1", "server-prod"):
            text = (APPS / folder / "hackertone.yaml").read_text()
            self.assertNotIn("skipExport", text)
            self.assertIn("pipeline: platform", text)
            self.assertFalse((APPS / folder / "web" / "scripts" / "build-godot.sh").is_file())
            dockerfile = (APPS / folder / "web" / "Dockerfile").read_text()
            self.assertIn("index.pck", dockerfile)

    def test_pjh_keeps_static_export(self) -> None:
        text = (APPS / "server-pjh-dev1" / "hackertone.yaml").read_text()
        self.assertNotIn("pipeline: platform", text)


class HubImages(unittest.TestCase):
    def test_folder_from_ref(self) -> None:
        self.assertEqual(
            folder_from_hub_ref("harbor.50.internal.xz/library/server-prod:b902eb470f27"),
            "server-prod",
        )

    def test_missing_only_absent_tags(self) -> None:
        refs = [
            "harbor.50.internal.xz/library/server-yjh-dev1:aaa",
            "harbor.50.internal.xz/library/server-prod:bbb",
        ]
        listed = "harbor.50.internal.xz/library/server-yjh-dev1:aaa\n"
        self.assertEqual(missing_hub_refs(refs, listed), [refs[1]])


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
