import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import http from "node:http";
import crypto from "node:crypto";
import { WebSocket, WebSocketServer } from "ws";
import promClient from "prom-client";
import { MAX_PLAYERS, MODES, TICK_HZ } from "./modes.js";

const PORT = Number(process.env.PORT || 9120);
const PUBLIC_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), "../public");
const TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
};
const GRACE_LOBBY_MS = 20_000;
const GRACE_PLAY_MS = 60_000;
const SERVER_START = Date.now();
const SLOT = process.env.SLOT_FOLDER || "server-fig-dev1";

// --- Prometheus ---

const promRegister = new promClient.Registry();
promRegister.setDefaultLabels({ slot: SLOT });
promClient.collectDefaultMetrics({ register: promRegister });

const gaugeClients = new promClient.Gauge({ name: "gangup_clients_total", help: "Connected clients", registers: [promRegister] });
const gaugeClientsPlaying = new promClient.Gauge({ name: "gangup_clients_playing", help: "Clients in active matches", registers: [promRegister] });
const gaugeRooms = new promClient.Gauge({ name: "gangup_rooms_total", help: "Total rooms", registers: [promRegister] });
const gaugeRoomsPlaying = new promClient.Gauge({ name: "gangup_rooms_playing", help: "Rooms in playing phase", registers: [promRegister] });
const gaugeRoomsLobby = new promClient.Gauge({ name: "gangup_rooms_lobby", help: "Rooms in lobby phase", registers: [promRegister] });
const histRtt = new promClient.Histogram({ name: "gangup_rtt_ms", help: "Player RTT in ms", buckets: [5, 10, 25, 50, 100, 200, 500, 1000], registers: [promRegister] });
const gaugeUptime = new promClient.Gauge({ name: "gangup_uptime_seconds", help: "Server uptime in seconds", registers: [promRegister] });

// --- Types ---

// Fix 6: O(1) ws → client lookup
interface TaggedWebSocket extends WebSocket {
  _session?: Client;
}

interface Client {
  id: string;
  resume: string;
  ws: WebSocket;
  name: string;
  mode: string;
  roomId: string | null;
  dead: boolean;
  deadAt: number;
  dropTimer: ReturnType<typeof setTimeout> | null;
  rtt: number;
  lastChatAt?: number;
  msgBudget: number;    // Fix 5: rate limiter
  msgRefillAt: number;  // Fix 5: rate limiter
}

interface Room {
  id: string;
  mode: string;
  title: string;
  members: string[];
  phase: "lobby" | "playing";
  hostClientId: string | null;
  timer: ReturnType<typeof setTimeout> | null;
  lastSnap: Record<string, unknown> | null;
}

// --- State ---

let nextId = 1;
let nextRoom = 1;
const clients = new Map<string, Client>();
const rooms = new Map<string, Room>();

// --- Helpers ---

function resumeToken(): string {
  return crypto.randomBytes(16).toString("hex");
}

