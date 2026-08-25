import { WebSocket } from "ws";
import { HUB_CONFIG, MSG, KO, MODES } from "./config";
import type { Client, Room, TaggedWebSocket } from "./types";
import { Phase } from "./types";
import {
  clients, rooms, allocClientId, allocRoomId, resumeToken,
  sanitize, rateOk, send, sendTo, sendRoom,
  clientByWs, livingIds, hostId, slotOf, roomPublic, peersPayload,
  notifyRoom, broadcastRooms, parkPlayer,
  leaveRoom, startMatch, resetToLobby, attachResume, parkClient, dropClient,
} from "./room-manager";

export function onConnection(ws: WebSocket, game: string): void {
  const id = allocClientId();
  const client: Client = {
    id, resume: resumeToken(), ws, name: HUB_CONFIG.defaultName,
    mode: HUB_CONFIG.defaultMode, game, roomId: null,
    dead: false, deadAt: 0, dropTimer: null, rtt: -1,
    msgBudget: HUB_CONFIG.rateBudget, msgRefillAt: Date.now(), publicHost: "",
  };
  (ws as TaggedWebSocket)._session = client;
  clients.set(id, client);
  send(ws, { t: MSG.WELCOME, id, resume: client.resume, modes: MODES, max: HUB_CONFIG.maxPlayers });

  ws.on("message", (data) => {
    if (!rateOk(client)) return;
    let msg: Record<string, unknown>;
    try { msg = JSON.parse(String(data)); } catch { return; }
    handleMessage(client, msg);
  });

  ws.on("close", () => parkClient(client));
  ws.on("error", () => parkClient(client));
}

