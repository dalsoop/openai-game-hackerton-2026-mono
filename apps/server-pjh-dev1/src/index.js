import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import http from "node:http";
import crypto from "node:crypto";
import { WebSocketServer } from "ws";
import { MAX_PLAYERS, MODES, TICK_HZ } from "./modes.js";
import { applyInput, createMatch, snapshot, step } from "./sim.js";

const PORT = Number(process.env.PORT || 9120);
const PUBLIC_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), "../public");
const TYPES = { ".html": "text/html; charset=utf-8", ".js": "text/javascript", ".css": "text/css", ".json": "application/json" };
const GRACE_LOBBY_MS = 20_000;
const GRACE_PLAY_MS = 60_000;
let nextId = 1;
let nextRoom = 1;
const clients = new Map();
const rooms = new Map();

function resumeToken() {
  return crypto.randomBytes(16).toString("hex");
}

function send(ws, msg) {
  if (!ws || ws.readyState !== 1) return;
  try {
    ws.send(JSON.stringify(msg));
  } catch {
    /* ignore broken sockets */
  }
}

function sendTo(id, msg) {
  const c = clients.get(id);
  if (c && !c.dead) send(c.ws, msg);
}

function clientByWs(ws) {
  for (const c of clients.values()) {
    if (c.ws === ws) return c;
  }
  return null;
}

function livingIds(room) {
  return room.members.filter((id) => {
    const c = clients.get(id);
    return c && !c.dead;
  });
}

function hostId(room) {
  return livingIds(room)[0] ?? room.members[0];
}

function roomPublic(room) {
  return {
    id: room.id,
    mode: room.mode,
    title: room.title,
    count: livingIds(room).length,
    max: MAX_PLAYERS,
    phase: room.phase,
  };
}

