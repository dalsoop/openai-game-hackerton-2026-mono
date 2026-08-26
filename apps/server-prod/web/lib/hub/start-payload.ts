import { asCharacterId } from "@/lib/characters";

// START 메시지 계약 — 서버가 보내고 React 가 localStorage 에 남기며 Godot 가 읽는다.
// 경계에서만 unknown 을 받고, 이후는 StartPayload 만 흐르게 한다.

export interface SeatStart {
  readonly slot: number;
  readonly name: string;
  readonly connected: boolean;
  readonly characterId: string;
}

export interface StartPayload {
  readonly you: number;
  readonly host: boolean;
  readonly seed: number;
  readonly mode: string;
  readonly seats: readonly SeatStart[];
}

function asSeat(raw: unknown): SeatStart | null {
  if (!raw || typeof raw !== "object") {return null;}
  const o = raw as Record<string, unknown>;
  const slot = Number(o.slot);
  if (!Number.isFinite(slot)) {return null;}
  return {
    slot,
    name: typeof o.name === "string" ? o.name : "",
    connected: o.connected !== false,
    characterId: asCharacterId(o.characterId),
  };
}

/** 신뢰 불가 START 본문을 확정 타입으로. 좌석·시드가 없으면 거절한다. */
export function parseStartPayload(raw: unknown): StartPayload | null {
  if (!raw || typeof raw !== "object") {return null;}
  const o = raw as Record<string, unknown>;
  const you = Number(o.you);
  const seed = Number(o.seed);
  if (!Number.isFinite(you) || !Number.isFinite(seed) || seed <= 0) {return null;}
  const seats = Array.isArray(o.seats)
    ? o.seats.map(asSeat).filter((s): s is SeatStart => s !== null)
    : [];
  return {
    you,
    host: Boolean(o.host),
    seed,
    mode: typeof o.mode === "string" ? o.mode : "",
    seats,
  };
}

/** 새로고침 후 React 가 MATCH 로 브릿지를 다시 연다. */
export function matchInfoFromStoredStart(
  raw: string | null,
  room: { roomId: string; reconnectionToken: string; gameId?: string },
  name: string,
): {
  roomId: string;
  name: string;
  slot: number;
  resumeToken: string;
  match: StartPayload;
  gameId?: string;
} | null {
  if (!raw) {return null;}
  let parsed: unknown;
  try {parsed = JSON.parse(raw);} catch {return null;}
  const payload = parseStartPayload(parsed);
  if (!payload) {return null;}
  return {
    roomId: room.roomId,
    name,
    slot: payload.you,
    resumeToken: room.reconnectionToken,
    match: payload,
    gameId: room.gameId,
  };
}