function handleMessage(client: Client, msg: Record<string, unknown>): void {
  const t = msg.t;

  if (t === MSG.PING) { send(client.ws, { t: MSG.PONG, ts: msg.ts }); return; }

  if (t === MSG.HELLO) {
    const token = String(msg.resume || "");
    if (/^[a-f0-9]{32}$/.test(token)) {
      const adopted = attachResume(client, token);
      if (adopted !== client) {
        adopted.name = sanitize(msg.name, HUB_CONFIG.maxNameLength) || adopted.name;
        adopted.mode = MODES[String(msg.mode)] ? String(msg.mode) : adopted.mode;
        broadcastRooms(client.game);
        return;
      }
      if (msg.wantResume && token !== client.resume) {
        send(client.ws, { t: MSG.DROPPED, msg: KO.RESUME_NOT_FOUND, resume: client.resume });
      }
    }
    client.name = sanitize(msg.name, HUB_CONFIG.maxNameLength) || HUB_CONFIG.defaultName;
    client.mode = MODES[String(msg.mode)] ? String(msg.mode) : HUB_CONFIG.defaultMode;
    if (client.roomId) { const room = rooms.get(client.roomId); if (room) notifyRoom(room); }
    broadcastRooms(client.game);
    return;
  }

  if (t === MSG.ROOMS) { broadcastRooms(client.game); return; }

  if (t === MSG.CREATE) {
    if (client.roomId) leaveRoom(client);
    const id = allocRoomId();
    const mode = MODES[client.mode] ? client.mode : HUB_CONFIG.defaultMode;
    const room: Room = {
      id, game: client.game, mode,
      title: sanitize(msg.title, HUB_CONFIG.maxTitleLength) || `${MODES[mode]!.title} #${id}`,
      members: [client.id], phase: Phase.LOBBY,
      hostClientId: null, timer: null, lastSnap: null, prevSnap: null, snapCount: 0,
    };
    rooms.set(id, room);
    client.roomId = id;
    send(client.ws, { t: MSG.JOINED, you: 0, room: roomPublic(room), players: peersPayload(room) });
    broadcastRooms(client.game);
    return;
  }

  if (t === MSG.JOIN) {
    const room = rooms.get(String(msg.roomId));
    if (!room || room.phase !== Phase.LOBBY) { send(client.ws, { t: MSG.ERROR, msg: KO.ROOM_NOT_FOUND }); return; }
    if (room.members.length >= HUB_CONFIG.maxPlayers) { send(client.ws, { t: MSG.ERROR, msg: KO.ROOM_FULL }); return; }
    client.mode = room.mode;
    if (client.roomId) leaveRoom(client);
    room.members.push(client.id);
    client.roomId = room.id;
    send(client.ws, { t: MSG.JOINED, you: room.members.indexOf(client.id), room: roomPublic(room), players: peersPayload(room) });
    notifyRoom(room, { notice: KO.playerJoined(client.name) });
    broadcastRooms(client.game);
    return;
  }

  if (t === MSG.MODE) {
    if (!client.roomId) return;
    const room = rooms.get(client.roomId);
    if (!room || room.phase !== Phase.LOBBY) { send(client.ws, { t: MSG.ERROR, msg: KO.CANNOT_CHANGE_MODE }); return; }
    if (hostId(room) !== client.id) { send(client.ws, { t: MSG.ERROR, msg: KO.HOST_ONLY_MODE }); return; }
    const next = MODES[String(msg.mode)] ? String(msg.mode) : room.mode;
    room.mode = next;
    for (const id of room.members) { const c = clients.get(id); if (c) c.mode = next; }
    notifyRoom(room);
    broadcastRooms(client.game);
    return;
  }

  if (t === MSG.LEAVE) { leaveRoom(client); send(client.ws, { t: MSG.LEFT }); return; }

  if (t === MSG.START) {
    if (!client.roomId) return;
    const room = rooms.get(client.roomId);
    if (!room || hostId(room) !== client.id) { send(client.ws, { t: MSG.ERROR, msg: KO.HOST_ONLY_START }); return; }
    startMatch(room);
    return;
  }

  if (t === MSG.KICK) {
    if (!client.roomId) return;
    const room = rooms.get(client.roomId);
    if (!room || room.phase !== Phase.LOBBY) { send(client.ws, { t: MSG.ERROR, msg: KO.CANNOT_KICK }); return; }
    if (hostId(room) !== client.id) { send(client.ws, { t: MSG.ERROR, msg: KO.HOST_ONLY_KICK }); return; }
    const slot = Number(msg.slot);
    const targetId = room.members[slot];
    if (!targetId || targetId === client.id) return;
    const target = clients.get(targetId);
    if (!target) return;
    leaveRoom(target, { silent: true });
    send(target.ws, { t: MSG.KICKED, msg: KO.KICKED_MSG });
    notifyRoom(room, { notice: KO.playerKicked(target.name) });
    return;
  }

  if (t === MSG.CHAT) {
    if (!client.roomId) return;
    const room = rooms.get(client.roomId);
    if (!room) return;
    const text = String(msg.text || "").replace(/\s+/g, " ").trim().slice(0, HUB_CONFIG.maxChatLength);
    if (!text) return;
    const now = Date.now();
    if (client.lastChatAt && now - client.lastChatAt < HUB_CONFIG.chatCooldownMs) return;
    client.lastChatAt = now;
    sendRoom(room, { t: MSG.CHAT, from: client.name, slot: slotOf(room, client.id), text });
    return;
  }

  if (t === MSG.INPUT) {
    if (!client.roomId) return;
    const room = rooms.get(client.roomId);
    if (!room || room.phase !== Phase.PLAYING || client.dead) return;
    if (client.id === room.hostClientId) return;
    const slot = room.members.indexOf(client.id);
    if (slot < 0) return;
    sendTo(room.hostClientId!, {
      t: MSG.PEER_INPUT, slot,
      mx: msg.mx, my: msg.my, fire: msg.fire, dash: msg.dash, use: msg.use,
      aimX: msg.aimX, aimY: msg.aimY, seq: msg.seq,
    });
    return;
  }

  if (t === MSG.HOST_SNAP) {
    if (!client.roomId) return;
    const room = rooms.get(client.roomId);
    if (!room || room.phase !== Phase.PLAYING) return;
    if (client.id !== room.hostClientId) return;
    const snapData: Record<string, unknown> = { ...msg, t: MSG.SNAP };
    room.prevSnap = room.lastSnap;
    room.lastSnap = snapData;
    room.snapCount += 1;
    const text = JSON.stringify(snapData);
    for (const id of livingIds(room)) { if (id !== client.id) sendTo(id, text); }
    const isEnded = Boolean(snapData.result && snapData.result !== Phase.PLAYING);
    if (isEnded && (!room.prevSnap || room.prevSnap["result"] === Phase.PLAYING)) {
      if (room.timer) { clearTimeout(room.timer); room.timer = null; }
      room.timer = setTimeout(() => { const r = rooms.get(room.id); if (r) resetToLobby(r); }, HUB_CONFIG.resetToLobbyDelayMs);
    } else if ((snapData as Record<string, unknown>).result === Phase.PLAYING && room.timer) {
      clearTimeout(room.timer); room.timer = null;
    }
    return;
  }
}
