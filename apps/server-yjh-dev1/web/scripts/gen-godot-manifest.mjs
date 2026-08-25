#!/usr/bin/env node
// Godot 산출물 버전 매니페스트 생성.
// version = js+wasm+pck 내용 해시 — 셋 중 하나라도 바뀌면 버전이 바뀐다.
// 런타임(GodotRuntime)은 이 버전을 쿼리로 붙여 불변 캐시를 안전하게 쓴다.
import { createHash } from "crypto";
import { readFileSync, writeFileSync } from "fs";
import path from "path";

const outDir = process.argv[2];
if (!outDir) {
  console.error("사용법: gen-godot-manifest.mjs <godot-export-dir>");
  process.exit(1);
}

const files = ["index.js", "index.wasm", "index.pck", "index.side.wasm"];
const hash = createHash("sha1");
for (const f of files) hash.update(readFileSync(path.join(outDir, f)));
const version = hash.digest("hex").slice(0, 12);

writeFileSync(
  path.join(outDir, "manifest.json"),
  JSON.stringify({ version, files }, null, 2) + "\n",
);
console.log(`manifest: version=${version}`);
