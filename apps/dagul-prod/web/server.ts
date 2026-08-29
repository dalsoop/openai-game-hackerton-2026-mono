import "./alias-register.js";
import { createServer, type IncomingMessage, type ServerResponse } from "http";
import type { RoomAvailable } from "@colyseus/sdk";
import next from "next";
import { matchMaker, Server as ColyseusServer } from "colyseus";
import { Encoder } from "@colyseus/schema";
import { WebSocketTransport } from "@colyseus/ws-transport";
import { RedisPresence } from "@colyseus/redis-presence";
import { RedisDriver } from "@colyseus/redis-driver";
import { LobbyRoom } from "./lib/hub/LobbyRoom.js";
import { HUB_CONFIG, ROOM_NAME } from "./lib/hub/config.js";
import { hubPublicAddress } from "./lib/hub/public-address.js";
import { roomsHttpBody, withDeadline } from "./lib/hub/rooms-http.js";
import { serveAddonsAsset, serveGodotAsset, servePackAssets, servePageRelativeGodotAssets } from "./lib/godot/asset-server.js";
import { healthBody } from "./lib/hub/health.js";
import { ccuHttpBody } from "./lib/hub/ccu-http.js";
import { ccuMetricsText } from "./lib/hub/ccu-metrics.js";
import { playMetricsText } from "./lib/hub/play-metrics.js";
import { opsMetricsText } from "./lib/hub/ops-metrics.js";
import { revisionBody } from "./lib/hub/revision.js";
import { liveRevisionId } from "./lib/hub/revision-fs.js";
import { redisConn } from "./lib/hub/redis-conn.js";

// 8인 + 총알·이펙트가 몰리면 인코딩 상태가 기본 8KB 버퍼를 넘어 패치 송신이
// 통째로 실패한다(총알 안 보임·월드 정지). 여유 있게 키운다.
Encoder.BUFFER_SIZE = 256 * 1024;

const dev = process.env.NODE_ENV !== "production";
const port = Number(process.env.PORT ?? 3000);

// 슬롯 개명(server-prod → dagul-prod) 뒤에도 와일드카드 인그레스가 옛 호스트를
// 이 앱으로 폴백시킨다. 옛 도메인은 리다이렉트 없이 명확히 죽인다(410 Gone).
function cutRetiredHost(req: IncomingMessage, res: ServerResponse): boolean {
  const host = String(req.headers.host ?? "");
  if (!host.startsWith("server-prod.")) {return false;}
  res.writeHead(410, { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" });
  res.end("gone — https://dagul-prod.external.kr/");
  return true;
}

function jsonOk(res: ServerResponse, body: string): void {
  res.writeHead(200, { "content-type": "application/json", "cache-control": "no-store" });
  res.end(body);
}

function metricsOk(res: ServerResponse, body: string): void {
  res.writeHead(200, {
    "content-type": "text/plain; version=0.0.4; charset=utf-8",
    "cache-control": "no-store",
  });
  res.end(body);
}

function localCcu(): ReturnType<typeof ccuHttpBody> {
  return ccuHttpBody(Number(matchMaker.stats.local.ccu));
}

// /metrics 는 동기 응답이라 방 스냅샷을 TTL 캐시로 유지한다. 갱신 실패 시 마지막 값을 쓴다.
const PLAY_SNAPSHOT_TTL_MS = 5_000;
let playRoomsCache: Array<RoomAvailable & { locked?: boolean }> = [];

function refreshPlaySnapshot(): void {
  void withDeadline(matchMaker.query({ name: ROOM_NAME }), HUB_CONFIG.roomsFetchMs)
    .then((listed) => {playRoomsCache = listed;})
    .catch(() => {/* 캐시 유지 */});
}

setInterval(refreshPlaySnapshot, PLAY_SNAPSHOT_TTL_MS);
void refreshPlaySnapshot();

function serveCcuJson(res: ServerResponse, write: (body: ReturnType<typeof ccuHttpBody>) => void): void {
  const fallback = localCcu();
  void withDeadline(matchMaker.stats.getGlobalCCU(), HUB_CONFIG.roomsFetchMs)
    .then((ccu) => {write(ccuHttpBody(Number(ccu)));})
    .catch(() => {write(fallback);});
}

function setIsolationHeaders(res: ServerResponse): void {
  // SharedArrayBuffer(스레드 지원 Godot 웹 빌드) 에 필요한 교차 출처 격리 헤더.
  res.setHeader("cross-origin-opener-policy", "same-origin");
  res.setHeader("cross-origin-embedder-policy", "require-corp");
  res.setHeader("cross-origin-resource-policy", "same-origin");
}

function serveMeta(pathname: string, res: ServerResponse): boolean {
  if (pathname === "/health" || pathname === "/healthz") {
    jsonOk(res, healthBody(undefined, localCcu()));
    return true;
  }
  if (pathname === "/metrics") {
    metricsOk(res, ccuMetricsText(localCcu()) + playMetricsText(playRoomsCache) + opsMetricsText());
    return true;
  }
  if (pathname === "/ccu" || pathname === "/api/ccu") {
    serveCcuJson(res, (body) => jsonOk(res, JSON.stringify(body)));
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
    if (servePageRelativeGodotAssets(req, res, pathname)) {return;}
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