// Fix 2 (server-side): sanitize user-provided text
const sanitize = (s: unknown, max: number): string =>
  String(s || "").replace(/[<>&"'`]/g, "").trim().slice(0, max);

// Fix 5: token bucket rate limiter (40/s refill, 60 burst)
function rateOk(c: Client): boolean {
  const now = Date.now();
  c.msgBudget = Math.min(60, c.msgBudget + (now - c.msgRefillAt) * 0.04);
  c.msgRefillAt = now;
  if (c.msgBudget < 1) return false;
  c.msgBudget -= 1;
  return true;
}

function send(ws: WebSocket | null, msg: unknown): void {
  if (!ws || ws.readyState !== WebSocket.OPEN) return;
  try {
    ws.send(typeof msg === "string" ? msg : JSON.stringify(msg));
  } catch {
    /* ignore broken sockets */
  }
}

function sendTo(id: string, msg: unknown): void {
  const c = clients.get(id);
  if (c && !c.dead) send(c.ws, msg);
}

function sendRoom(room: Room, msg: unknown): void {
  const text = JSON.stringify(msg);
  for (const id of livingIds(room)) sendTo(id, text);
}

// Fix 6: O(1) lookup instead of linear scan
function clientByWs(ws: WebSocket): Client | null {
  return (ws as TaggedWebSocket)._session ?? null;
}

function livingIds(room: Room): string[] {
  return room.members.filter((id) => {
    const c = clients.get(id);
    return c && !c.dead;
  });
}

function hostId(room: Room): string {
  return livingIds(room)[0] ?? room.members[0]!;
}

// Slot = stable index in members array (relay mode — no server-side match object)
function slotOf(_room: Room, clientId: string): number {
  return _room.members.indexOf(clientId);
}

function roomPublic(room: Room) {
  return {
    id: room.id,
    mode: room.mode,
    title: room.title,
    count: livingIds(room).length,
    max: MAX_PLAYERS,
    phase: room.phase,
  };
}

function peersPayload(room: Room) {
  return room.members.map((id, i) => {
    const c = clients.get(id);
    return {
      slot: i,
      id,
      name: c?.name ?? "?",
      host: id === hostId(room),
      dropped: Boolean(c?.dead),
    };
  });
}

function notifyRoom(room: Room, extra?: Record<string, unknown>): void {
  sendRoom(room, { t: "peers", players: peersPayload(room), room: roomPublic(room), ...extra });
}

function broadcastRooms(): void {
  const list = [...rooms.values()].filter((r) => r.phase === "lobby").map(roomPublic);
  const text = JSON.stringify({ t: "rooms", rooms: list });
  for (const c of clients.values()) {
    if (!c.dead) send(c.ws, text);
  }
}

// In relay mode the host client manages player state — server only tracks membership
function parkPlayer(_room: Room, _clientId: string): void {
  // Notify host that a player parked (host handles CPU takeover)
  if (_room.hostClientId) {
    sendTo(_room.hostClientId, { t: "peer_parked", slot: _room.members.indexOf(_clientId) });
  }
}

function reclaimPlayer(_room: Room, _clientId: string, _name: string): void {
  if (_room.hostClientId) {
    sendTo(_room.hostClientId, { t: "peer_reclaimed", slot: _room.members.indexOf(_clientId), name: _name });
  }
}

function dropClient(client: Client): void {
  if (client.dropTimer) {
    clearTimeout(client.dropTimer);
    client.dropTimer = null;
  }
  leaveRoom(client, { silent: false });
  clients.delete(client.id);
}

function parkClient(client: Client): void {
  if (!client.roomId) {
    clients.delete(client.id);
    return;
  }
  const room = rooms.get(client.roomId);
  if (!room) {
    clients.delete(client.id);
    return;
  }
  if (client.dead) return;
  client.dead = true;
  client.deadAt = Date.now();
  // If the host disconnects during play, end the match for everyone
  if (room.phase === "playing" && room.hostClientId === client.id) {
    notifyRoom(room, { notice: `호스트(${client.name})의 연결이 끊겨 게임이 종료됩니다.` });
    resetToLobby(room);
    return;
  }
  parkPlayer(room, client.id);
  const grace = room.phase === "playing" ? GRACE_PLAY_MS : GRACE_LOBBY_MS;
  client.dropTimer = setTimeout(() => dropClient(client), grace);
  notifyRoom(room, { notice: `${client.name} 연결이 끊겼습니다. ${Math.round(grace / 1000)}초 안에 다시 들어오면 자리가 유지됩니다.` });
  broadcastRooms();
}

function leaveRoom(client: Client, { silent }: { silent?: boolean } = {}): void {
  if (client.dropTimer) {
    clearTimeout(client.dropTimer);
    client.dropTimer = null;
  }
  const wasDead = client.dead;
  if (!client.roomId) {
    // Fix 4: clean up orphaned dead clients
    if (wasDead || client.ws.readyState !== WebSocket.OPEN) clients.delete(client.id);
    return;
  }
  const room = rooms.get(client.roomId);
  client.roomId = null;
  client.dead = false;
  if (!room) {
    if (wasDead || client.ws.readyState !== WebSocket.OPEN) clients.delete(client.id);
    return;
  }
  room.members = room.members.filter((id) => id !== client.id);
  parkPlayer(room, client.id);
  if (room.members.length === 0) {
    if (room.timer) clearTimeout(room.timer);
    rooms.delete(room.id);
  } else if (!silent) {
    notifyRoom(room, { notice: `${client.name} 이(가) 나갔습니다.` });
  }
  // Fix 4: delete dead/disconnected clients after leaving room
  if (wasDead || client.ws.readyState !== WebSocket.OPEN) clients.delete(client.id);
  broadcastRooms();
}

function attachResume(fresh: Client, token: string): Client {
  for (const old of clients.values()) {
    if (old.id === fresh.id || old.resume !== token) continue;
    if (old.dropTimer) {
      clearTimeout(old.dropTimer);
      old.dropTimer = null;
    }
    const staleWs = old.ws;
    old.ws = fresh.ws;
    old.dead = false;
    old.deadAt = 0;
    // Fix 6: update ws → client binding on socket handover
    (fresh.ws as TaggedWebSocket)._session = old;
    old.resume = fresh.resume; // sync token so next reconnect works
    clients.delete(fresh.id);
    try {
      if (staleWs && staleWs !== fresh.ws) staleWs.terminate();
    } catch {
      /* ignore */
    }
    const room = old.roomId ? rooms.get(old.roomId) : null;
    if (room) {
      reclaimPlayer(room, old.id, old.name);
      const playing = room.phase === "playing";
      send(old.ws, {
        t: "resume",
        id: old.id,
        resume: old.resume,
        you: slotOf(room, old.id), // Fix 3: use canonical slot
        room: roomPublic(room),
        players: peersPayload(room),
        playing: Boolean(playing),
        snap: playing ? room.lastSnap : null,
      });
      notifyRoom(room, { notice: `${old.name} 이(가) 다시 연결되었습니다.` });
    } else {
      send(old.ws, { t: "welcome", id: old.id, resume: old.resume, modes: MODES, max: MAX_PLAYERS });
      broadcastRooms();
    }
    return old;
  }
  return fresh;
}

// Reset room to lobby — called when host disconnects or game ends
function resetToLobby(room: Room): void {
  room.hostClientId = null;
  room.timer = null;
  room.lastSnap = null;
  room.phase = "lobby";
  if (livingIds(room).length === 0) {
    rooms.delete(room.id);
    broadcastRooms();
    return;
  }
  sendRoom(room, { t: "lobby" });
  notifyRoom(room, { notice: "게임이 끝났습니다. 대기실로 돌아왔습니다." });
  broadcastRooms();
}

function startMatch(room: Room): void {
  if (room.phase !== "lobby") return;
  room.phase = "playing";
  room.hostClientId = hostId(room);
  for (const id of room.members) {
    const c = clients.get(id);
    if (c?.dead) {
      parkPlayer(room, id);
    } else {
      const slot = room.members.indexOf(id);
      const isHost = id === room.hostClientId;
      sendTo(id, { t: "start", you: slot, host: isHost, room: roomPublic(room) });
    }
  }
  broadcastRooms();
}

// --- HTTP Server ---

const server = http.createServer((req, res) => {
  const pathname = new URL(req.url || "/", "http://localhost").pathname;

  if (pathname === "/health" || pathname === "/gang-up/health") {
    res.writeHead(200, {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
    });
    res.end(JSON.stringify({
      ok: true,
      slot: process.env.SLOT_FOLDER || "",
      rooms: rooms.size,
      modes: Object.keys(MODES),
    }));
    return;
  }

  if (pathname === "/metrics" || pathname === "/gang-up/metrics") {
    promRegister.metrics().then((metrics) => {
      res.writeHead(200, { "content-type": promRegister.contentType, "access-control-allow-origin": "*", "cache-control": "no-store" });
      res.end(metrics);
    });
    return;
  }

  if (pathname === "/status" || pathname === "/gang-up/status") {
    const alive = [...clients.values()].filter((c) => !c.dead);
    const rtts = alive.map((c) => c.rtt).filter((r) => r > 0);
    res.writeHead(200, { "content-type": "application/json", "access-control-allow-origin": "*", "cache-control": "no-store" });
    res.end(JSON.stringify({
      ok: true, slot: SLOT, uptime: Math.floor((Date.now() - SERVER_START) / 1000), tickHz: TICK_HZ,
      clients: { total: alive.length, playing: alive.filter((c) => rooms.get(c.roomId!)?.phase === "playing").length },
      ping: { avg: rtts.length ? Math.round(rtts.reduce((a, b) => a + b, 0) / rtts.length) : 0, min: rtts.length ? Math.min(...rtts) : 0, max: rtts.length ? Math.max(...rtts) : 0 },
      players: alive.map((c) => ({ id: c.id, name: c.name, rtt: c.rtt, roomId: c.roomId, phase: c.roomId ? rooms.get(c.roomId)?.phase ?? null : null })),
      rooms: [...rooms.values()].map((r) => ({ id: r.id, mode: r.mode, title: r.title, phase: r.phase, playerCount: livingIds(r).length })),
    }));
    return;
  }

  // Static file serving
  const url = new URL(req.url || "/", "http://localhost");
  const raw = url.pathname.replace(/^\/gang-up/, "") || "/";
  const file = raw === "/" ? "/index.html" : raw;
  const full = path.normalize(path.join(PUBLIC_DIR, file));
  // Fix 11: include path separator in prefix check
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
    res.writeHead(200, { "content-type": TYPES[path.extname(full)] || "application/octet-stream" });
    res.end(buf);
  });
});

