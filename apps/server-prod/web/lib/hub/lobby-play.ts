import type { Client } from "colyseus";
import { MSG } from "../contract/wire.js";
import { matchJustEnded } from "./lobby-relay.js";
import { resetToLobby, type LobbyBag, type LobbyHandle } from "./lobby-waiting.js";
import {
  acceptPlayInput,
  MatchAuthority,
  packAuthoritySnap,
  writeMatchSchema,
} from "./match-authority.js";

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
  );
}

/** 구 클라이언트 host_snap 은 권위가 아니다. 버린다. */
export function ignoreHostSnap(): void {
  return;
}

export function bootAuthority(room: LobbyHandle, bag: LobbyBag): void {
  const seats = [...room.state.players].map((p) => ({ slot: p.slot, name: p.name }));
  bag.authority = new MatchAuthority(seats, room.state.mode);
  writeMatchSchema(room.state, bag.authority.sim);
  const snap = packAuthoritySnap(bag.authority.sim, bag.authority.names, room.state.mode);
  bag.prevSnap = null;
  bag.lastSnap = snap;
  room.broadcast(MSG.SNAP, snap);
}

export function tickAuthority(room: LobbyHandle, bag: LobbyBag, dtMs: number): void {
  if (room.state.phase !== "playing" || !bag.authority) {return;}
  const { snap, fx } = bag.authority.advance(Math.max(0, dtMs) / 1000, room.state);
  for (const ev of fx) {
    room.broadcast(MSG.GUN_FIRE, ev);
  }
  if (!snap) {return;}
  bag.prevSnap = bag.lastSnap;
  bag.lastSnap = snap;
  room.broadcast(MSG.SNAP, snap);
  if (matchJustEnded(snap, bag.prevSnap)) {
    if (bag.gameTimer) {bag.gameTimer.clear();}
    resetToLobby(room, bag);
  }
}
