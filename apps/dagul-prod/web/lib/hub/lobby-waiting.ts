import type { Client } from "colyseus";
import { clampPackPct, shouldSendPackPct } from "../domain/waiting-room-pack.js";
import { HUB_CONFIG, KO } from "./config.js";
import { MSG, CLOSE_CODE } from "../contract/wire.js";
import { asCharacterId } from "../characters/index.js";
import { asGameId, defaultModeOf } from "../games/catalog.js";
import type { LobbyState } from "./lobby-state.js";
import { seatsPayloadOf } from "./lobby-seats.js";
import { startBodies } from "./lobby-relay.js";
import { idleUntilSecOf, nowUnixSec } from "./lobby-idle.js";
import { clearMatchSchema, type MatchAuthority } from "./match-authority.js";
import { seatedSession } from "./match-engine.js";
import { clearMatchState } from "./match-schema-write.js";

export type TimerHandle = { clear(): void };

export type LobbyBag = {
  lastSnap: Record<string, unknown> | null;
  prevSnap: Record<string, unknown> | null;
  gameTimer: TimerHandle | null;
  idleTimer: TimerHandle | null;
  authority: MatchAuthority | null;
  hostLossTimer: TimerHandle | null;
};

export type LobbyHandle = {
  state: LobbyState;
  clients: Client[];
  metadata: object;
  setMetadata: (value: object) => void | Promise<void>;
  clock: { setTimeout: (cb: () => void, ms: number) => TimerHandle };
  broadcast: (type: string, payload: unknown) => void;
  roomId?: string;
  slotOfSession?(sessionId: string): number;
};

/** 호스트가 순간적으로 사라져도 곧바로 리셋하지 않고, 유예 뒤 여전히 없을 때만 리셋한다.
 * 재접속·새 join 으로 호스트가 다시 정해지면 cancelHostLossReset 이 취소한다. */
export function scheduleHostLossReset(room: LobbyHandle, bag: LobbyBag): void {
  if (bag.hostLossTimer) {return;} // 이미 예약됨 — 중복 예약 금지
  bag.hostLossTimer = room.clock.setTimeout(() => {
    bag.hostLossTimer = null;
    if (room.state.phase === "playing" && room.state.hostSessionId === "") {
      resetToLobby(room, bag);
    }
  }, HUB_CONFIG.hostLossGraceMs);
}

export function cancelHostLossReset(bag: LobbyBag): void {
  if (bag.hostLossTimer) {bag.hostLossTimer.clear(); bag.hostLossTimer = null;}
}

export function handleRoomToggle(room: LobbyHandle, client: Client): void {
  if (client.sessionId !== room.state.hostSessionId) {
    client.send(MSG.ERROR, { msg: KO.HOST_ONLY_TOGGLE });
    return;
  }
  room.state.open = !room.state.open;
  void room.setMetadata({ ...room.metadata, open: room.state.open });
  if (room.state.open) {return;}
  for (const c of room.clients) {
    if (c.sessionId === room.state.hostSessionId) {continue;}
    if (!seatedSession([...room.state.players], c.sessionId)) {continue;}
    c.send(MSG.KICKED, { msg: KO.KICKED_MSG });
    c.leave(CLOSE_CODE.KICKED);
  }
}

export function handleSetGame(room: LobbyHandle, client: Client, data: Record<string, unknown>): void {
  if (room.state.phase !== "lobby") {return;}
  if (client.sessionId !== room.state.hostSessionId) {
    client.send(MSG.ERROR, { msg: KO.HOST_ONLY_GAME });
    return;
  }
  const game = asGameId(data.game);
  room.state.gameId = game;
  room.state.mode = defaultModeOf(game);
  for (const p of room.state.players) {p.packPct = 0;}
  void room.setMetadata({ ...room.metadata, gameId: game, mode: room.state.mode });
}

export function handleSetCharacter(room: LobbyHandle, client: Client, data: Record<string, unknown>): void {
  if (room.state.phase !== "lobby") {return;}
  const player = room.state.players.find((p) => p.sessionId === client.sessionId);
  if (!player) {return;}
  player.characterId = asCharacterId(data.characterId);
}

export function handlePackPct(room: LobbyHandle, client: Client, data: Record<string, unknown>): void {
  if (room.state.phase !== "lobby") {return;}
  const player = room.state.players.find((p) => p.sessionId === client.sessionId);
  if (!player) {return;}
  const next = clampPackPct(data.pct);
  if (!shouldSendPackPct(player.packPct, next)) {return;}
  player.packPct = next;
}

export function burstIdle(room: LobbyHandle): void {
  if (room.state.phase !== "lobby") {return;}
  const payload = { msg: KO.IDLE_START, reason: "idle" };
  const clients = [...room.clients];
  for (const c of clients) {
    c.send(MSG.KICKED, payload);
  }
  setTimeout(() => {
    for (const c of clients) {
      c.leave(CLOSE_CODE.KICKED);
    }
  }, 0);
}

export function clearIdleTimer(room: LobbyHandle, bag: LobbyBag): void {
  if (bag.idleTimer) {bag.idleTimer.clear(); bag.idleTimer = null;}
  room.state.idleUntilSec = 0;
}

export function armIdleTimer(room: LobbyHandle, bag: LobbyBag): void {
  clearIdleTimer(room, bag);
  room.state.idleUntilSec = idleUntilSecOf(nowUnixSec());
  bag.idleTimer = room.clock.setTimeout(() => {burstIdle(room);}, HUB_CONFIG.idleStartMs);
}

export function resetToLobby(room: LobbyHandle, bag: LobbyBag): void {
  if (bag.gameTimer) {bag.gameTimer.clear(); bag.gameTimer = null;}
  cancelHostLossReset(bag);
  bag.lastSnap = null;
  bag.prevSnap = null;
  bag.authority = null;
  clearMatchSchema(room.state);
  clearMatchState(room.state.match);
  room.state.phase = "lobby";
  room.state.seed = 0;
  void room.setMetadata({ ...room.metadata, phase: room.state.phase });
  armIdleTimer(room, bag);
}

export function handleStart(room: LobbyHandle, bag: LobbyBag, client: Client): void {
  if (room.state.phase !== "lobby") {return;}
  if (client.sessionId !== room.state.hostSessionId) {
    client.send(MSG.ERROR, { msg: KO.HOST_ONLY_START });
    return;
  }
  clearIdleTimer(room, bag);
  room.state.phase = "playing";
  room.state.seed = Math.floor(Math.random() * HUB_CONFIG.seedMax) + 1;
  void room.setMetadata({ ...room.metadata, phase: room.state.phase });
  sendStartBodies(room, bag);
}

function sendStartBodies(room: LobbyHandle, bag: LobbyBag): void {
  // 계약: CPU 좌석 정보는 START 에 없고 SNAP 으로만 전달된다 (seats 는 실접속 플레이어만 담는다).
  const seats = seatsPayloadOf(room.state.players);
  const engineJoin = room.roomId ? { roomId: room.roomId } : undefined;
  for (const body of startBodies(
    [...room.state.players], room.state.hostSessionId, room.state.seed, room.state.mode, seats,
    engineJoin,
  )) {
    room.clients.find((c) => c.sessionId === body.sessionId)
      ?.send(body.type, body.payload, { afterNextPatch: true });
  }
  bag.gameTimer = room.clock.setTimeout(() => {
    if (room.state.phase === "playing" && !bag.lastSnap) {
      room.broadcast(MSG.ERROR, { msg: KO.HOST_BOOT_FAIL });
      resetToLobby(room, bag);
    }
  }, HUB_CONFIG.hostBootTimeoutMs);
}
