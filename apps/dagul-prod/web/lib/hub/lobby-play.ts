import type { Client } from "colyseus";
import { HUB_CONFIG, KO } from "./config.js";
import { CLOSE_CODE, MSG } from "../contract/wire.js";
import { loadWaitTimedOut, shouldHoldCountdown } from "../domain/match-load-ready.js";
import { matchJustEnded } from "./lobby-relay.js";
import { resetToLobby, type LobbyBag, type LobbyHandle } from "./lobby-waiting.js";
import { recordRoundDuration } from "./ops-metrics.js";
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
import { PLAYER_COUNT, type MatchSim } from "./match-sim.js";

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
  syncResolvedCharacterIds(room, bag.authority.sim);
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

/**
 * "랜덤" 픽(SSOT: characters.json defaultId)은 허브가 매치 시드로 단 한 번만 굴린다.
 * 그 결과(sim.heroes)를 players 에 되써야 START 페이로드·재접속·재입장이 같은 값을
 * 본다 — 아니면 클라(Godot)가 허브 해소 전 "unknown" 원본을 그대로 받아 실행한다.
 */
function syncResolvedCharacterIds(room: LobbyHandle, sim: MatchSim): void {
  for (const p of room.state.players) {
    const resolved = sim.heroes.get(p.slot)?.characterId;
    if (resolved) {p.characterId = resolved;}
  }
}

export function tickAuthority(room: LobbyHandle, bag: LobbyBag, dtMs: number): void {
  if (room.state.phase !== "playing" || !bag.authority) {return;}
  tryReleaseLoadBarrier(room, bag, dtMs);
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
    if (bag.matchStartedAtMs > 0) {
      recordRoundDuration(Date.now() - bag.matchStartedAtMs);
      bag.matchStartedAtMs = 0;
    }
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

/** dropSeat → tryRelease 재진입에서 같은 틱에 강퇴를 두 번 보내지 않는다. */
let kickingLoadWait = false;

/** 전원 matchReady 이면 장벽을 연다. 1분이 지나도 미완료면 그 좌석만 내보낸다.
 * packPct·20초로는 열지 않는다. */
export function tryReleaseLoadBarrier(room: LobbyHandle, bag: LobbyBag, dtMs = 0): void {
  const sim = bag.authority?.sim;
  if (!sim || !sim.countdownHeld) {return;}
  bag.loadWaitMs += Math.max(0, dtMs);
  const seats = [...room.state.players].map((p) => ({ matchReady: p.matchReady }));
  if (!shouldHoldCountdown(seats)) {
    sim.countdownHeld = false;
    room.state.loadHeld = false;
    return;
  }
  if (kickingLoadWait) {return;}
  if (!loadWaitTimedOut(bag.loadWaitMs, HUB_CONFIG.loadReadyWaitMs)) {return;}
  kickingLoadWait = true;
  try {
    kickUnreadyLoadWait(room);
  } finally {
    kickingLoadWait = false;
  }
}

const LOAD_WAIT_KICK = { msg: KO.LOAD_WAIT_TIMEOUT, reason: "load-wait" } as const;

function kickUnreadyLoadWait(room: LobbyHandle): void {
  const unreadyIds = [...room.state.players]
    .filter((p) => !p.matchReady)
    .map((p) => p.sessionId);
  for (const sessionId of unreadyIds) {
    const client = room.clients.find((c) => c.sessionId === sessionId);
    if (client) {
      client.send(MSG.KICKED, LOAD_WAIT_KICK);
      client.leave(CLOSE_CODE.KICKED);
    }
    room.dropSeat?.(sessionId);
  }
}

/** 이어받기처럼 좌석이 다시 로딩해야 하면 카운트다운·개전을 붙잡고 1분 대기를 다시 잰다. */
export function holdLoadBarrier(room: LobbyHandle, bag: LobbyBag): void {
  const sim = bag.authority?.sim;
  if (!sim || room.state.phase !== "playing") {return;}
  sim.countdownHeld = true;
  room.state.loadHeld = true;
  bag.loadWaitMs = 0;
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
