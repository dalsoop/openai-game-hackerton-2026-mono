#!/usr/bin/env node
// Godot 백그라운드 프리로드 경로 스모크 — GodotRuntime.preload 와 동일 물질을 노드에서 실측.
// 매니페스트 → 버전드 URL(브로틀리 협상) 다운로드 → WASM 컴파일까지 실패 시 exit 1.
import { godotPublicUrl, readCatalogPacks } from "./catalog-packs.mjs";

const BASE = process.env.HUB_URL || "http://127.0.0.1:3000";
const PACK = readCatalogPacks()[0];
if (!PACK) {console.error("  ✗ FAIL: 카탈로그 pack 없음"); process.exit(1);}

const fail = (m) => { console.error(`  ✗ FAIL: ${m}`); process.exit(1); };
const step = (m) => console.log(`  ✓ ${m}`);

const t0 = Date.now();
const mResp = await fetch(`${BASE}${godotPublicUrl(PACK, "manifest.json")}`, { cache: "no-store" });
if (!mResp.ok) fail(`manifest ${mResp.status}`);
const manifest = await mResp.json();
if (!/^[0-9a-f]{12}$/.test(manifest.version)) fail(`manifest.version 형식: ${manifest.version}`);
step(`manifest v=${manifest.version}`);

async function pull(file) {
  const url = `${BASE}${godotPublicUrl(PACK, file)}?v=${manifest.version}`;
  const resp = await fetch(url);
  if (!resp.ok) fail(`${file} ${resp.status}`);
  const cc = resp.headers.get("cache-control") || "";
  if (!cc.includes("immutable")) fail(`${file}: 버전드 URL인데 immutable 아님 (${cc})`);
  const buf = await resp.arrayBuffer();
  return buf;
}

const [wasm, pck, js] = await Promise.all([pull("index.wasm"), pull("index.pck"), pull("index.js")]);
step(`다운로드 wasm=${(wasm.byteLength / 1048576).toFixed(1)}MB pck=${(pck.byteLength / 1048576).toFixed(1)}MB js=${(js.byteLength / 1024).toFixed(0)}KB (${Date.now() - t0}ms)`);

if (String.fromCharCode(...new Uint8Array(pck.slice(0, 4))) !== "GDPC") fail("pck 매직(GDPC) 불일치");
step("pck 매직 GDPC 확인");

const tc = Date.now();
await WebAssembly.compile(wasm);
step(`WASM 컴파일 성공 (${Date.now() - tc}ms)`);

console.log(`\nsmoke-preload: 통과 — 백그라운드 프리로드 경로 정상 (총 ${Date.now() - t0}ms)`);
