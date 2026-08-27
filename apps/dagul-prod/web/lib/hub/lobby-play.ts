import type { Client } from "colyseus";
import { HUB_CONFIG } from "./config.js";
import { MSG } from "../contract/wire.js";
import { shouldHoldCountdown } from "../domain/match-load-ready.js";
import { matchJustEnded } from "./lobby-relay.js";
import { resetToLobby, type LobbyBag, type LobbyHandle } from "./lobby-waiting.js";
import {
  acceptPlayInput,
  packAuthoritySnap,
  seed as seedAuthority,
  setHeroAckReset,
  setHeroParked,
  tick as tickAuthoritySim,
  writeMatchSchema,
} from "./match-authority.js";
import { writeMatchState } from "./match-schema-write.js";
import { fillMatchSeats } from "./lobby-seats.js";
import { PLAYER_COUNT } from "./match-sim.js";

export function applyPlayInput(
  room: LobbyHandle,
  bag: LobbyBag,
  client: Client,
  data: Record<string, unknown>,
): void {
  acceptPlayInput(
    room.state.phase,
    [...room.state.players],
    client.sessionId,
    data,
    bag.authority,
    room.slotOfSession?.(client.sessionId) ?? -1,
  );
}

export function bootAuthority(room: LobbyHandle, bag: LobbyBag): void {
  const seats = fillMatchSeats([...room.state.players].map((p) => ({
    slot: p.slot, name: p.name, characterId: p.characterId,
  }))).slice(0, PLAYER_COUNT);
  bag.authority = seedAuthority(seats, room.state.mode, room.state.seed);
  for (const p of room.state.players) {
    if (!p.connected) {setHeroParked(bag.authority, p.slot, true);}
  }
  writeMatchSchema(room.state, bag.authority.sim);
  writeMatchState(room.state.match, bag.authority.sim, bag.authority.names, room.state.mode);
  const snap = packAuthoritySnap(bag.authority.sim, bag.authority.names, room.state.mode);
  bag.prevSnap = null;
  bag.lastSnap = snap;
  room.broadcast(MSG.SNAP, snap);
}

export function tickAuthority(room: LobbyHandle, bag: LobbyBag, dtMs: number): void {
  if (room.state.phase !== "playing" || !bag.authority) {return;}
  releaseLoadBarrier(room, bag, dtMs);
  const { snap, events } = tickAuthoritySim(bag.authority, Math.max(0, dtMs) / 1000, room.state);
  writeMatchState(
    room.state.match, bag.authority.sim, bag.authority.names, room.state.mode, events,
  );
  if (!snap) {return;}
  commitTickSnap(room, bag, snap);
}

/** lastSnap·승패 판정은 전원 opt-out 이어도 유지. JSON 스냅만 대상 세션에 보낸다. */
export function commitTickSnap(
  room: LobbyHandle,
  bag: LobbyBag,
  snap: Record<string, unknown>,
): void {
  bag.prevSnap = bag.lastSnap;
  bag.lastSnap = snap;
  sendTickSnap(room, snap);
  if (matchJustEnded(snap, bag.prevSnap)) {
    scheduleLobbyReset(room, bag);
  }
}

function sendTickSnap(room: LobbyHandle, snap: Record<string, unknown>): void {
  const blocked = room.snapOptOut;
  const targets = blocked && blocked.size > 0
    ? room.clients.filter((client) => !blocked.has(client.sessionId))
    : room.clients;
  if (targets.length === 0) {return;}
  for (const client of targets) {
    client.send(MSG.SNAP, snap);
  }
}

/** READY 직후 틱을 기다리지 않고 장벽을 연다. dtMs=0 이면 대기 시각은 늘리지 않는다. */
export function tryReleaseLoadBarrier(room: LobbyHandle, bag: LobbyBag): void {
  releaseLoadBarrier(room, bag, 0);
}

function releaseLoadBarrier(room: LobbyHandle, bag: LobbyBag, dtMs: number): void {
  const sim = bag.authority?.sim;
  if (!sim || !sim.countdownHeld) {return;}
  bag.loadWaitMs += Math.max(0, dtMs);
  const seats = [...room.state.players].map((p) => ({ matchReady: p.matchReady }));
  if (shouldHoldCountdown(seats, bag.loadWaitMs, HUB_CONFIG.loadReadyTimeoutMs)) {return;}
  sim.countdownHeld = false;
  room.state.loadHeld = false;
}

/** 결과 스냅을 먼저 뿌리고, 전원 같은 시각에 대기실로 돌린다. */
export function scheduleLobbyReset(room: LobbyHandle, bag: LobbyBag): void {
  if (bag.gameTimer) {bag.gameTimer.clear();}
  const handle = setTimeout(() => {
    resetToLobby(room, bag);
  }, HUB_CONFIG.resetToLobbyDelayMs);
  bag.gameTimer = { clear: (): void => {clearTimeout(handle);} };
}

export function parkSeat(bag: LobbyBag, slot: number, parked: boolean): void {
  setHeroParked(bag.authority, slot, parked);
}

export function resetSeatAck(bag: LobbyBag, slot: number): void {
  setHeroAckReset(bag.authority, slot);
}

export const seed = bootAuthority;
export const tick = tickAuthority;
export const apply = applyPlayInput;
