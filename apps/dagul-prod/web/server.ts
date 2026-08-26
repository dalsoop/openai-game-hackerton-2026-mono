import "./alias-register.js";
import { createServer, type IncomingMessage, type ServerResponse } from "http";
import { createReadStream, statSync } from "fs";
import path from "path";
import next from "next";
import { matchMaker, Server as ColyseusServer } from "colyseus";
import { WebSocketTransport } from "@colyseus/ws-transport";
import { RedisPresence } from "@colyseus/redis-presence";
import { RedisDriver } from "@colyseus/redis-driver";
import { LobbyRoom } from "./lib/hub/LobbyRoom.js";
import { HUB_CONFIG, ROOM_NAME } from "./lib/hub/config.js";
import { hubPublicAddress } from "./lib/hub/public-address.js";
import { roomsHttpBody, withDeadline } from "./lib/hub/rooms-http.js";
import { assetPlanOf, godotWorkletAssetPath, isExtLibPath } from "./lib/godot/asset-store.js";
import { healthBody } from "./lib/hub/health.js";
import { revisionBody } from "./lib/hub/revision.js";
import { liveRevisionId } from "./lib/hub/revision-fs.js";
import { redisConn } from "./lib/hub/redis-conn.js";

const dev = process.env.NODE_ENV !== "production";
const port = Number(process.env.PORT ?? 3000);

const GODOT_DIR = path.join(process.cwd(), "public", "godot");
// 이미지 안에서는 public/addons, 로컬 dev 는 project/addons.
const ADDONS_DIR = process.env.ADDONS_DIR
  ?? (statExists(path.join(process.cwd(), "public", "addons"))
    ? path.join(process.cwd(), "public", "addons")
    : path.join(process.cwd(), "..", "project", "addons"));

function statExists(p: string): boolean {
  try { statSync(p); return true; } catch { return false; }
}