function peersPayload(room) {
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

function notifyRoom(room, extra) {
  const payload = { t: "peers", players: peersPayload(room), room: roomPublic(room), ...extra };
  for (const id of livingIds(room)) sendTo(id, payload);
}

function broadcastRooms() {
  const list = [...rooms.values()].filter((r) => r.phase === "lobby").map(roomPublic);
  for (const c of clients.values()) {
    if (!c.dead) send(c.ws, { t: "rooms", rooms: list });
  }
}

function parkPlayer(room, clientId) {
  if (!room?.match) return;
  const p = room.match.players.find((pl) => pl.id === clientId);
  if (p) {
    p.cpu = true;
    p.parked = true;
  }
}

function reclaimPlayer(room, clientId, name) {
  if (!room?.match) return;
  const p = room.match.players.find((pl) => pl.id === clientId);
  if (p) {
    p.cpu = false;
    p.parked = false;
    p.name = name || p.name;
  }
}

function dropClient(client) {
  if (client.dropTimer) {
    clearTimeout(client.dropTimer);
    client.dropTimer = null;
  }
  leaveRoom(client, { silent: false });
  clients.delete(client.id);
}

function parkClient(client) {
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
  parkPlayer(room, client.id);
  const grace = room.phase === "playing" ? GRACE_PLAY_MS : GRACE_LOBBY_MS;
  client.dropTimer = setTimeout(() => dropClient(client), grace);
  notifyRoom(room, { notice: `${client.name} 연결이 끊겼습니다. ${Math.round(grace / 1000)}초 안에 다시 들어오면 자리가 유지됩니다.` });
  broadcastRooms();
}

function leaveRoom(client, { silent } = {}) {
  if (client.dropTimer) {
    clearTimeout(client.dropTimer);
    client.dropTimer = null;
  }
  if (!client.roomId) return;
  const room = rooms.get(client.roomId);
  client.roomId = null;
  client.dead = false;
  if (!room) return;
  room.members = room.members.filter((id) => id !== client.id);
  parkPlayer(room, client.id);
  if (room.members.length === 0) {
    if (room.timer) clearTimeout(room.timer);
    rooms.delete(room.id);
  } else if (!silent) {
    notifyRoom(room);
  }
  broadcastRooms();
}

function attachResume(fresh, token) {
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
    clients.delete(fresh.id);
    try {
      if (staleWs && staleWs !== fresh.ws) staleWs.terminate();
    } catch {
      /* ignore */
    }
    const room = old.roomId ? rooms.get(old.roomId) : null;
    if (room) {
      reclaimPlayer(room, old.id, old.name);
      const playing = room.phase === "playing" && room.match;
      send(old.ws, {
        t: "resume",
        id: old.id,
        you: room.members.indexOf(old.id),
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

function startMatch(room) {
  if (room.phase !== "lobby") return;
  const humans = room.members.map((id) => ({ id, name: clients.get(id)?.name ?? "player" }));
  room.match = createMatch(room.mode, humans);
  room.phase = "playing";
  for (const id of room.members) {
    const c = clients.get(id);
    if (c?.dead) parkPlayer(room, id);
    else sendTo(id, { t: "start", you: room.members.indexOf(id), room: roomPublic(room) });
  }
  broadcastRooms();
  const interval = 1000 / TICK_HZ;
  let nextAt = Date.now() + interval;
  const loop = () => {
    if (!room.match) {
      room.timer = null;
      return;
    }
    const now = Date.now();
    let steps = 0;
    while (now + 1 >= nextAt && steps < 4) {
      step(room.match);
      nextAt += interval;
      steps += 1;
    }
    if (steps > 0) {
      const snap = snapshot(room.match);
      room.lastSnap = snap;
      for (const id of livingIds(room)) sendTo(id, snap);
      if (room.match.result !== "playing") {
        room.timer = null;
        return;
      }
    }
    room.timer = setTimeout(loop, Math.max(1, nextAt - Date.now()));
  };
  room.timer = setTimeout(loop, interval);
}

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
  const url = new URL(req.url || "/", "http://localhost");
  let file = url.pathname === "/" ? "/index.html" : url.pathname;
  const full = path.normalize(path.join(PUBLIC_DIR, file));
  if (!full.startsWith(PUBLIC_DIR)) {
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

const wss = new WebSocketServer({ server });
wss.on("connection", (ws) => {
  const client = {
    id: `p${nextId++}`,
    resume: resumeToken(),
    ws,
    name: "손님",
    mode: "classic",
    roomId: null,
    dead: false,
    deadAt: 0,
    dropTimer: null,
  };
  clients.set(client.id, client);
  send(ws, { t: "welcome", id: client.id, resume: client.resume, modes: MODES, max: MAX_PLAYERS });

  ws.on("message", (raw) => {
    const session = clientByWs(ws);
    if (!session) return;
    let msg;
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
});

function handleMessage(client, msg) {
  const t = msg.t;
  if (t === "ping") {
    send(client.ws, { t: "pong" });
    return;
  }
  if (t === "hello") {
    const token = String(msg.resume || "");
    if (/^[a-f0-9]{32}$/.test(token)) {
      const adopted = attachResume(client, token);
      if (adopted !== client) {
        adopted.name = String(msg.name || adopted.name || "손님").slice(0, 12);
        adopted.mode = MODES[msg.mode] ? msg.mode : adopted.mode;
        broadcastRooms();
        return;
      }
      if (msg.wantResume) {
        send(client.ws, { t: "dropped", msg: "이전 자리를 찾지 못했습니다. 로비로 갑니다.", resume: client.resume });
      }
    }
    client.name = String(msg.name || "손님").slice(0, 12);
    client.mode = MODES[msg.mode] ? msg.mode : "classic";
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
    const room = {
      id,
      mode: client.mode,
      title: String(msg.title || `${MODES[client.mode].title} #${id}`).slice(0, 24),
      members: [client.id],
      phase: "lobby",
      match: null,
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
    const room = rooms.get(msg.roomId);
    if (!room || room.phase !== "lobby") return send(client.ws, { t: "error", msg: "방을 찾을 수 없습니다" });
    client.mode = room.mode;
    if (room.members.length >= MAX_PLAYERS) return send(client.ws, { t: "error", msg: "방이 가득 찼습니다 (8)" });
    if (client.roomId) leaveRoom(client);
    room.members.push(client.id);
    client.roomId = room.id;
    send(client.ws, {
      t: "joined",
      you: room.members.indexOf(client.id),
      room: roomPublic(room),
      players: peersPayload(room),
    });
    notifyRoom(room);
    broadcastRooms();
    return;
  }
  if (t === "mode") {
    const room = rooms.get(client.roomId);
    if (!room || room.phase !== "lobby") return send(client.ws, { t: "error", msg: "지금은 게임을 바꿀 수 없습니다" });
    if (hostId(room) !== client.id) return send(client.ws, { t: "error", msg: "호스트만 게임을 바꿀 수 있습니다" });
    const next = MODES[msg.mode] ? msg.mode : room.mode;
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
    const room = rooms.get(client.roomId);
    if (!room || hostId(room) !== client.id) return send(client.ws, { t: "error", msg: "호스트만 시작할 수 있습니다" });
    startMatch(room);
    return;
  }
  if (t === "input") {
    const room = rooms.get(client.roomId);
    if (room?.match && !client.dead) applyInput(room.match, client.id, msg);
  }
}

setInterval(() => {
  for (const c of clients.values()) {
    if (!c.dead && c.ws.readyState === 1) {
      try {
        c.ws.ping();
      } catch {
        /* ignore */
      }
    }
  }
}, 10_000);

server.listen(PORT, "0.0.0.0", () => {
  console.log(`[gang-up] web http://127.0.0.1:${PORT}  ws://127.0.0.1:${PORT}  max=${MAX_PLAYERS}`);
});
