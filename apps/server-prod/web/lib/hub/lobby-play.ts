import type { Client } from "colyseus";
import { HUB_CONFIG } from "./config.js";
import { MSG } from "../contract/wire.js";
import { matchJustEnded } from "./lobby-relay.js";
import { resetToLobby, type LobbyBag, type LobbyHandle } from "./lobby-waiting.js";
import {
  acceptPlayInput,
  MatchAuthority,
  packAuthoritySnap,
  writeMatchSchema,
} from "./match-authority.js";
import { fillMatchSeats } from "./lobby-seats.js";

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
  const seats = fillMatchSeats([...room.state.players].map((p) => ({
    slot: p.slot, name: p.name, characterId: p.characterId,
  })));
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
