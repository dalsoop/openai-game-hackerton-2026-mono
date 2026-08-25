import crypto from "node:crypto";
import { WebSocket } from "ws";
import { HUB_CONFIG, MSG, KO, MODES } from "./config";
import type { Client, Room, TaggedWebSocket } from "./types";
import { Phase } from "./types";

let nextId = 1;
let nextRoom = 1;
export const clients = new Map<string, Client>();
export const rooms = new Map<string, Room>();

export function allocClientId(): string { return `p${nextId++}`; }
export function allocRoomId(): string { return `r${nextRoom++}`; }
export function resumeToken(): string { return crypto.randomBytes(16).toString("hex"); }

export const sanitize = (s: unknown, max: number): string =>
  String(s || "").replace(/[<>&"'`]/g, "").trim().slice(0, max);

export function rateOk(c: Client): boolean {
  const now = Date.now();
  c.msgBudget = Math.min(HUB_CONFIG.rateBudget, c.msgBudget + (now - c.msgRefillAt) * HUB_CONFIG.rateRefillPerMs);
  c.msgRefillAt = now;
  if (c.msgBudget < 1) return false;
  c.msgBudget -= 1;
  return true;
}

export function send(ws: WebSocket | null, msg: unknown): void {
  if (!ws || ws.readyState !== WebSocket.OPEN) return;
  try { ws.send(typeof msg === "string" ? msg : JSON.stringify(msg)); } catch { /* */ }
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

export function slotOf(room: Room, clientId: string): number {
  return room.members.indexOf(clientId);
}

export function roomPublic(room: Room) {
  return {
    id: room.id, game: room.game, mode: room.mode, title: room.title,
    count: livingIds(room).length, max: HUB_CONFIG.maxPlayers, phase: room.phase,
  };
}

export function peersPayload(room: Room) {
  return room.members.map((id, i) => {
    if (!id) return { slot: i, id: "", name: "", host: false, dropped: true, vacant: true };
    const c = clients.get(id);
    return { slot: i, id, name: c?.name ?? "?", host: id === hostId(room), dropped: Boolean(c?.dead) };
  });
}

export function notifyRoom(room: Room, extra?: Record<string, unknown>): void {
  sendRoom(room, { t: MSG.PEERS, players: peersPayload(room), room: roomPublic(room), ...extra });
}

export function broadcastRooms(game?: string): void {
  const list = [...rooms.values()]
    .filter((r) => r.phase === Phase.LOBBY && (!game || r.game === game))
    .map(roomPublic);
  const text = JSON.stringify({ t: MSG.ROOMS, rooms: list });
  for (const c of clients.values()) {
    if (!c.dead && (!game || c.game === game)) send(c.ws, text);
  }
}

export function parkPlayer(room: Room, clientId: string): void {
  if (room.hostClientId) {
    sendTo(room.hostClientId, { t: MSG.PEER_PARKED, slot: room.members.indexOf(clientId) });
  }
}

export function reclaimPlayer(room: Room, clientId: string, name: string): void {
  if (room.hostClientId) {
    sendTo(room.hostClientId, { t: MSG.PEER_RECLAIMED, slot: room.members.indexOf(clientId), name });
  }
}

export function resetToLobby(room: Room): void {
  if (room.timer) { clearTimeout(room.timer); room.timer = null; }
  room.hostClientId = null;
  room.lastSnap = null;
  room.prevSnap = null;
  room.snapCount = 0;
  room.members = room.members.filter((id) => !!id);
  room.phase = Phase.LOBBY;
  if (livingIds(room).length === 0) { rooms.delete(room.id); broadcastRooms(room.game); return; }
  sendRoom(room, { t: MSG.LOBBY });
  notifyRoom(room, { notice: KO.GAME_END_LOBBY });
  broadcastRooms(room.game);
}

export function startMatch(room: Room): void {
  if (room.phase !== Phase.LOBBY) return;
  room.phase = Phase.PLAYING;
  room.hostClientId = hostId(room);
  const seed = Math.floor(Math.random() * 999999) + 1;
  const players = room.members.map((id, slot) => {
    const c = clients.get(id);
    return { slot, name: c?.name ?? "?", resume_token: c?.resume ?? "" };
  });
  notifyGameServer(room.id, players, room.mode, seed);
  for (const id of room.members) {
    const c = clients.get(id);
    if (c?.dead) { parkPlayer(room, id); continue; }
    const slot = room.members.indexOf(id);
    const isHost = id === room.hostClientId;
    sendTo(id, { t: MSG.START, you: slot, host: isHost, room: roomPublic(room), gameServerUrl: "", seed });
  }
  room.timer = setTimeout(() => {
    if (room.phase === Phase.PLAYING && !room.lastSnap) {
      sendRoom(room, { t: MSG.ERROR, msg: KO.HOST_BOOT_FAIL });
      resetToLobby(room);
    }
  }, HUB_CONFIG.hostBootTimeoutMs);
  broadcastRooms(room.game);
}

function notifyGameServer(roomId: string, players: { slot: number; name: string; resume_token: string }[], mode: string, seed: number): void {
  fetch(`${HUB_CONFIG.gameServerUrl}/start-match`, {
    method: "POST", headers: { "content-type": "application/json" },
    body: JSON.stringify({ room_id: roomId, players, mode, seed }),
    signal: AbortSignal.timeout(5000),
  }).catch((err: Error) => console.error(`[hub] game server notify failed: ${err.message}`));
}

export function leaveRoom(client: Client, opts?: { silent?: boolean }): void {
  if (client.dropTimer) { clearTimeout(client.dropTimer); client.dropTimer = null; }
  const wasDead = client.dead;
  if (!client.roomId) { if (wasDead || client.ws.readyState !== WebSocket.OPEN) clients.delete(client.id); return; }
  const room = rooms.get(client.roomId);
  client.roomId = null; client.dead = false;
  if (!room) { if (wasDead || client.ws.readyState !== WebSocket.OPEN) clients.delete(client.id); return; }
  parkPlayer(room, client.id);
  if (room.phase === Phase.PLAYING) {
    const idx = room.members.indexOf(client.id);
    if (idx >= 0) room.members[idx] = "";
  } else {
    room.members = room.members.filter((id) => id !== client.id);
  }
  if (room.phase === Phase.PLAYING && client.id === room.hostClientId) {
    if (!opts?.silent) notifyRoom(room, { notice: KO.hostLeftEnd(client.name) });
    resetToLobby(room);
  } else if (room.members.every((id) => !id) || (room.phase === Phase.LOBBY && room.members.length === 0)) {
    if (room.timer) clearTimeout(room.timer);
    rooms.delete(room.id);
  } else if (!opts?.silent) {
    notifyRoom(room, { notice: KO.playerLeft(client.name) });
  }
  if (wasDead || client.ws.readyState !== WebSocket.OPEN) clients.delete(client.id);
  broadcastRooms(room.game);
}

export function dropClient(client: Client): void {
  if (client.dropTimer) { clearTimeout(client.dropTimer); client.dropTimer = null; }
  leaveRoom(client);
  clients.delete(client.id);
}

export function parkClient(client: Client): void {
  if (!client.roomId) { clients.delete(client.id); return; }
  const room = rooms.get(client.roomId);
  if (!room) { clients.delete(client.id); return; }
  if (client.dead) return;
  client.dead = true;
  client.deadAt = Date.now();
  parkPlayer(room, client.id);
  const grace = room.phase === Phase.PLAYING ? HUB_CONFIG.gracePlayMs : HUB_CONFIG.graceLobbyMs;
  client.dropTimer = setTimeout(() => dropClient(client), grace);
  notifyRoom(room, { notice: KO.playerDropped(client.name, Math.round(grace / 1000)) });
  broadcastRooms(room.game);
}

export function attachResume(fresh: Client, token: string): Client {
  for (const old of clients.values()) {
    if (old.id === fresh.id || old.resume !== token) continue;
    if (old.dropTimer) { clearTimeout(old.dropTimer); old.dropTimer = null; }
    const staleWs = old.ws;
    old.ws = fresh.ws; old.dead = false; old.deadAt = 0;
    (fresh.ws as TaggedWebSocket)._session = old;
    old.resume = fresh.resume;
    clients.delete(fresh.id);
    try { if (staleWs && staleWs !== fresh.ws) staleWs.terminate(); } catch { /* */ }
    const room = old.roomId ? rooms.get(old.roomId) : null;
    if (room) {
      reclaimPlayer(room, old.id, old.name);
      const playing = room.phase === Phase.PLAYING;
      send(old.ws, {
        t: MSG.RESUME, id: old.id, resume: old.resume,
        you: slotOf(room, old.id), host: old.id === room.hostClientId,
        room: roomPublic(room), players: peersPayload(room),
        playing, snap: playing ? room.lastSnap : null, gameServerUrl: "",
      });
      notifyRoom(room, { notice: KO.playerReconnected(old.name) });
    } else {
      send(old.ws, { t: MSG.WELCOME, id: old.id, resume: old.resume, modes: MODES, max: HUB_CONFIG.maxPlayers });
      broadcastRooms(old.game);
    }
    return old;
  }
  return fresh;
}
