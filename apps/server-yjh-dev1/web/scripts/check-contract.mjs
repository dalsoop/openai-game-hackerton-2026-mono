#!/usr/bin/env node
// React↔Godot 핸드오프 계약 대조 게이트.
// 정본: web/lib/contract/wire.ts · web/lib/games/catalog.ts
// 거울: project/core/contract/web_contract.gd
import { readFileSync, existsSync } from "fs";
import { createHash } from "crypto";
import path from "path";
import { fileURLToPath } from "url";
import { readCatalogPacks } from "./catalog-packs.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const tsPath = path.join(here, "..", "lib", "contract", "wire.ts");
const catalogPath = path.join(here, "..", "lib", "games", "catalog.ts");
const gdPath = path.join(here, "..", "..", "project", "core", "contract", "web_contract.gd");

const ts = readFileSync(tsPath, "utf8");
const catalog = readFileSync(catalogPath, "utf8");
const gd = readFileSync(gdPath, "utf8");

function tsBlock(src, name) {
  const m = src.match(new RegExp(`export const ${name} = \\{([\\s\\S]*?)\\} as const;`));
  if (!m) fail(`정본에서 ${name} 블록을 찾지 못했습니다`);
  const values = {};
  for (const [, key, val] of m[1].matchAll(/(\w+):\s*"([^"]+)"/g)) values[key] = val;
  return values;
}

function gdConst(name) {
  const m = gd.match(new RegExp(`const ${name} := "([^"]+)"`));
  return m ? m[1] : null;
}

let errors = 0;
function fail(msg) {
  console.error(`  ✗ ${msg}`);
  errors++;
}

const HANDOFF = tsBlock(ts, "HANDOFF");
const DOM_EVT = tsBlock(ts, "DOM_EVT");
const pairs = [
  ["HANDOFF.FROM_HUB", HANDOFF.FROM_HUB, "KEY_FROM_HUB"],
  ["HANDOFF.GAME", HANDOFF.GAME, "KEY_GAME"],
  ["HANDOFF.NAME", HANDOFF.NAME, "KEY_NAME"],
  ["HANDOFF.ROOM_ID", HANDOFF.ROOM_ID, "KEY_ROOM_ID"],
  ["HANDOFF.SLOT", HANDOFF.SLOT, "KEY_SLOT"],
  ["HANDOFF.RESUME", HANDOFF.RESUME, "KEY_RESUME"],
  ["HANDOFF.MATCH", HANDOFF.MATCH, "KEY_MATCH"],
  ["DOM_EVT.MATCH_START", DOM_EVT.MATCH_START, "EVT_MATCH_START"],
  ["DOM_EVT.MATCH_END", DOM_EVT.MATCH_END, "EVT_MATCH_END"],
];

for (const [label, tsVal, gdName] of pairs) {
  const gdVal = gdConst(gdName);
  if (!tsVal) fail(`${label}: 정본에 값 없음`);
  else if (gdVal === null) fail(`${gdName}: 거울(web_contract.gd)에 상수 없음`);
  else if (tsVal !== gdVal) fail(`${label}: 정본 "${tsVal}" ≠ 거울 "${gdVal}"`);
}

const MSG_KEYS = ["START", "INPUT", "HOST_SNAP", "SNAP", "PEER_INPUT", "ERROR"];
const msgBlock = ts.match(/export const MSG = \{([\s\S]*?)\} as const;/)?.[1] ?? "";
for (const key of MSG_KEYS) {
  const tsVal = msgBlock.match(new RegExp(`(?:^|[\\s,{])${key}: "([^"]+)"`))?.[1];
  const gdVal = gdConst(`MSG_${key}`);
  if (!tsVal || tsVal !== gdVal) {fail(`MSG.${key}: 정본 "${tsVal}" ≠ 거울 MSG_${key} "${gdVal}"`);}
}

const catalogId = catalog.match(/GAME_CATALOG[\s\S]*?id:\s*"([^"]+)"/)?.[1];
const catalogMode = catalog.match(/GAME_CATALOG[\s\S]*?defaultMode:\s*"([^"]+)"/)?.[1];
const gdGame = gdConst("DEFAULT_GAME");
const gdMode = gdConst("DEFAULT_MODE");
if (!catalogId || catalogId !== gdGame) fail(`DEFAULT_GAME: 카탈로그 "${catalogId}" ≠ 거울 "${gdGame}"`);
if (!catalogMode || catalogMode !== gdMode) fail(`DEFAULT_MODE: 카탈로그 "${catalogMode}" ≠ 거울 "${gdMode}"`);

const catalogIds = [...catalog.matchAll(/^\s*id:\s*"([^"]+)"/gm)].map((m) => m[1]);
const catalogPackFields = [...catalog.matchAll(/^\s*pack:\s*"([^"]+)"/gm)].map((m) => m[1]);
if (catalogIds.length === 0 || catalogIds.length !== catalogPackFields.length) {
  fail(`카탈로그 항목마다 pack 필요 — id ${catalogIds.length} / pack ${catalogPackFields.length}`);
}
const packs = readCatalogPacks();
if (packs.length === 0) {fail("catalog pack 집합이 비어 있습니다");}

const godotDir = path.join(here, "..", "..", "project", "web");
const manifestPath = path.join(godotDir, "manifest.json");
const hasArtifacts = existsSync(path.join(godotDir, "index.pck"));
if (!existsSync(godotDir) || (!existsSync(manifestPath) && !hasArtifacts)) {
  console.log("  · Godot 산출물 없음(CI 체크아웃 등) — 버전 무결성 검사 건너뜀");
} else if (!existsSync(manifestPath)) {
  fail("산출물은 있는데 manifest.json 없음 — npm run godot:build 로 생성하세요");
} else {
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  const hash = createHash("sha1");
  for (const f of manifest.files) hash.update(readFileSync(path.join(godotDir, f)));
  const actual = hash.digest("hex").slice(0, 12);
  if (actual !== manifest.filesHash) {
    fail(`Godot 산출물 해시 불일치: manifest=${manifest.filesHash} 실제=${actual} — npm run godot:build 로 재생성하세요`);
  }
}

if (errors > 0) {
  console.error(`\ncheck-contract: ${errors}건 불일치 — 정본(lib/contract, catalog)을 먼저 고치고 거울을 맞추세요`);
  process.exit(1);
}
console.log(`check-contract: 정본-거울 일치 (키 7종 + MSG 6종 + DEFAULT_GAME/MODE + pack ${packs.length}) · Godot 산출물 버전 무결`);