// --- WebSocket Server ---

// maxPayload: 64KB allows host_snap relay; regular client messages are much smaller
const wss = new WebSocketServer({ server, maxPayload: 65_536 });

wss.on("connection", (ws: WebSocket, req) => {
  // TCP_NODELAY: disable Nagle's algorithm for minimal latency
  const sock = req.socket;
  if ("setNoDelay" in sock) (sock as import("node:net").Socket).setNoDelay(true);
  const now = Date.now();
  const client: Client = {
    id: `p${nextId++}`,
    resume: resumeToken(),
    ws,
    name: "손님",
    mode: "classic",
    roomId: null,
    dead: false,
    deadAt: 0,
    dropTimer: null,
    rtt: 0,
    msgBudget: 60,
    msgRefillAt: now,
  };
  clients.set(client.id, client);
  // Fix 6: bind ws → client
  (ws as TaggedWebSocket)._session = client;
  send(ws, { t: "welcome", id: client.id, resume: client.resume, modes: MODES, max: MAX_PLAYERS });

  ws.on("message", (raw: Buffer) => {
    const session = clientByWs(ws);
    if (!session) return;
    // Fix 5: rate limiting
    if (!rateOk(session)) return;
    let msg: Record<string, unknown>;
    try {
      msg = JSON.parse(String(raw));
    } catch {
      return;
    }
    handleMessage(session, msg);
  });

  ws.on("close", () => {
    const session = clientByWs(ws);
    if (!session) return;
    if (session.ws !== ws) return;
    parkClient(session);
  });

  ws.on("error", () => {
    /* close follows */
  });

  // Fix 9: observe RTT exactly once per pong (not in the 5s metrics loop)
  ws.on("pong", (data: Buffer) => {
    const session = clientByWs(ws);
    if (!session || data.length < 8) return;
    session.rtt = Number(Date.now() - Number(data.readBigInt64BE(0)));
    if (session.rtt >= 0) histRtt.observe(session.rtt);
  });
});

