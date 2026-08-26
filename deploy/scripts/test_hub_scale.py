#!/usr/bin/env python3
"""차트 1만 CCU 값 — 복제·publicPrefix·스케일 폴더가 빠지면 실패."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VALUES = (ROOT / "deploy" / "chart" / "values.yaml").read_text()
HUB = (ROOT / "deploy" / "chart" / "templates" / "hub.yaml").read_text()
HELPERS = (ROOT / "deploy" / "chart" / "templates" / "_helpers.tpl").read_text()
WEB = (ROOT / "deploy" / "chart" / "templates" / "web.yaml").read_text()


class HubScaleChart(unittest.TestCase):
    def test_redis_url_is_host_only(self) -> None:
        self.assertIn('url: "redis://redis:6379"', VALUES)
        self.assertIn("redis.slots", VALUES)

    def test_templates_use_per_slot_redis_db(self) -> None:
        self.assertIn("hackertone-games.hubRedisUrl", HUB)
        self.assertIn("redis.slots", HELPERS)

    def test_templates_pin_ws_and_static(self) -> None:
        self.assertIn("HUB_PUBLIC_PREFIX", HUB)
        self.assertIn("hub-static", HUB)
        self.assertIn("HUB_STATIC_SPLIT", HUB)
        self.assertIn("hub-static:80", WEB)
        self.assertIn("read_timeout 3600s", WEB)
        self.assertIn("/matchmake*", WEB)
        self.assertIn("/rooms", WEB)

    def test_prod_scale_values(self) -> None:
        self.assertIn("staticSplit: true", VALUES)
        self.assertIn('publicPrefix: "%s.external.kr/hubp"', VALUES)
        self.assertIn("- server-prod", VALUES)
        self.assertIn("replicaCount: 20", VALUES)
        self.assertIn("staticResources:", VALUES)
        self.assertIn("scale.resources", HUB)


if __name__ == "__main__":
    unittest.main()
