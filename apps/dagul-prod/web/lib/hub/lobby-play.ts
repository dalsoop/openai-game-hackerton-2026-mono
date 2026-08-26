import type { Client } from "colyseus";
import { HUB_CONFIG } from "./config.js";
import { MSG } from "../contract/wire.js";
import { matchJustEnded } from "./lobby-relay.js";
import { resetToLobby, type LobbyBag, type LobbyHandle } from "./lobby-waiting.js";
import {
  acceptPlayInput,
  packAuthoritySnap,
  seed as seedAuthority,
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
  writeMatchSchema(room.state, bag.authority.sim);
  writeMatchState(room.state.match, bag.authority.sim, bag.authority.names, room.state.mode);
  const snap = packAuthoritySnap(bag.authority.sim, bag.authority.names, room.state.mode);
  bag.prevSnap = null;
  bag.lastSnap = snap;
  room.broadcast(MSG.SNAP, snap);
}

export function tickAuthority(room: LobbyHandle, bag: LobbyBag, dtMs: number): void {
  if (room.state.phase !== "playing" || !bag.authority) {return;}
  const { snap, fx } = tickAuthoritySim(bag.authority, Math.max(0, dtMs) / 1000, room.state);
  writeMatchState(room.state.match, bag.authority.sim, bag.authority.names, room.state.mode);
  for (const ev of fx) {
    room.broadcast(MSG.GUN_FIRE, ev);
  }
  if (!snap) {return;}
  bag.prevSnap = bag.lastSnap;
  bag.lastSnap = snap;
  room.broadcast(MSG.SNAP, snap);
  if (matchJustEnded(snap, bag.prevSnap)) {
    scheduleLobbyReset(room, bag);
  }
}

/** 결과 스냅을 먼저 뿌리고, 전원 같은 시각에 대기실로 돌린다. */
export function scheduleLobbyReset(room: LobbyHandle, bag: LobbyBag): void {
  if (bag.gameTimer) {bag.gameTimer.clear();}
  const handle = setTimeout(() => {
    resetToLobby(room, bag);
  }, HUB_CONFIG.resetToLobbyDelayMs);
  bag.gameTimer = { clear: (): void => {clearTimeout(handle);} };
}

export const seed = bootAuthority;
export const tick = tickAuthority;
export const apply = applyPlayInput;
