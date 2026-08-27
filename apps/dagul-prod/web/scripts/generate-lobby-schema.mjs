#!/usr/bin/env node
// 정본: lib/hub/match-schema/*.ts · lobby-state.ts
// GD 산출물(lobby_state_schema.gd)은 쓰지 않는다 — Colyseus GDExtension/side.wasm 크래시.
// 기본 실행과 --check 는 같다: tmp 에서 TS codegen 만 확인하고, project 에 생성본이 있으면 실패.
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
  if (existsSync(outPath)) {
    fail("lobby_state_schema.gd 가 있습니다. Colyseus GD 스키마는 금지입니다 (side.wasm 크래시). 파일을 지우세요.");
  }
  console.log("generate-lobby-schema: TS 스키마 codegen 통과, GD 생성본 없음");
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
