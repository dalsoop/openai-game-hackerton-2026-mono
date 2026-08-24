import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import http from "node:http";
import crypto from "node:crypto";
import { WebSocket, WebSocketServer } from "ws";
import promClient from "prom-client";
import { MAX_PLAYERS, MODES, TICK_HZ } from "./modes.js";

// --- Configuration ---

const CONFIG = {
  port: Number(process.env.PORT || 9120),
  slot: process.env.SLOT_FOLDER || "server-prod",
  graceLobbyMs: 20_000,
  gracePlayMs: 60_000,
  maxPayload: 64 * 1024,
  defaultName: "손님",
  defaultMode: "classic",
  maxNameLength: 12,
  maxTitleLength: 24,
  maxChatLength: 120,
  chatCooldownMs: 400,
  rateBudget: 60,
  rateRefillPerMs: 0.04,
  snapDeltaLogInterval: 100,
  resetToLobbyDelayMs: 5_000,
  pingIntervalMs: 10_000,
  metricsIntervalMs: 5_000,
} as const;

const Phase = { LOBBY: "lobby", PLAYING: "playing" } as const;
type Phase = (typeof Phase)[keyof typeof Phase];

const MSG = {
  WELCOME: "welcome", HELLO: "hello", ROOMS: "rooms", CREATE: "create",
  JOIN: "join", LEAVE: "leave", START: "start", KICK: "kick", CHAT: "chat",
  INPUT: "input", HOST_SNAP: "host_snap", SNAP: "snap",
  PEER_INPUT: "peer_input", PEER_PARKED: "peer_parked", PEER_RECLAIMED: "peer_reclaimed",
  JOINED: "joined", PEERS: "peers", LEFT: "left", KICKED: "kicked",
  LOBBY: "lobby", ERROR: "error", PING: "ping", PONG: "pong",
  DROPPED: "dropped", RESUME: "resume", MODE: "mode",
} as const;

const ROUTES = {
  health: ["/health", "/gang-up/health"] as readonly string[],
  metrics: ["/metrics", "/gang-up/metrics"] as readonly string[],
  status: ["/status", "/gang-up/status"] as readonly string[],
  prefix: "/gang-up",
} as const;

const MIME_TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
};

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
  phase: Phase;
  hostClientId: string | null;
  timer: ReturnType<typeof setTimeout> | null;
  lastSnap: Record<string, unknown> | null;
  prevSnap: Record<string, unknown> | null;
  snapCount: number;
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

function rateOk(c: Client): boolean {
  const now = Date.now();
  c.msgBudget = Math.min(CONFIG.rateBudget, c.msgBudget + (now - c.msgRefillAt) * CONFIG.rateRefillPerMs);
  c.msgRefillAt = now;
  if (c.msgBudget < 1) return false;
  c.msgBudget -= 1;
  return true;
}

// Snapshot delta: compare hero arrays field-by-field, keep arrays that change wholesale
function computeHeroDelta(
  prev: Record<string, unknown>,
  next: Record<string, unknown>,
): Record<string, unknown> {
  const delta: Record<string, unknown> = { t: "snap", tick: next.tick, full: false };
  const skipKeys = new Set(["t", "heroes"]);
  const arrayKeys = new Set(["projectiles", "zones", "effects", "knockouts", "covers",
    "health_pickups", "crates", "crate_orbs", "deployables", "cores"]);
  for (const key of Object.keys(next)) {
    if (skipKeys.has(key)) continue;
    if (arrayKeys.has(key)) {
      delta[key] = next[key]; // arrays always sent in full
      continue;
    }
    if (JSON.stringify(prev[key]) !== JSON.stringify(next[key])) {
      delta[key] = next[key];
    }
  }
  // Heroes: per-slot diff
  const prevH = (prev.heroes ?? []) as Record<string, unknown>[];
  const nextH = (next.heroes ?? []) as Record<string, unknown>[];
  const deltaHeroes: Record<string, unknown>[] = [];
  for (const nh of nextH) {
    const slot = nh.slot as number;
    const ph = prevH.find((h) => h.slot === slot);
    if (!ph) { deltaHeroes.push(nh); continue; }
    const diff: Record<string, unknown> = { slot };
    for (const k of Object.keys(nh)) {
      if (k === "slot") continue;
      if (JSON.stringify(ph[k]) !== JSON.stringify(nh[k])) diff[k] = nh[k];
    }
    deltaHeroes.push(Object.keys(diff).length > 1 ? diff : { slot });
  }
  delta.heroes = deltaHeroes;
  return delta;
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
    if (!id) return false; // vacant slot (C1: stable indices during play)
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
    if (!id) return { slot: i, id: "", name: "", host: false, dropped: true, vacant: true };
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
  sendRoom(room, { t: MSG.PEERS, players: peersPayload(room), room: roomPublic(room), ...extra });
}

