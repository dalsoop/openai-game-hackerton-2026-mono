import { CONFIG, Phase, MSG } from "./config.js";
import { MAX_PLAYERS, MODES } from "./modes.js";
import type { Client, Room } from "./types.js";
import {
  clients, rooms, allocRoomId,
  sanitize, send, sendTo, sendRoom,
  livingIds, hostId, slotOf, roomPublic, peersPayload,
  notifyRoom, broadcastRooms,
  parkPlayer, leaveRoom, startMatch, resetToLobby,
  attachResume,
} from "./state.js";

// --- Snapshot Delta (measurement only) ---

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
    if (arrayKeys.has(key)) { delta[key] = next[key]; continue; }
    if (JSON.stringify(prev[key]) !== JSON.stringify(next[key])) delta[key] = next[key];
  }
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

// --- Message Handler ---

export function handleMessage(client: Client, msg: Record<string, unknown>): void {
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
    // L1: notify room members when name changes
    if (client.roomId) {
      const room = rooms.get(client.roomId);
      if (room) notifyRoom(room);
    }
    broadcastRooms();
    return;
  }

  if (t === MSG.ROOMS) {
    broadcastRooms();
    return;
  }

  if (t === MSG.CREATE) {
    if (client.roomId) leaveRoom(client);
    const id = allocRoomId();
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
    if (room.members.length >= MAX_PLAYERS) { send(client.ws, { t: MSG.ERROR, msg: "방이 가득 찼습니다 (8)" }); return; }
    client.mode = room.mode;
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
    sendRoom(room, { t: MSG.CHAT, from: client.name, slot: slotOf(room, client.id), text });
    return;
  }

  if (t === MSG.INPUT) {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== Phase.PLAYING || client.dead) return;
    if (client.id === room.hostClientId) return;
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

  if (t === MSG.HOST_SNAP) {
    const room = rooms.get(client.roomId!);
    if (!room || room.phase !== Phase.PLAYING) return;
    if (client.id !== room.hostClientId) return;
    const snapData = msg as Record<string, unknown>;
    snapData.t = MSG.SNAP;
    room.prevSnap = room.lastSnap;
    room.lastSnap = snapData;
    room.snapCount += 1;
    const text = JSON.stringify(snapData);
    if (room.prevSnap && room.snapCount % CONFIG.snapDeltaLogInterval === 0) {
      const delta = computeHeroDelta(room.prevSnap, snapData);
      const deltaSize = JSON.stringify(delta).length;
      const fullSize = text.length;
      const pct = Math.round((1 - deltaSize / fullSize) * 100);
      console.log(`[snap-delta] room=${room.id} full=${fullSize}B delta=${deltaSize}B saving=${pct}%`);
    }
    for (const id of livingIds(room)) {
      if (id !== client.id) sendTo(id, text);
    }
    const isEnded = snapData.result && snapData.result !== Phase.PLAYING;
    if (isEnded) {
      if (!room.prevSnap || room.prevSnap["result"] === Phase.PLAYING) {
        if (room.timer) { clearTimeout(room.timer); room.timer = null; }
        room.timer = setTimeout(() => resetToLobby(room), CONFIG.resetToLobbyDelayMs);
      }
    } else if (snapData.result === Phase.PLAYING && room.timer) {
      clearTimeout(room.timer);
      room.timer = null;
    }
    return;
  }
}
