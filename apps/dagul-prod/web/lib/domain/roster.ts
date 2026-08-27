import { asCharacterId } from "../characters/index.js";

export function clampPackPct(raw: unknown): number {
  const n = Math.round(Number(raw));
  if (!Number.isFinite(n)) {return 0;}
  return Math.max(0, Math.min(100, n));
}

export interface SeatSnapshot {
  readonly slot: number;
  readonly sessionId: string;
  readonly name: string;
  readonly connected: boolean;
  readonly packPct?: number;
  readonly characterId?: string;
  readonly matchReady?: boolean;
}

export interface RosterSnapshot {
  readonly gameId?: string;
  readonly mode?: string;
  readonly open?: boolean;
  readonly createdAtMs?: number;
  readonly idleUntilSec?: number;
  readonly loadHeld?: boolean;
  /** 중첩 matchReady 지문. 선택자 동등 비교용. */
  readonly readySig?: string;
  readonly phase: string;
  readonly hostSessionId: string;
  readonly password?: string;
  readonly startInSec?: number;
  readonly players: readonly SeatSnapshot[];
}

/** 스키마 인스턴스를 평문 복사한다. 죽은 ~refId 를 React 가 다시 읽지 않게. */
export function plainSeatOf(p: SeatSnapshot): SeatSnapshot {
  return {
    slot: Number(p.slot),
    sessionId: String(p.sessionId),
    name: String(p.name),
    connected: Boolean(p.connected),
    packPct: p.packPct,
    characterId: p.characterId,
    matchReady: Boolean(p.matchReady),
  };
}

/** ArraySchema 는 Array 가 아니다. 이터러블이면 펼친다. */
export function seatListOf(raw: unknown): SeatSnapshot[] {
  if (raw == null) {return [];}
  if (Array.isArray(raw)) {return raw as SeatSnapshot[];}
  if (typeof (raw as Iterable<unknown>)[Symbol.iterator] === "function") {
    return [...(raw as Iterable<SeatSnapshot>)];
  }
  return [];
}

export class Seat {
  constructor(
    readonly slot: number,
    readonly playerId: string,
    readonly name: string,
    readonly isHost: boolean,
    readonly connected: boolean,
    readonly packPct: number,
    readonly characterId: string,
    readonly matchReady = false,
  ) {}
}

export class Roster {
  private constructor(
    readonly seats: Seat[],
    readonly me: Seat | null,
    readonly playing: boolean,
  ) {}

  static fromSnapshot(snap: RosterSnapshot, mySessionId: string): Roster {
    const raw = seatListOf(snap.players);
    const seats = [...raw]
      .sort((a, b) => a.slot - b.slot)
      .map((p) => new Seat(
        p.slot, p.sessionId, p.name,
        p.sessionId === snap.hostSessionId,
        p.connected,
        clampPackPct(p.packPct),
        asCharacterId(p.characterId),
        Boolean(p.matchReady),
      ));
    const me = seats.find((s) => s.playerId === mySessionId) ?? null;
    return new Roster(seats, me, snap.phase === "playing");
  }

  get you(): number {
    return this.me?.slot ?? -1;
  }

  get isHost(): boolean {
    return this.me?.isHost ?? false;
  }

  get host(): Seat | null {
    return this.seats.find((s) => s.isHost) ?? null;
  }
}
