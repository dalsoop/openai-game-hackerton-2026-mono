#!/usr/bin/env node
// export 직후 · 사전압축 전에 호출. glue 의 side.wasm 로드를 끊고 낡은 .br/.gz 를 지운다.
import { spawnSync } from "child_process";
import path from "path";
import { fileURLToPath } from "url";
import { prepareGodotExportDir } from "../lib/godot/godot-export-prepare.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const dir = process.argv[2];
if (!dir) {
  console.error("사용법: prepare-godot-export.mjs <godot-export-dir>");
  process.exit(1);
}
const abs = path.resolve(dir);
let result;
try {
  result = prepareGodotExportDir(abs);
} catch (err) {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
}
console.log(
  `prepare-godot-export: stripped=${result.stripped} sideGone=${result.sideGone.length} stale=${result.stale.length}`,
);
if (result.stripped) {
  const gen = path.join(here, "gen-godot-manifest.mjs");
  const ran = spawnSync(process.execPath, [gen, abs], { stdio: "inherit" });
  if (ran.status !== 0) {process.exit(ran.status ?? 1);}
}
