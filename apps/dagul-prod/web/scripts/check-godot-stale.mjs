#!/usr/bin/env node
/**
 * public/godot/.export-stamp 의 해시가 project/ 소스 해시와 다르면 경고하고 종료한다.
 * deploy/scripts/export_web.py 의 project_source_hash 와 같은 로직.
 *
 * 우회: SKIP_GODOT_STALE_CHECK=1 npm run dev
 */
import { createHash } from "crypto";
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, join, resolve, relative } from "path";

const WRITE_STAMP = process.argv.includes("--write-stamp");
if (!WRITE_STAMP && process.env.SKIP_GODOT_STALE_CHECK === "1") process.exit(0);

const root = resolve(import.meta.dirname, "..", "..", "project");
const stampPath = resolve(import.meta.dirname, "..", "public", "godot", ".export-src-hash");

const SKIP_PARTS = new Set([".godot", "web", "__pycache__"]);

function sourceHash() {
  const hash = createHash("sha256");
  const files = [];
  function walk(dir) {
    let entries;
    try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (SKIP_PARTS.has(e.name)) continue;
      const full = join(dir, e.name);
      if (e.isDirectory()) { walk(full); continue; }
      if (!e.isFile()) { continue; }
      files.push(full);
    }
  }
  walk(root);
  files.sort();
  for (const f of files) {
    hash.update(relative(root, f).replaceAll("\\", "/"));
    hash.update(readFileSync(f));
  }
  return hash.digest("hex").slice(0, 12);
}

const current = sourceHash();
if (WRITE_STAMP) {
  mkdirSync(dirname(stampPath), { recursive: true });
  writeFileSync(stampPath, `${current}\n`);
  console.log(`check-godot-stale: wrote stamp ${current}`);
  process.exit(0);
}

let stamp;
try { stamp = readFileSync(stampPath, "utf8").trim(); } catch { process.exit(0); }
if (!stamp) process.exit(0);

if (stamp === current) process.exit(0);

console.error(
  `\n❌  Godot export가 소스와 다릅니다 (stamp=${stamp}, src=${current}).` +
  `\n   npm run godot:ship  으로 다시 빌드하세요.` +
  `\n   (우회: SKIP_GODOT_STALE_CHECK=1 npm run dev)\n`
);
process.exit(1);
