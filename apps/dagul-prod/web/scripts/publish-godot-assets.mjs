#!/usr/bin/env node
// 카탈로그 팩 폴더를 project/web 산출물로 채운다. --link 는 개발 심링크, 기본은 실파일 복사.
import {
  existsSync, mkdirSync, rmSync, copyFileSync, symlinkSync, readdirSync,
} from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { readCatalogPacks } from "./catalog-packs.mjs";
import { dropStaleEncodings, shouldCopyName } from "../lib/godot/encoding-freshness.mjs";
import { prepareGodotExportDir, stripSideWasmLoader } from "../lib/godot/godot-export-prepare.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const WEB = path.join(here, "..");
const SRC = path.join(WEB, "..", "project", "web");
const LINK = process.argv.includes("--link");

export const PUBLISH_NAMES = [
  "index.wasm", "index.pck", "index.js", "manifest.json",
  "index.audio.worklet.js", "index.audio.position.worklet.js",
  "index.wasm.br", "index.pck.br", "index.js.br",
  "index.wasm.gz", "index.pck.gz", "index.js.gz",
];

export function publishPack(srcDir, destDir, { link }) {
  rmSync(destDir, { recursive: true, force: true });
  mkdirSync(destDir, { recursive: true });
  for (const name of PUBLISH_NAMES) {
    if (!shouldCopyName(srcDir, name)) {continue;}
    const from = path.join(srcDir, name);
    const to = path.join(destDir, name);
    if (link) {symlinkSync(path.relative(destDir, from), to);}
    else {copyFileSync(from, to);}
  }
  if (!link) {
    stripSideWasmLoader(path.join(destDir, "index.js"));
    dropStaleEncodings(destDir);
  }
}

function isMain() {
  const argvPath = process.argv[1];
  if (!argvPath) {return false;}
  return path.resolve(argvPath) === fileURLToPath(import.meta.url);
}

if (isMain()) {
  if (!existsSync(path.join(SRC, "index.wasm"))) {
    console.error(`publish-godot-assets: Godot export 없음: ${SRC}`);
    process.exit(1);
  }

  prepareGodotExportDir(SRC);

  const packs = readCatalogPacks();
  if (packs.length === 0) {
    console.error("publish-godot-assets: 카탈로그 pack 이 없습니다");
    process.exit(1);
  }

  for (const pack of packs) {
    const dest = path.join(WEB, "public", "godot", pack);
    publishPack(SRC, dest, { link: LINK });
    const count = readdirSync(dest).length;
    console.log(`publish-godot-assets: ${count}개 → ${dest} (${LINK ? "link" : "copy"})`);
  }
}
