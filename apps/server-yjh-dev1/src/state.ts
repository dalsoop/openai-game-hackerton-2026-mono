import crypto from "node:crypto";
import { WebSocket } from "ws";
import { CONFIG, Phase, MSG } from "./config.js";
import { MAX_PLAYERS, MODES } from "./modes.js";
import type { Client, Room, TaggedWebSocket } from "./types.js";

// --- Shared State ---

let nextId = 1;
let nextRoom = 1;
export const clients = new Map<string, Client>();
export const rooms = new Map<string, Room>();

export function allocClientId(): string { return `p${nextId++}`; }
export function allocRoomId(): string { return `r${nextRoom++}`; }

// --- Low-level Helpers ---

export function resumeToken(): string {
  return crypto.randomBytes(16).toString("hex");
}

export const sanitize = (s: unknown, max: number): string =>
  String(s || "").replace(/[<>&"'`]/g, "").trim().slice(0, max);

export function rateOk(c: Client): boolean {
  const now = Date.now();
  c.msgBudget = Math.min(CONFIG.rateBudget, c.msgBudget + (now - c.msgRefillAt) * CONFIG.rateRefillPerMs);
  c.msgRefillAt = now;
  if (c.msgBudget < 1) return false;
  c.msgBudget -= 1;
  return true;
}

export function send(ws: WebSocket | null, msg: unknown): void {
  if (!ws || ws.readyState !== WebSocket.OPEN) return;
  try {
    ws.send(typeof msg === "string" ? msg : JSON.stringify(msg));
  } catch { /* ignore broken sockets */ }
}

export function sendTo(id: string, msg: unknown): void {
  const c = clients.get(id);
  if (c && !c.dead) send(c.ws, msg);
}

export function sendRoom(room: Room, msg: unknown): void {
  const text = JSON.stringify(msg);
  for (const id of livingIds(room)) sendTo(id, text);
}

export function clientByWs(ws: WebSocket): Client | null {
  return (ws as TaggedWebSocket)._session ?? null;
}

export function livingIds(room: Room): string[] {
  return room.members.filter((id) => {
    if (!id) return false;
    const c = clients.get(id);
    return c && !c.dead;
  });
}

export function hostId(room: Room): string {
  return livingIds(room)[0] ?? room.members[0]!;
}

export function slotOf(_room: Room, clientId: string): number {
  return _room.members.indexOf(clientId);
}

export function roomPublic(room: Room) {
  return {
    id: room.id,
    mode: room.mode,
    title: room.title,
    count: livingIds(room).length,
    max: MAX_PLAYERS,
    phase: room.phase,
  };
}

export function peersPayload(room: Room) {
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

export function notifyRoom(room: Room, extra?: Record<string, unknown>): void {
  sendRoom(room, { t: MSG.PEERS, players: peersPayload(room), room: roomPublic(room), ...extra });
}

export function broadcastRooms(): void {
  const list = [...rooms.values()].filter((r) => r.phase === Phase.LOBBY).map(roomPublic);
  const text = JSON.stringify({ t: MSG.ROOMS, rooms: list });
  for (const c of clients.values()) {
    if (!c.dead) send(c.ws, text);
  }
}

// --- Relay Notifications (host ↔ player state) ---

export function parkPlayer(_room: Room, _clientId: string): void {
  if (_room.hostClientId) {
    sendTo(_room.hostClientId, { t: MSG.PEER_PARKED, slot: _room.members.indexOf(_clientId) });
  }
}

export function reclaimPlayer(_room: Room, _clientId: string, _name: string): void {
  if (_room.hostClientId) {
    sendTo(_room.hostClientId, { t: MSG.PEER_RECLAIMED, slot: _room.members.indexOf(_clientId), name: _name });
  }
}

// --- Room Management ---

export function resetToLobby(room: Room): void {
  if (room.timer) { clearTimeout(room.timer); room.timer = null; }
  room.hostClientId = null;
  room.lastSnap = null;
  room.prevSnap = null;
  room.snapCount = 0;
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

export function startMatch(room: Room): void {
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
  room.timer = setTimeout(() => {
    if (room.phase === Phase.PLAYING && !room.lastSnap) {
      sendRoom(room, { t: MSG.ERROR, msg: "호스트가 게임을 시작하지 못했습니다." });
      resetToLobby(room);
    }
  }, CONFIG.resetToLobbyDelayMs);
  broadcastRooms();
}

export function leaveRoom(client: Client, { silent }: { silent?: boolean } = {}): void {
  if (client.dropTimer) {
    clearTimeout(client.dropTimer);
    client.dropTimer = null;
  }
  const wasDead = client.dead;
  if (!client.roomId) {
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
  parkPlayer(room, client.id);
  if (room.phase === Phase.PLAYING) {
    const idx = room.members.indexOf(client.id);
    if (idx >= 0) room.members[idx] = "";
  } else {
    room.members = room.members.filter((id) => id !== client.id);
  }
  if (room.phase === Phase.PLAYING && client.id === room.hostClientId) {
    if (!silent) notifyRoom(room, { notice: `호스트(${client.name})가 나가서 게임이 종료됩니다.` });
    resetToLobby(room);
  } else if (room.members.every((id) => !id) || (room.phase === Phase.LOBBY && room.members.length === 0)) {
    if (room.timer) clearTimeout(room.timer);
    rooms.delete(room.id);
  } else if (!silent) {
    notifyRoom(room, { notice: `${client.name} 이(가) 나갔습니다.` });
  }
  if (wasDead || client.ws.readyState !== WebSocket.OPEN) clients.delete(client.id);
  broadcastRooms();
}

// --- Session Management ---

export function dropClient(client: Client): void {
  if (client.dropTimer) {
    clearTimeout(client.dropTimer);
    client.dropTimer = null;
  }
  leaveRoom(client, { silent: false });
  clients.delete(client.id);
}

export function parkClient(client: Client): void {
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

export function attachResume(fresh: Client, token: string): Client {
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
    (fresh.ws as TaggedWebSocket)._session = old;
    old.resume = fresh.resume;
    clients.delete(fresh.id);
    try {
      if (staleWs && staleWs !== fresh.ws) staleWs.terminate();
    } catch { /* ignore */ }
    const room = old.roomId ? rooms.get(old.roomId) : null;
    if (room) {
      reclaimPlayer(room, old.id, old.name);
      const playing = room.phase === Phase.PLAYING;
      send(old.ws, {
        t: "resume",
        id: old.id,
        resume: old.resume,
        you: slotOf(room, old.id),
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
