#!/usr/bin/env python3
"""차트 1만 CCU 값 — 복제·publicPrefix·스케일 폴더가 빠지면 실패."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VALUES = (ROOT / "deploy" / "chart" / "values.yaml").read_text()
HUB = (ROOT / "deploy" / "chart" / "templates" / "hub.yaml").read_text()
WEB = (ROOT / "deploy" / "chart" / "templates" / "web.yaml").read_text()


class HubScaleChart(unittest.TestCase):
    def test_colyseus_slots_are_scaled(self) -> None:
        self.assertIn("server-yjh-dev1", VALUES)
        self.assertIn("server-prod", VALUES)
        self.assertIn("replicaCount: 20", VALUES)
        self.assertIn('publicPrefix: "%s.external.kr/hubp"', VALUES)
        self.assertIn("staticSplit: true", VALUES)
        self.assertIn("nodeSelector: {}", VALUES)

    def test_templates_pin_ws_and_static(self) -> None:
        self.assertIn("HUB_PUBLIC_PREFIX", HUB)
        self.assertIn("hub-static", HUB)
        self.assertIn("HUB_STATIC_SPLIT", HUB)
        self.assertIn("hub-static:80", WEB)
        self.assertIn("read_timeout 3600s", WEB)
        self.assertIn("/matchmake*", WEB)
        self.assertIn("/rooms", WEB)


if __name__ == "__main__":
    unittest.main()