// --- Message Handler ---

function handleMessage(client: Client, msg: Record<string, unknown>): void {
  const t = msg.t;

  if (t === "ping") {
    send(client.ws, { t: "pong", ts: msg.ts });
    return;
  }

  if (t === "hello") {
    const token = String(msg.resume || "");
    if (/^[a-f0-9]{32}$/.test(token)) {
      const adopted = attachResume(client, token);
      if (adopted !== client) {
        adopted.name = sanitize(msg.name, 12) || adopted.name; // Fix 2
        adopted.mode = MODES[String(msg.mode)] ? String(msg.mode) : adopted.mode;
        broadcastRooms();
        return;
      }
      if (msg.wantResume && token !== client.resume) {
        send(client.ws, { t: "dropped", msg: "이전 자리를 찾지 못했습니다. 로비로 갑니다.", resume: client.resume });
      }
    }
    client.name = sanitize(msg.name, 12) || "손님"; // Fix 2
    client.mode = MODES[String(msg.mode)] ? String(msg.mode) : "classic";
    broadcastRooms();
    return;
  }

  if (t === "rooms") {
    broadcastRooms();
    return;
  }

  if (t === "create") {
    if (client.roomId) leaveRoom(client);
    const id = `r${nextRoom++}`;
    const mode = MODES[client.mode] ? client.mode : "classic";
    const room: Room = {
      id,
      mode,
      title: sanitize(msg.title, 24) || `${MODES[mode]!.title} #${id}`, // Fix 2
      members: [client.id],
      phase: "lobby",
      hostClientId: null,
      timer: null,
      lastSnap: null,
    };
    rooms.set(id, room);
    client.roomId = id;
    send(client.ws, { t: "joined", you: 0, room: roomPublic(room), players: peersPayload(room) });
    broadcastRooms();
    return;
  }

  if (t === "join") {
    const room = rooms.get(String(msg.roomId));
    if (!room || room.phase !== "lobby") { send(client.ws, { t: "error", msg: "방을 찾을 수 없습니다" }); return; }
    client.mode = room.mode;
    if (room.members.length >= MAX_PLAYERS) { send(client.ws, { t: "error", msg: "방이 가득 찼습니다 (8)" }); return; }
    if (client.roomId) leaveRoom(client);
    room.members.push(client.id);
    client.roomId = room.id;
    send(client.ws, {
      t: "joined",
      you: room.members.indexOf(client.id),
      room: roomPublic(room),
      players: peersPayload(room),
    });
    notifyRoom(room, { notice: `${client.name} 이(가) 들어왔습니다.` });
    broadcastRooms();
    return;
  }

  if (t === "mode") {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== "lobby") { send(client.ws, { t: "error", msg: "지금은 게임을 바꿀 수 없습니다" }); return; }
    if (hostId(room) !== client.id) { send(client.ws, { t: "error", msg: "호스트만 게임을 바꿀 수 있습니다" }); return; }
    const next = MODES[String(msg.mode)] ? String(msg.mode) : room.mode;
    room.mode = next;
    for (const id of room.members) {
      const c = clients.get(id);
      if (c) c.mode = next;
    }
    notifyRoom(room);
    broadcastRooms();
    return;
  }

  if (t === "leave") {
    leaveRoom(client);
    send(client.ws, { t: "left" });
    return;
  }

  if (t === "start") {
    const room = rooms.get(client.roomId!);
    if (!room || hostId(room) !== client.id) { send(client.ws, { t: "error", msg: "호스트만 시작할 수 있습니다" }); return; }
    startMatch(room);
    return;
  }

  if (t === "kick") {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== "lobby") { send(client.ws, { t: "error", msg: "지금은 내보낼 수 없습니다" }); return; }
    if (hostId(room) !== client.id) { send(client.ws, { t: "error", msg: "호스트만 내보낼 수 있습니다" }); return; }
    const slot = Number(msg.slot);
    const targetId = room.members[slot];
    if (!targetId || targetId === client.id) return;
    const target = clients.get(targetId);
    if (!target) return;
    leaveRoom(target, { silent: true });
    send(target.ws, { t: "kicked", msg: "호스트가 방에서 내보냈습니다." });
    notifyRoom(room, { notice: `${target.name} 이(가) 내보내졌습니다.` });
    return;
  }

  if (t === "chat") {
    const room = rooms.get(client.roomId!);
    if (!room) return;
    const text = String(msg.text || "").replace(/\s+/g, " ").trim().slice(0, 120);
    if (!text) return;
    const now = Date.now();
    if (client.lastChatAt && now - client.lastChatAt < 400) return;
    client.lastChatAt = now;
    sendRoom(room, { t: "chat", from: client.name, slot: slotOf(room, client.id), text }); // Fix 3
    return;
  }

  // Relay mode: forward inputs from non-host to host
  if (t === "input") {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== "playing" || client.dead) return;
    if (client.id === room.hostClientId) return; // host handles own input locally
    const slot = room.members.indexOf(client.id);
    if (slot < 0) return;
    sendTo(room.hostClientId!, {
      t: "peer_input",
      slot,
      mx: msg.mx, my: msg.my,
      fire: msg.fire, dash: msg.dash, use: msg.use,
      aimX: msg.aimX, aimY: msg.aimY,
      seq: msg.seq,
    });
    return;
  }

  // Relay mode: host broadcasts snapshot to all other clients
  if (t === "host_snap") {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== "playing") return;
    if (client.id !== room.hostClientId) return; // only host can send snapshots
    const snapData = msg as Record<string, unknown>;
    snapData.t = "snap";
    room.lastSnap = snapData;
    const text = JSON.stringify(snapData);
    for (const id of livingIds(room)) {
      if (id !== client.id) sendTo(id, text); // don't echo back to host
    }
    // Check for match end — host signals result in the snapshot
    if (snapData.result && snapData.result !== "playing") {
      room.timer = setTimeout(() => resetToLobby(room), 5_000);
    }
    return;
  }
}

