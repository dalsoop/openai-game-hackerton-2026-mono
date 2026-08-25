import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import http from "node:http";
import { WebSocket, WebSocketServer } from "ws";
import promClient from "prom-client";
import { CONFIG, ROUTES, MIME_TYPES, Phase } from "./config.js";
import { MAX_PLAYERS, MODES, TICK_HZ } from "./modes.js";
import type { TaggedWebSocket } from "./types.js";
import {
  clients, rooms, allocClientId,
  resumeToken, rateOk, send, clientByWs, livingIds,
  parkClient, broadcastRooms,
} from "./state.js";
import { handleMessage } from "./relay.js";

const PUBLIC_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), "../public");
const SERVER_START = Date.now();

// --- Prometheus ---

const promRegister = new promClient.Registry();
promRegister.setDefaultLabels({ slot: CONFIG.slot });
promClient.collectDefaultMetrics({ register: promRegister });

const gaugeClients = new promClient.Gauge({ name: "gangup_clients_total", help: "Connected clients", registers: [promRegister] });
const gaugeClientsPlaying = new promClient.Gauge({ name: "gangup_clients_playing", help: "Clients in active matches", registers: [promRegister] });
const gaugeRooms = new promClient.Gauge({ name: "gangup_rooms_total", help: "Total rooms", registers: [promRegister] });
const gaugeRoomsPlaying = new promClient.Gauge({ name: "gangup_rooms_playing", help: "Rooms in playing phase", registers: [promRegister] });
const gaugeRoomsLobby = new promClient.Gauge({ name: "gangup_rooms_lobby", help: "Rooms in lobby phase", registers: [promRegister] });
const histRtt = new promClient.Histogram({ name: "gangup_rtt_ms", help: "Player RTT in ms", buckets: [5, 10, 25, 50, 100, 200, 500, 1000], registers: [promRegister] });
const gaugeUptime = new promClient.Gauge({ name: "gangup_uptime_seconds", help: "Server uptime in seconds", registers: [promRegister] });

// --- HTTP Server ---

const server = http.createServer((req, res) => {
  const pathname = new URL(req.url || "/", "http://localhost").pathname;

  if (ROUTES.health.includes(pathname)) {
    res.writeHead(200, { "content-type": "application/json", "access-control-allow-origin": "*", "cache-control": "no-store" });
    res.end(JSON.stringify({ ok: true, slot: CONFIG.slot, rooms: rooms.size, modes: Object.keys(MODES) }));
    return;
  }

  if (ROUTES.metrics.includes(pathname)) {
    promRegister.metrics().then((metrics) => {
      res.writeHead(200, { "content-type": promRegister.contentType, "access-control-allow-origin": "*", "cache-control": "no-store" });
      res.end(metrics);
    });
    return;
  }

  if (ROUTES.status.includes(pathname)) {
    const alive = [...clients.values()].filter((c) => !c.dead);
    const rtts = alive.map((c) => c.rtt).filter((r) => r > 0);
    res.writeHead(200, { "content-type": "application/json", "access-control-allow-origin": "*", "cache-control": "no-store" });
    res.end(JSON.stringify({
      ok: true, slot: CONFIG.slot, uptime: Math.floor((Date.now() - SERVER_START) / 1000), tickHz: TICK_HZ,
      clients: { total: alive.length, playing: alive.filter((c) => rooms.get(c.roomId!)?.phase === Phase.PLAYING).length },
      ping: { avg: rtts.length ? Math.round(rtts.reduce((a, b) => a + b, 0) / rtts.length) : 0, min: rtts.length ? Math.min(...rtts) : 0, max: rtts.length ? Math.max(...rtts) : 0 },
      players: alive.map((c) => ({ id: c.id, name: c.name, rtt: c.rtt, roomId: c.roomId, phase: c.roomId ? rooms.get(c.roomId)?.phase ?? null : null })),
      rooms: [...rooms.values()].map((r) => ({ id: r.id, mode: r.mode, title: r.title, phase: r.phase, playerCount: livingIds(r).length })),
    }));
    return;
  }

  const url = new URL(req.url || "/", "http://localhost");
  const raw = url.pathname.replace(new RegExp(`^${ROUTES.prefix}`), "") || "/";
  const file = raw === "/" ? "/index.html" : raw;
  const full = path.normalize(path.join(PUBLIC_DIR, file));
  if (full !== PUBLIC_DIR && !full.startsWith(PUBLIC_DIR + path.sep)) {
    res.writeHead(403).end();
    return;
  }
  fs.readFile(full, (err, buf) => {
    if (err) {
      res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
      res.end("not found");
      return;
    }
    const ext = path.extname(full);
    const cacheControl = ext === ".html" ? "no-store" : "no-cache";
    res.writeHead(200, {
      "content-type": MIME_TYPES[ext] || "application/octet-stream",
      "cache-control": cacheControl,
    });
    res.end(buf);
  });
});

