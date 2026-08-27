#!/usr/bin/env node
// 정본: lib/hub/match-schema/*.ts · lobby-state.ts
// 산출: project/core/net/lobby_state_schema.gd
// Colyseus schema-codegen --gdscript 를 돌린 뒤 class_name LobbyColyseus 로 감싼다.
import { mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync, existsSync } from "fs";
import { tmpdir } from "os";
import path from "path";
import { spawnSync } from "child_process";
import { fileURLToPath } from "url";

const here = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.join(here, "..");
const outPath = path.join(webRoot, "..", "project", "core", "net", "lobby_state_schema.gd");
const schemaDir = path.join(webRoot, "lib", "hub", "match-schema");
/** 의존 잎이 앞에 온다. codegen 은 파일을 한 장으로 이어 붙인다. */
const SCHEMA_ORDER = [
  "until-buff.ts",
  "timed-buff.ts",
  "clone.ts",
  "hero-hud.ts",
  "hero.ts",
  "bullet.ts",
  "cover.ts",
  "crate.ts",
  "crate-orb.ts",
  "mid-tower.ts",
  "loot.ts",
  "deployable.ts",
  "zone.ts",
  "knockout.ts",
  "finish-cine.ts",
  "core.ts",
  "effect.ts",
  "event-data.ts",
  "event.ts",
  "state.ts",
];
const check = process.argv.includes("--check");

const HEADER = `class_name LobbyColyseus
extends RefCounted
## 생성본. 고치지 말 것.
## 정본: web/lib/hub/match-schema/*.ts · lobby-state.ts
## npm run schema:codegen

`;

function fail(msg) {
  console.error(`generate-lobby-schema: ${msg}`);
  process.exit(1);
}

function concatMatchSchema() {
  const present = new Set(readdirSync(schemaDir).filter((n) => n.endsWith(".ts") && n !== "index.ts"));
  for (const name of SCHEMA_ORDER) {
    if (!present.has(name)) {fail(`match-schema/${name} 없음`);}
  }
  for (const name of present) {
    if (!SCHEMA_ORDER.includes(name)) {fail(`match-schema/${name} 가 SCHEMA_ORDER 에 없다`);}
  }
  return SCHEMA_ORDER.map((name) => {
    const src = readFileSync(path.join(schemaDir, name), "utf8");
    return src
      .replace(/^import[\s\S]*?from\s+"[^"]+";\s*/gm, "")
      .trim();
  }).join("\n\n");
}

const bin = path.join(webRoot, "node_modules", ".bin", "schema-codegen");
if (!existsSync(bin)) {
  fail("schema-codegen 이 없습니다. apps/dagul-prod/web 에서 npm install 하세요");
}

const tmp = mkdtempSync(path.join(tmpdir(), "dagul-schema-"));
try {
  const lobbySrc = path.join(webRoot, "lib", "hub", "lobby-state.ts");
  const lobbyBody = readFileSync(lobbySrc, "utf8")
    .replace(/^import[\s\S]*?from\s+"[^"]+";\s*/gm, "")
    .replace(/asCharacterId\(undefined\)/g, '""')
    .replace(/asGameId\(undefined\)/g, '""')
    .replace(/defaultModeOf\(""\)/g, '""')
    .trim();
  const bundled = `import { Schema, ArraySchema, MapSchema, type } from "@colyseus/schema";\n\n${concatMatchSchema()}\n\n${lobbyBody}\n`;
  const bundledPath = path.join(tmp, "match-schema.ts");
  writeFileSync(bundledPath, bundled);
  const ran = spawnSync(bin, [bundledPath, "--gdscript", "--bundle", "--output", tmp], {
    cwd: webRoot,
    encoding: "utf8",
  });
  if (ran.status !== 0) {
    fail(`schema-codegen 실패\n${ran.stderr || ran.stdout || ""}`);
  }
  const generated = path.join(tmp, "schema.gd");
  if (!existsSync(generated)) {
    fail("schema-codegen 이 schema.gd 를 만들지 않았습니다");
  }
  let body = readFileSync(generated, "utf8");
  body = body.replace(/^class_name\s+\w+\s*\n/m, "");
  body = body.replace(/^extends\s+\w+\s*\n/m, "");
  const next = HEADER + body.trimStart();
  if (check) {
    if (!existsSync(outPath)) {
      fail(`${outPath} 없음 — npm run schema:codegen 을 먼저 실행하세요`);
    }
    const prev = readFileSync(outPath, "utf8");
    if (prev !== next) {
      fail("lobby_state_schema.gd 가 정본과 어긋납니다 — npm run schema:codegen");
    }
    console.log("generate-lobby-schema: 생성본이 정본과 같다");
    process.exit(0);
  }
  writeFileSync(outPath, next);
  console.log(`generate-lobby-schema: ${path.relative(webRoot, outPath)}`);
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