// --- Periodic Tasks ---

// Fix 9: metrics loop WITHOUT histRtt.observe (moved to pong handler)
setInterval(() => {
  const alive = [...clients.values()].filter((c) => !c.dead);
  gaugeClients.set(alive.length);
  gaugeClientsPlaying.set(alive.filter((c) => rooms.get(c.roomId!)?.phase === "playing").length);
  gaugeRooms.set(rooms.size);
  gaugeRoomsPlaying.set([...rooms.values()].filter((r) => r.phase === "playing").length);
  gaugeRoomsLobby.set([...rooms.values()].filter((r) => r.phase === "lobby").length);
  gaugeUptime.set(Math.floor((Date.now() - SERVER_START) / 1000));
}, 5_000);

setInterval(() => {
  for (const c of clients.values()) {
    if (!c.dead && c.ws.readyState === WebSocket.OPEN) {
      try {
        const pingTs = Buffer.alloc(8);
        pingTs.writeBigInt64BE(BigInt(Date.now()));
        c.ws.ping(pingTs);
      } catch {
        /* ignore */
      }
    }
  }
}, 10_000);

// --- Start ---

server.listen(PORT, "0.0.0.0", () => {
  console.log(`[gang-up] web http://127.0.0.1:${PORT}  ws://127.0.0.1:${PORT}  max=${MAX_PLAYERS}`);
});
