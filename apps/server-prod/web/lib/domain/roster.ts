// 좌석 명단 도메인 값객체 — 서버 state 스냅샷에서 파생 사실을 한 번에 계산한다.
// 네트워크(콜리세우스)도 UI(React)도 모른다.

export interface SeatSnapshot {
  readonly slot: number;
  readonly sessionId: string;
  readonly name: string;
  readonly connected: boolean;
}

export interface RosterSnapshot {
  readonly gameId?: string;
  readonly open?: boolean; // 방장의 문 — 닫히면 입장 불가
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
  ) {}
}

export class Roster {
  private constructor(
    readonly seats: Seat[],
    readonly me: Seat | null,
    readonly playing: boolean,
  ) {}

  static fromSnapshot(snap: RosterSnapshot, mySessionId: string): Roster {
    // 최초 패치 도착 전의 부분 스냅샷(players 미동기)도 빈 명단으로 소화한다.
    const raw = Array.isArray(snap.players) ? snap.players : [];
    const seats = [...raw]
      .sort((a, b) => a.slot - b.slot)
      .map((p) => new Seat(
        p.slot, p.sessionId, p.name,
        p.sessionId === snap.hostSessionId,
        p.connected,
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
