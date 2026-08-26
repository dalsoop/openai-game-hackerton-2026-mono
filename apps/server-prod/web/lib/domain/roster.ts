import { asCharacterId } from "@/lib/characters";

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
}

export interface RosterSnapshot {
  readonly gameId?: string;
  readonly open?: boolean;
  readonly createdAtMs?: number;
  readonly idleUntilSec?: number;
  readonly phase: string;
  readonly hostSessionId: string;
  readonly players: readonly SeatSnapshot[];
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
  ) {}
}

export class Roster {
  private constructor(
    readonly seats: Seat[],
    readonly me: Seat | null,
    readonly playing: boolean,
  ) {}

  static fromSnapshot(snap: RosterSnapshot, mySessionId: string): Roster {
    const raw = Array.isArray(snap.players) ? snap.players : [];
    const seats = [...raw]
      .sort((a, b) => a.slot - b.slot)
      .map((p) => new Seat(
        p.slot, p.sessionId, p.name,
        p.sessionId === snap.hostSessionId,
        p.connected,
        clampPackPct(p.packPct),
        asCharacterId(p.characterId),
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