// 슬롯 개명(server-prod → dagul-prod) 뒤에도 와일드카드 인그레스가 옛 호스트를
// 이 앱으로 폴백시킨다. 옛 도메인은 리다이렉트 없이 명확히 죽인다(410 Gone).
function cutRetiredHost(req: IncomingMessage, res: ServerResponse): boolean {
  const host = String(req.headers.host ?? "");
  if (!host.startsWith("server-prod.")) {return false;}
  res.writeHead(410, { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" });
  res.end("gone — https://dagul-prod.external.kr/");
  return true;
}
const GODOT_MIME: Record<string, string> = {
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".js": "text/javascript",
  ".json": "application/json",
};

// /godot/* 대용량 파일: 사전 압축본(.br/.gz)을 Content-Encoding으로 서빙.
// ?v=해시(매니페스트 버전)가 붙으면 불변 캐시, 아니면 재검증.
function serveAddonsAsset(req: IncomingMessage, res: ServerResponse, pathname: string): boolean {
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

function serveGodotAsset(req: IncomingMessage, res: ServerResponse, pathname: string): boolean {
  const rel = path.normalize(pathname.replace(/^\/godot\//, ""));
  if (rel.startsWith("..")) {return false;}
  const ext = path.extname(rel);
  const mime = GODOT_MIME[ext];
  if (!mime) {return false;}

  const versioned = /\bv=[0-9a-f]+/.test((req.url ?? "").split("?")[1] ?? "");
  const cacheControl = versioned ? "public, max-age=31536000, immutable" : "no-cache";

  const base = path.join(GODOT_DIR, rel);
  const accept = String(req.headers["accept-encoding"] ?? "");
  const candidates: Array<[string, string | null]> = [];
  if (accept.includes("br")) {candidates.push([`${base}.br`, "br"]);}
  if (accept.includes("gzip")) {candidates.push([`${base}.gz`, "gzip"]);}
  candidates.push([base, null]);

  for (const [file, encoding] of candidates) {
    if (serveOne(file, encoding, req, res, mime, cacheControl)) {return true;}
  }
  return false;
}

// 후보 하나를 응답에 싣는다 — 성공 여부만 반환 (max-depth: 루프 안 try/isFile 중첩 방지)
function serveOne(
  file: string,
  encoding: string | null,
  req: IncomingMessage,
  res: ServerResponse,
  mime: string,
  cacheControl: string,
): boolean {
  let st;
  try {
    st = statSync(file);
  } catch {
    return false;
  }
  if (!st.isFile()) {return false;}
  // 무버전 요청도 ETag 검증으로 304 를 돌려준다 — 엔진이 스스로 fetch 하는
  // index.side.wasm(8MB+)의 재전송을 본문 없이 갱신 검사로 끝낸다.
  const etag = `"${st.size.toString(16)}-${Math.floor(st.mtimeMs).toString(16)}"`;
  if (req.headers["if-none-match"] === etag) {
    res.writeHead(304, { etag, "cache-control": cacheControl });
    res.end();
    return true;
  }
  res.writeHead(200, {
    "content-type": mime,
    "content-length": st.size,
    etag,
    "cache-control": cacheControl,
    ...(encoding ? { "content-encoding": encoding, vary: "Accept-Encoding" } : {}),
  });
  if (req.method === "HEAD") {
    res.end();
    return true;
  }
  createReadStream(file).pipe(res);
  return true;
}

function jsonOk(res: ServerResponse, body: string): void {
  res.writeHead(200, { "content-type": "application/json", "cache-control": "no-store" });
  res.end(body);
}

function setIsolationHeaders(res: ServerResponse): void {
  // SharedArrayBuffer(스레드 지원 Godot 웹 빌드) 에 필요한 교차 출처 격리 헤더.
  res.setHeader("cross-origin-opener-policy", "same-origin");
  res.setHeader("cross-origin-embedder-policy", "require-corp");
  res.setHeader("cross-origin-resource-policy", "same-origin");
}

function serveMeta(pathname: string, res: ServerResponse): boolean {
  if (pathname === "/health" || pathname === "/healthz") {
    jsonOk(res, healthBody());
    return true;
  }
  if (pathname === "/api/version") {
    jsonOk(res, revisionBody(liveRevisionId()));
    return true;
  }
  return false;
}

function serveRoomsList(pathname: string, res: ServerResponse): boolean {
  if (pathname === "/rooms") {
    void withDeadline(matchMaker.query({ name: ROOM_NAME }), HUB_CONFIG.roomsFetchMs).then((listed) => {
      jsonOk(res, JSON.stringify(roomsHttpBody(listed)));
    }).catch(() => {
      res.writeHead(503, { "content-type": "application/json" });
      res.end(JSON.stringify({ rooms: [] }));
    });
    return true;
  }
  return false;
}

function servePackAssets(
  req: IncomingMessage,
  res: ServerResponse,
  pathname: string,
): boolean {
  // extlib 는 Godot dlopen 이 페이지 루트에서 파일명만 요청한다.
  // HUB_STATIC_SPLIT 이어도 Caddy 가 static 으로 못 넘기면 Next 404 가 난다.
  if (isExtLibPath(pathname) &&
      serveAddonsAsset(req, res, "/addons/colyseus/bin/" + assetPlanOf("dagul").extLibFile)) {
    return true;
  }
  const worklet = godotWorkletAssetPath(pathname);
  if (worklet && serveGodotAsset(req, res, worklet)) {return true;}
  const servePack = process.env.HUB_STATIC_SPLIT !== "1";
  if (servePack && pathname.startsWith("/addons/") && serveAddonsAsset(req, res, pathname)) {
    return true;
  }
  if (servePack && pathname.startsWith("/godot/") && serveGodotAsset(req, res, pathname)) {
    return true;
  }
  return false;
}

type RequestHandle = (req: IncomingMessage, res: ServerResponse) => void | Promise<void>;

function hubFallback(
  req: IncomingMessage,
  res: ServerResponse,
  handle: RequestHandle,
): void {
  if (cutRetiredHost(req, res)) {return;}
  setIsolationHeaders(res);
  const pathname = (req.url ?? "/").split("?")[0];
  if (serveMeta(pathname, res)) {return;}
  if (serveRoomsList(pathname, res)) {return;}
  if (servePackAssets(req, res, pathname)) {return;}
  void handle(req, res);
}

function startStatic(): void {
  createServer((req, res) => {
    if (cutRetiredHost(req, res)) {return;}
    res.setHeader("cross-origin-opener-policy", "same-origin");
    res.setHeader("cross-origin-embedder-policy", "require-corp");
    res.setHeader("cross-origin-resource-policy", "same-origin");
    const pathname = (req.url ?? "/").split("?")[0];
    if (serveMeta(pathname, res)) {return;}
    if (isExtLibPath(pathname) &&
        serveAddonsAsset(req, res, "/addons/colyseus/bin/" + assetPlanOf("dagul").extLibFile)) {return;}
    {
      const worklet = godotWorkletAssetPath(pathname);
      if (worklet && serveGodotAsset(req, res, worklet)) {return;}
    }
    if (pathname.startsWith("/addons/") && serveAddonsAsset(req, res, pathname)) {return;}
    if (pathname.startsWith("/godot/") && serveGodotAsset(req, res, pathname)) {return;}
    res.writeHead(404).end();
  }).listen(port, "0.0.0.0", () => {
    console.log(`> Static on http://localhost:${port}`);
  });
}

function startHub(): void {
  const app = next({ dev });
  const handle = app.getRequestHandler();
  void app.prepare().then(async () => {
  const httpServer = createServer();

  // Next dev HMR(webpack-hmr) 업그레이드는 Next 핸들러로 넘긴다 — 끊으면
  // dev 에서 핫리로드가 죽는다. 그 외 업그레이드는 Colyseus 가 가져간다.
  const nextUpgrade = app.getUpgradeHandler();
  httpServer.on("upgrade", (req, socket, head) => {
    if ((req.url ?? "").startsWith("/_next")) {void nextUpgrade(req, socket, head);}
  });

  const transport = new WebSocketTransport({ noServer: true, maxPayload: HUB_CONFIG.maxPayload });
  transport.attachToServer(httpServer, {
    filter: (req) => !(req.url ?? "").startsWith("/_next"),
  });

  // 다중 인스턴스 확장(공식 docs.colyseus.io/scalability) — 조건부:
  // REDIS_URL 이 없으면 로컬 폴백(현재 단일 프로세스 동작 100% 유지),
  // HUB_PUBLIC_PREFIX+POD_NAME 가 있으면 클라가 이 Pod 로 직접 WS 연결한다.
  const redisUrl = process.env.REDIS_URL;
  const publicAddress = hubPublicAddress(process.env.HUB_PUBLIC_PREFIX, process.env.POD_NAME);

  const gameServer = new ColyseusServer({
    transport,
    greet: false,
    ...(redisUrl ? { presence: new RedisPresence(redisConn(redisUrl)), driver: new RedisDriver(redisConn(redisUrl)) } : {}),
    ...(publicAddress ? { publicAddress } : {}),
    // Colyseus 라우터(매치메이킹 /matchmake/*)가 못 받는 요청은 여기로 폴백된다.
    express: (expressApp): void => {
      expressApp.use((req: IncomingMessage, res: ServerResponse): void => {
        hubFallback(req, res, handle);
      });
    },
  });

  gameServer.define(ROOM_NAME, LobbyRoom);

  await gameServer.serverless();
  httpServer.listen(port, "0.0.0.0", () => {
    console.log(`> Ready on http://localhost:${port}`);
    console.log(`> Colyseus room: "${ROOM_NAME}" (matchmake: /matchmake/*)`);
  });
  });
}

if (process.env.HUB_ROLE === "static") {
  startStatic();
} else {
  startHub();
}
