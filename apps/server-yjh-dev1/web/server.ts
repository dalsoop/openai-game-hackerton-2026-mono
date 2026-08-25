import { createServer, type IncomingMessage, type ServerResponse } from "http";
import { createReadStream, statSync } from "fs";
import path from "path";
import next from "next";
import { Server as ColyseusServer, LobbyRoom as RoomListRoom } from "colyseus";
import { WebSocketTransport } from "@colyseus/ws-transport";
import { LobbyRoom } from "./lib/hub/LobbyRoom.js";
import { HUB_CONFIG, ROOM_NAME, LIST_ROOM_NAME } from "./lib/hub/config.js";

const dev = process.env.NODE_ENV !== "production";
const port = Number(process.env.PORT || 3000);
const app = next({ dev });
const handle = app.getRequestHandler();

const GODOT_DIR = path.join(process.cwd(), "public", "godot");
// GDExtension 웹 라이브러리 — Godot dlopen 이 res:// 경로 그대로 요청한다.
const ADDONS_DIR = path.join(process.cwd(), "..", "project", "addons");
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

  const versioned = /\bv=[0-9a-f]+/.test((req.url || "").split("?")[1] || "");
  const cacheControl = versioned ? "public, max-age=31536000, immutable" : "no-cache";

  const base = path.join(GODOT_DIR, rel);
  const accept = String(req.headers["accept-encoding"] || "");
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
  createReadStream(file).pipe(res);
  return true;
}

void app.prepare().then(async () => {
  const httpServer = createServer();

  // Next dev HMR(webpack-hmr) 업그레이드는 Next 핸들러로 넘긴다 — 끊으면
  // dev 에서 핫리로드가 죽는다. 그 외 업그레이드는 Colyseus 가 가져간다.
  const nextUpgrade = app.getUpgradeHandler();
  httpServer.on("upgrade", (req, socket, head) => {
    if ((req.url || "").startsWith("/_next")) {void nextUpgrade(req, socket, head);}
  });

  const transport = new WebSocketTransport({ noServer: true, maxPayload: HUB_CONFIG.maxPayload });
  transport.attachToServer(httpServer, {
    filter: (req) => !(req.url || "").startsWith("/_next"),
  });

  const gameServer = new ColyseusServer({
    transport,
    greet: false,
    // Colyseus 라우터(매치메이킹 /matchmake/*)가 못 받는 요청은 여기로 폴백된다.
    express: (expressApp): void => {
      expressApp.use((req: IncomingMessage, res: ServerResponse) => {
        // SharedArrayBuffer(스레드 지원 Godot 웹 빌드) 에 필요한 교차 출처 격리 헤더.
        res.setHeader("cross-origin-opener-policy", "same-origin");
        res.setHeader("cross-origin-embedder-policy", "require-corp");
        res.setHeader("cross-origin-resource-policy", "same-origin");
        const pathname = (req.url || "/").split("?")[0];
        // GDExtension 웹 라이브러리 — Godot dlopen 이 파일명만 요청한다(페이지 루트).
        if (pathname === "/libcolyseus_godot.web.wasm32.release.wasm" &&
            serveAddonsAsset(req, res, "/addons/colyseus/bin/" + pathname.slice(1))) {return;}
        if (pathname.startsWith("/addons/") && serveAddonsAsset(req, res, pathname)) {return;}
        if (pathname.startsWith("/godot/") && serveGodotAsset(req, res, pathname)) {return;}
        void handle(req, res);
      });
    },
  });

  // 게임 방: 생성/변경/소멸이 내장 리스트 룸으로 실시간 전파된다 (공식 리스팅).
  gameServer.define(ROOM_NAME, LobbyRoom).enableRealtimeListing();
  gameServer.define(LIST_ROOM_NAME, RoomListRoom);

  await gameServer.serverless();
  httpServer.listen(port, "0.0.0.0", () => {
    console.log(`> Ready on http://localhost:${port}`);
    console.log(`> Colyseus room: "${ROOM_NAME}" (matchmake: /matchmake/*)`);
  });
});