// --- WebSocket Server ---

const wss = new WebSocketServer({ server, maxPayload: CONFIG.maxPayload });

wss.on("connection", (ws: WebSocket, req) => {
  const sock = req.socket;
  if ("setNoDelay" in sock) (sock as import("node:net").Socket).setNoDelay(true);

  const now = Date.now();
  const client = {
    id: allocClientId(),
    resume: resumeToken(),
    ws,
    name: CONFIG.defaultName,
    mode: CONFIG.defaultMode,
    roomId: null as string | null,
    dead: false,
    deadAt: 0,
    dropTimer: null as ReturnType<typeof setTimeout> | null,
    rtt: 0,
    msgBudget: CONFIG.rateBudget,
    msgRefillAt: now,
  };
  clients.set(client.id, client);
  (ws as TaggedWebSocket)._session = client;
  send(ws, { t: "welcome", id: client.id, resume: client.resume, modes: MODES, max: MAX_PLAYERS });

  ws.on("message", (raw: Buffer) => {
    const session = clientByWs(ws);
    if (!session || !rateOk(session)) return;
    let msg: Record<string, unknown>;
    try { msg = JSON.parse(String(raw)); } catch { return; }
    handleMessage(session, msg);
  });

  ws.on("close", () => {
    const session = clientByWs(ws);
    if (!session || session.ws !== ws) return;
    parkClient(session);
  });

  ws.on("error", () => { /* close follows */ });

  ws.on("pong", (data: Buffer) => {
    const session = clientByWs(ws);
    if (!session || data.length < 8) return;
    session.rtt = Number(Date.now() - Number(data.readBigInt64BE(0)));
    if (session.rtt >= 0) histRtt.observe(session.rtt);
  });
});

// --- Periodic Tasks ---

setInterval(() => {
  const alive = [...clients.values()].filter((c) => !c.dead);
  gaugeClients.set(alive.length);
  gaugeClientsPlaying.set(alive.filter((c) => rooms.get(c.roomId!)?.phase === Phase.PLAYING).length);
  gaugeRooms.set(rooms.size);
  gaugeRoomsPlaying.set([...rooms.values()].filter((r) => r.phase === Phase.PLAYING).length);
  gaugeRoomsLobby.set([...rooms.values()].filter((r) => r.phase === Phase.LOBBY).length);
  gaugeUptime.set(Math.floor((Date.now() - SERVER_START) / 1000));
}, CONFIG.metricsIntervalMs);

setInterval(() => {
  for (const c of clients.values()) {
    if (!c.dead && c.ws.readyState === WebSocket.OPEN) {
      try {
        const pingTs = Buffer.alloc(8);
        pingTs.writeBigInt64BE(BigInt(Date.now()));
        c.ws.ping(pingTs);
      } catch { /* ignore */ }
    }
  }
}, CONFIG.pingIntervalMs);

// --- Start ---

server.listen(CONFIG.port, "0.0.0.0", () => {
  console.log(`[gang-up] web http://127.0.0.1:${CONFIG.port}  ws://127.0.0.1:${CONFIG.port}  max=${MAX_PLAYERS}`);
});
