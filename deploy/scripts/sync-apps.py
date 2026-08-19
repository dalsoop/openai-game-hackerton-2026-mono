#!/usr/bin/env python3
"""호환 엔트리. 카탈로그·스냅샷은 plant-apps.py."""
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name("plant-apps.py")), run_name="__main__")