function broadcastRooms(): void {
  const list = [...rooms.values()].filter((r) => r.phase === Phase.LOBBY).map(roomPublic);
  const text = JSON.stringify({ t: MSG.ROOMS, rooms: list });
  for (const c of clients.values()) {
    if (!c.dead) send(c.ws, text);
  }
}

// In relay mode the host client manages player state — server only tracks membership
function parkPlayer(_room: Room, _clientId: string): void {
  // Notify host that a player parked (host handles CPU takeover)
  if (_room.hostClientId) {
    sendTo(_room.hostClientId, { t: MSG.PEER_PARKED, slot: _room.members.indexOf(_clientId) });
  }
}

function reclaimPlayer(_room: Room, _clientId: string, _name: string): void {
  if (_room.hostClientId) {
    sendTo(_room.hostClientId, { t: MSG.PEER_RECLAIMED, slot: _room.members.indexOf(_clientId), name: _name });
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
  if (room.phase === Phase.PLAYING && room.hostClientId === client.id) {
    notifyRoom(room, { notice: `호스트(${client.name})의 연결이 끊겨 게임이 종료됩니다.` });
    resetToLobby(room);
    return;
  }
  parkPlayer(room, client.id);
  const grace = room.phase === Phase.PLAYING ? CONFIG.gracePlayMs : CONFIG.graceLobbyMs;
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
  // NEW-H1 fix: parkPlayer before vacating so indexOf still finds the slot
  parkPlayer(room, client.id);
  // C1: during PLAYING, mark slot vacant instead of splicing to preserve index stability
  if (room.phase === Phase.PLAYING) {
    const idx = room.members.indexOf(client.id);
    if (idx >= 0) room.members[idx] = "";
  } else {
    room.members = room.members.filter((id) => id !== client.id);
  }
  // C2: if the leaving player is the host during play, end the match
  if (room.phase === Phase.PLAYING && client.id === room.hostClientId) {
    if (!silent) notifyRoom(room, { notice: `호스트(${client.name})가 나가서 게임이 종료됩니다.` });
    resetToLobby(room);
  } else if (room.members.every((id) => !id) || (room.phase === Phase.LOBBY && room.members.length === 0)) {
    // All slots vacant or lobby empty — delete room
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
      const playing = room.phase === Phase.PLAYING;
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
      send(old.ws, { t: MSG.WELCOME, id: old.id, resume: old.resume, modes: MODES, max: MAX_PLAYERS });
      broadcastRooms();
    }
    return old;
  }
  return fresh;
}

// Reset room to lobby — called when host disconnects or game ends
function resetToLobby(room: Room): void {
  if (room.timer) { clearTimeout(room.timer); room.timer = null; } // M1: clear before resetting
  room.hostClientId = null;
  room.lastSnap = null;
  room.prevSnap = null;
  room.snapCount = 0;
  // C1: remove vacant slots when returning to lobby
  room.members = room.members.filter((id) => !!id);
  room.phase = Phase.LOBBY;
  if (livingIds(room).length === 0) {
    rooms.delete(room.id);
    broadcastRooms();
    return;
  }
  sendRoom(room, { t: MSG.LOBBY });
  notifyRoom(room, { notice: "게임이 끝났습니다. 대기실로 돌아왔습니다." });
  broadcastRooms();
}

function startMatch(room: Room): void {
  if (room.phase !== Phase.LOBBY) return;
  room.phase = Phase.PLAYING;
  room.hostClientId = hostId(room);
  for (const id of room.members) {
    const c = clients.get(id);
    if (c?.dead) {
      parkPlayer(room, id);
    } else {
      const slot = room.members.indexOf(id);
      const isHost = id === room.hostClientId;
      sendTo(id, { t: MSG.START, you: slot, host: isHost, room: roomPublic(room) });
    }
  }
  // H1: if host doesn't send first snapshot within timeout, reset to lobby
  room.timer = setTimeout(() => {
    if (room.phase === Phase.PLAYING && !room.lastSnap) {
      sendRoom(room, { t: MSG.ERROR, msg: "호스트가 게임을 시작하지 못했습니다." });
      resetToLobby(room);
    }
  }, CONFIG.resetToLobbyDelayMs);
  broadcastRooms();
}

