#!/usr/bin/env node
// React↔Godot 핸드오프 계약 대조 게이트.
// 정본: web/lib/hub/config.ts (HANDOFF / DOM_EVT / wsPath / defaultMode)
// 거울: apps/server-yjh-dev1/project/scripts/net/web_contract.gd
// 값이 하나라도 어긋나면 exit 1.
import { readFileSync, existsSync } from "fs";
import { createHash } from "crypto";
import path from "path";
import { fileURLToPath } from "url";

const here = path.dirname(fileURLToPath(import.meta.url));
const tsPath = path.join(here, "..", "lib", "hub", "config.ts");
const gdPath = path.join(here, "..", "..", "project", "core", "contract", "web_contract.gd");

const ts = readFileSync(tsPath, "utf8");
const gd = readFileSync(gdPath, "utf8");

function tsBlock(name) {
  const m = ts.match(new RegExp(`export const ${name} = \\{([\\s\\S]*?)\\} as const;`));
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

// TS 정본 키 ↔ GD 거울 상수 매핑
const HANDOFF = tsBlock("HANDOFF");
const DOM_EVT = tsBlock("DOM_EVT");
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

// 커스텀 메시지 타입 거울 — TS MSG 와 web_contract.gd MSG_* 가 1:1 이어야 한다.
const MSG_KEYS = ["START", "INPUT", "HOST_SNAP", "SNAP", "PEER_INPUT", "ERROR"];
const msgBlock = ts.match(/export const MSG = \{([\s\S]*?)\} as const;/)?.[1] ?? "";
for (const key of MSG_KEYS) {
  const tsVal = msgBlock.match(new RegExp(`(?:^|[\\s,{])${key}: "([^"]+)"`))?.[1];
  const gdVal = gdConst(`MSG_${key}`);
  if (!tsVal || tsVal !== gdVal) {fail(`MSG.${key}: 정본 "${tsVal}" ≠ 거울 MSG_${key} "${gdVal}"`);}
}

// 기본 모드
const tsMode = ts.match(/defaultMode:\s*"([^"]+)"/)?.[1];
const gdMode = gdConst("DEFAULT_MODE");
if (!tsMode || tsMode !== gdMode) fail(`defaultMode: 정본 "${tsMode}" ≠ 거울 DEFAULT_MODE "${gdMode}"`);

// Godot 산출물 무결성: manifest.filesHash 가 실제 파일 해시와 일치해야 한다.
// (version 은 yymmddhhmmss 타임스탬프 — 내용 불변이면 계승된다.)
// (export 후 매니페스트 재생성을 빼먹으면 여기서 빌드가 죽는다 — npm run godot:build 사용)
// 산출물 자체가 없는 체크아웃(CI 등)에서는 건너뛴다 — 로컬에서 빌드 산출물이
// 있는데 manifest 만 빠진 경우는 여전히 실패시킨다.
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
  console.error(`\ncheck-contract: ${errors}건 불일치 — 정본(config.ts)을 먼저 고치고 거울을 맞추세요`);
  process.exit(1);
}
console.log("check-contract: 정본-거울 일치 (키 7종 + MSG 6종 + defaultMode) · Godot 산출물 버전 무결");
