import type { IncomingMessage, ServerResponse } from "http";
import { createReadStream, statSync } from "fs";
import path from "path";
import { godotWorkletAssetPath } from "./asset-store.js";
import { godotCacheHeaders, shouldServeEncoding } from "./serve-encoding.js";

function statExists(p: string): boolean {
  try { statSync(p); return true; } catch { return false; }
}

const GODOT_DIR = path.join(process.cwd(), "public", "godot");
// 이미지 안에서는 public/addons, 로컬 dev 는 project/addons.
const ADDONS_DIR = process.env.ADDONS_DIR
  ?? (statExists(path.join(process.cwd(), "public", "addons"))
    ? path.join(process.cwd(), "public", "addons")
    : path.join(process.cwd(), "..", "project", "addons"));

const GODOT_MIME: Record<string, string> = {
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".js": "text/javascript",
  ".json": "application/json",
};

// /godot/* 대용량 파일: 사전 압축본(.br/.gz)을 Content-Encoding으로 서빙.
// ?v=해시(매니페스트 버전)가 붙으면 불변 캐시, 아니면 재검증.
export function serveAddonsAsset(req: IncomingMessage, res: ServerResponse, pathname: string): boolean {
  const rel = path.normalize(pathname.replace(/^\/addons\//, ""));
  if (rel.startsWith("..")) {return false;}
  const file = path.join(ADDONS_DIR, rel);
  try {
    const st = statSync(file);
    if (!st.isFile()) {return false;}
    res.writeHead(200, {
      "content-type": "application/wasm",
      "content-length": st.size,
      "cache-control": "no-cache",
      "cross-origin-resource-policy": "same-origin",
    });
    createReadStream(file).pipe(res);
    return true;
  } catch {
    return false;
  }
}

export function serveGodotAsset(req: IncomingMessage, res: ServerResponse, pathname: string): boolean {
  const rel = path.normalize(pathname.replace(/^\/godot\//, ""));
  if (rel.startsWith("..")) {return false;}
  const ext = path.extname(rel);
  const mime = GODOT_MIME[ext];
  if (!mime) {return false;}

  const versioned = /\bv=[0-9a-f]+/.test((req.url ?? "").split("?")[1] ?? "");
  const cacheHeaders = godotCacheHeaders(versioned);

  const base = path.join(GODOT_DIR, rel);
  const accept = String(req.headers["accept-encoding"] ?? "");
  const rawMtime = mtimeMs(base);
  const candidates: Array<[string, string | null]> = [];
  if (accept.includes("br")) {candidates.push([`${base}.br`, "br"]);}
  if (accept.includes("gzip")) {candidates.push([`${base}.gz`, "gzip"]);}
  candidates.push([base, null]);

  for (const [file, encoding] of candidates) {
    if (encoding && !isEncodingCandidateFresh(file, rawMtime)) {continue;}
    if (serveOne(file, encoding, req, res, mime, cacheHeaders)) {return true;}
  }
  return false;
}

function isEncodingCandidateFresh(file: string, rawMtime: number | null): boolean {
  return shouldServeEncoding(rawMtime, mtimeMs(file));
}

function mtimeMs(file: string): number | null {
  try {
    const st = statSync(file);
    return st.isFile() ? st.mtimeMs : null;
  } catch {
    return null;
  }
}

// 후보 하나를 응답에 싣는다 — 성공 여부만 반환 (max-depth: 루프 안 try/isFile 중첩 방지)
function serveOne(
  file: string,
  encoding: string | null,
  req: IncomingMessage,
  res: ServerResponse,
  mime: string,
  cacheHeaders: Record<string, string>,
): boolean {
  let st;
  try {
    st = statSync(file);
  } catch {
    return false;
  }
  if (!st.isFile()) {return false;}
  // 무버전 요청도 ETag 검증으로 304 를 돌려준다 — 대용량 파일의 재전송을 갱신 검사로 끝낸다.
  const etag = `"${st.size.toString(16)}-${Math.floor(st.mtimeMs).toString(16)}"`;
  if (req.headers["if-none-match"] === etag) {
    res.writeHead(304, { etag, ...cacheHeaders });
    res.end();
    return true;
  }
  res.writeHead(200, {
    "content-type": mime,
    "content-length": st.size,
    etag,
    ...cacheHeaders,
    ...(encoding ? { "content-encoding": encoding, vary: "Accept-Encoding" } : {}),
  });
  if (req.method === "HEAD") {
    res.end();
    return true;
  }
  createReadStream(file).pipe(res);
  return true;
}

/** 로케일 접두사로 들어오는 워크릿. 허브 폴백과 정적 서버가 같이 쓴다. */
export function servePageRelativeGodotAssets(
  req: IncomingMessage,
  res: ServerResponse,
  pathname: string,
): boolean {
  const worklet = godotWorkletAssetPath(pathname);
  return Boolean(worklet && serveGodotAsset(req, res, worklet));
}

export function servePackAssets(
  req: IncomingMessage,
  res: ServerResponse,
  pathname: string,
): boolean {
  if (servePageRelativeGodotAssets(req, res, pathname)) {return true;}
  const servePack = process.env.HUB_STATIC_SPLIT !== "1";
  if (servePack && pathname.startsWith("/addons/") && serveAddonsAsset(req, res, pathname)) {
    return true;
  }
  if (servePack && pathname.startsWith("/godot/") && serveGodotAsset(req, res, pathname)) {
    return true;
  }
  return false;
}