// --- HTTP Server ---

const server = http.createServer((req, res) => {
  const pathname = new URL(req.url || "/", "http://localhost").pathname;

  if (ROUTES.health.includes(pathname)) {
    res.writeHead(200, {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
    });
    res.end(JSON.stringify({
      ok: true,
      slot: CONFIG.slot,
      rooms: rooms.size,
      modes: Object.keys(MODES),
    }));
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

  // Static file serving
  const url = new URL(req.url || "/", "http://localhost");
  const raw = url.pathname.replace(new RegExp(`^${ROUTES.prefix}`), "") || "/";
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
    res.writeHead(200, { "content-type": MIME_TYPES[path.extname(full)] || "application/octet-stream" });
    res.end(buf);
  });
});

// --- WebSocket Server ---

const wss = new WebSocketServer({ server, maxPayload: CONFIG.maxPayload });

wss.on("connection", (ws: WebSocket, req) => {
  // TCP_NODELAY: disable Nagle's algorithm for minimal latency
  const sock = req.socket;
  if ("setNoDelay" in sock) (sock as import("node:net").Socket).setNoDelay(true);
  const now = Date.now();
  const client: Client = {
    id: `p${nextId++}`,
    resume: resumeToken(),
    ws,
    name: CONFIG.defaultName,
    mode: CONFIG.defaultMode,
    roomId: null,
    dead: false,
    deadAt: 0,
    dropTimer: null,
    rtt: 0,
    msgBudget: CONFIG.rateBudget,
    msgRefillAt: now,
  };
  clients.set(client.id, client);
  // Fix 6: bind ws → client
  (ws as TaggedWebSocket)._session = client;
  send(ws, { t: MSG.WELCOME, id: client.id, resume: client.resume, modes: MODES, max: MAX_PLAYERS });

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

  if (t === MSG.PING) {
    send(client.ws, { t: MSG.PONG, ts: msg.ts });
    return;
  }

  if (t === MSG.HELLO) {
    const token = String(msg.resume || "");
    if (/^[a-f0-9]{32}$/.test(token)) {
      const adopted = attachResume(client, token);
      if (adopted !== client) {
        adopted.name = sanitize(msg.name, CONFIG.maxNameLength) || adopted.name;
        adopted.mode = MODES[String(msg.mode)] ? String(msg.mode) : adopted.mode;
        broadcastRooms();
        return;
      }
      if (msg.wantResume && token !== client.resume) {
        send(client.ws, { t: MSG.DROPPED, msg: "이전 자리를 찾지 못했습니다. 로비로 갑니다.", resume: client.resume });
      }
    }
    client.name = sanitize(msg.name, CONFIG.maxNameLength) || CONFIG.defaultName;
    client.mode = MODES[String(msg.mode)] ? String(msg.mode) : CONFIG.defaultMode;
    broadcastRooms();
    return;
  }

  if (t === MSG.ROOMS) {
    broadcastRooms();
    return;
  }

  if (t === MSG.CREATE) {
    if (client.roomId) leaveRoom(client);
    const id = `r${nextRoom++}`;
    const mode = MODES[client.mode] ? client.mode : CONFIG.defaultMode;
    const room: Room = {
      id,
      mode,
      title: sanitize(msg.title, CONFIG.maxTitleLength) || `${MODES[mode]!.title} #${id}`,
      members: [client.id],
      phase: Phase.LOBBY,
      hostClientId: null,
      timer: null,
      lastSnap: null,
      prevSnap: null,
      snapCount: 0,
    };
    rooms.set(id, room);
    client.roomId = id;
    send(client.ws, { t: MSG.JOINED, you: 0, room: roomPublic(room), players: peersPayload(room) });
    broadcastRooms();
    return;
  }

  if (t === MSG.JOIN) {
    const room = rooms.get(String(msg.roomId));
    if (!room || room.phase !== Phase.LOBBY) { send(client.ws, { t: MSG.ERROR, msg: "방을 찾을 수 없습니다" }); return; }
    client.mode = room.mode;
    if (room.members.length >= MAX_PLAYERS) { send(client.ws, { t: MSG.ERROR, msg: "방이 가득 찼습니다 (8)" }); return; }
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

  if (t === MSG.MODE) {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== Phase.LOBBY) { send(client.ws, { t: MSG.ERROR, msg: "지금은 게임을 바꿀 수 없습니다" }); return; }
    if (hostId(room) !== client.id) { send(client.ws, { t: MSG.ERROR, msg: "호스트만 게임을 바꿀 수 있습니다" }); return; }
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

  if (t === MSG.LEAVE) {
    leaveRoom(client);
    send(client.ws, { t: MSG.LEFT });
    return;
  }

  if (t === MSG.START) {
    const room = rooms.get(client.roomId!);
    if (!room || hostId(room) !== client.id) { send(client.ws, { t: MSG.ERROR, msg: "호스트만 시작할 수 있습니다" }); return; }
    startMatch(room);
    return;
  }

  if (t === MSG.KICK) {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== Phase.LOBBY) { send(client.ws, { t: MSG.ERROR, msg: "지금은 내보낼 수 없습니다" }); return; }
    if (hostId(room) !== client.id) { send(client.ws, { t: MSG.ERROR, msg: "호스트만 내보낼 수 있습니다" }); return; }
    const slot = Number(msg.slot);
    const targetId = room.members[slot];
    if (!targetId || targetId === client.id) return;
    const target = clients.get(targetId);
    if (!target) return;
    leaveRoom(target, { silent: true });
    send(target.ws, { t: MSG.KICKED, msg: "호스트가 방에서 내보냈습니다." });
    notifyRoom(room, { notice: `${target.name} 이(가) 내보내졌습니다.` });
    return;
  }

  if (t === MSG.CHAT) {
    const room = rooms.get(client.roomId!);
    if (!room) return;
    const text = String(msg.text || "").replace(/\s+/g, " ").trim().slice(0, CONFIG.maxChatLength);
    if (!text) return;
    const now = Date.now();
    if (client.lastChatAt && now - client.lastChatAt < CONFIG.chatCooldownMs) return;
    client.lastChatAt = now;
    sendRoom(room, { t: MSG.CHAT, from: client.name, slot: slotOf(room, client.id), text }); // Fix 3
    return;
  }

  // Relay mode: forward inputs from non-host to host
  if (t === MSG.INPUT) {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== Phase.PLAYING || client.dead) return;
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
  if (t === MSG.HOST_SNAP) {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== Phase.PLAYING) return;
    if (client.id !== room.hostClientId) return; // only host can send snapshots
    const snapData = msg as Record<string, unknown>;
    snapData.t = MSG.SNAP;
    room.prevSnap = room.lastSnap;
    room.lastSnap = snapData;
    room.snapCount += 1;
    const text = JSON.stringify(snapData);
    // Delta measurement (log every 100 snaps)
    if (room.prevSnap && room.snapCount % CONFIG.snapDeltaLogInterval === 0) {
      const delta = computeHeroDelta(room.prevSnap, snapData);
      const deltaSize = JSON.stringify(delta).length;
      const fullSize = text.length;
      const pct = Math.round((1 - deltaSize / fullSize) * 100);
      console.log(`[snap-delta] room=${room.id} full=${fullSize}B delta=${deltaSize}B saving=${pct}%`);
    }
    for (const id of livingIds(room)) {
      if (id !== client.id) sendTo(id, text); // don't echo back to host
    }
    // Check for match end — host signals result in the snapshot
    const isEnded = snapData.result && snapData.result !== Phase.PLAYING;
    if (isEnded) {
      if (!room.prevSnap || room.prevSnap["result"] === Phase.PLAYING) {
        // First end snap: clear any existing timer (H1 startup), set reset timer
        if (room.timer) { clearTimeout(room.timer); room.timer = null; }
        room.timer = setTimeout(() => resetToLobby(room), CONFIG.resetToLobbyDelayMs);
      }
      // Subsequent end snaps: keep existing reset timer
    } else if (snapData.result === Phase.PLAYING && room.timer) {
      // First valid snap arrived — clear the H1 startup timeout
      clearTimeout(room.timer);
      room.timer = null;
    }
    return;
  }
}

// --- Periodic Tasks ---

// Fix 9: metrics loop WITHOUT histRtt.observe (moved to pong handler)
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
      } catch {
        /* ignore */
      }
    }
  }
}, CONFIG.pingIntervalMs);

// --- Start ---

server.listen(CONFIG.port, "0.0.0.0", () => {
  console.log(`[gang-up] web http://127.0.0.1:${CONFIG.port}  ws://127.0.0.1:${CONFIG.port}  max=${MAX_PLAYERS}`);
});
