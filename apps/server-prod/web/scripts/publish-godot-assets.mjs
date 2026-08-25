#!/usr/bin/env node
// 카탈로그 팩 폴더를 project/web 산출물로 채운다. --link 는 개발 심링크, 기본은 실파일 복사.
import { existsSync, mkdirSync, rmSync, copyFileSync, symlinkSync, readdirSync } from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { readCatalogPacks } from "./catalog-packs.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const WEB = path.join(here, "..");
const SRC = path.join(WEB, "..", "project", "web");
const LINK = process.argv.includes("--link");

const NAMES = [
  "index.wasm", "index.pck", "index.js", "index.side.wasm", "manifest.json",
  "index.audio.worklet.js", "index.audio.position.worklet.js",
  "index.wasm.br", "index.pck.br", "index.js.br", "index.side.wasm.br",
  "index.wasm.gz", "index.pck.gz", "index.js.gz", "index.side.wasm.gz",
];

if (!existsSync(path.join(SRC, "index.wasm"))) {
  console.error(`publish-godot-assets: Godot export 없음: ${SRC}`);
  process.exit(1);
}

const packs = readCatalogPacks();
if (packs.length === 0) {
  console.error("publish-godot-assets: 카탈로그 pack 이 없습니다");
  process.exit(1);
}

for (const pack of packs) {
  const dest = path.join(WEB, "public", "godot", pack);
  rmSync(dest, { recursive: true, force: true });
  mkdirSync(dest, { recursive: true });
  for (const name of NAMES) {
    const from = path.join(SRC, name);
    if (!existsSync(from)) {continue;}
    const to = path.join(dest, name);
    if (LINK) {symlinkSync(path.relative(dest, from), to);}
    else {copyFileSync(from, to);}
  }
  const count = readdirSync(dest).length;
  console.log(`publish-godot-assets: ${count}개 → ${dest} (${LINK ? "link" : "copy"})`);
}
