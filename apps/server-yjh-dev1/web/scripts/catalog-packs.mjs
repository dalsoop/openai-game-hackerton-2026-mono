#!/usr/bin/env node
// 카탈로그 pack 필드 리더 — 셸·스모크·계약 게이트가 TS 를 로드하지 않고 같은 정본을 읽는다.
import { readFileSync } from "fs";
import path from "path";
import { fileURLToPath } from "url";

const catalogPath = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "lib", "games", "catalog.ts");

export function readCatalogPacks() {
  const src = readFileSync(catalogPath, "utf8");
  const packs = [...src.matchAll(/^\s*pack:\s*"([^"]+)"/gm)].map((m) => m[1]);
  return [...new Set(packs)];
}

export function godotPublicUrl(pack, file) {
  return file ? `/godot/${pack}/${file}` : `/godot/${pack}`;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  for (const pack of readCatalogPacks()) {console.log(pack);}
}
