/** 대기실 받기 진행률 — 방 state와 좌석 표시의 정본. */

export type SeatDownload = {
  readonly slot: number;
  readonly present: boolean;
  readonly pct: number;
  readonly name: string;
};

export function clampPct(raw: unknown): number {
  const n = Math.round(Number(raw));
  if (!Number.isFinite(n)) {return 0;}
  return Math.max(0, Math.min(100, n));
}

export function isPresent(seat: { connected?: boolean; dropped?: boolean }): boolean {
  return seat.dropped !== true && seat.connected !== false;
}

export function seatsOf(
  players: readonly { slot: number; name?: string; connected?: boolean; dropped?: boolean; dlPct?: number }[],
): SeatDownload[] {
  return players.map((p) => ({
    slot: p.slot,
    name: p.name ?? "",
    present: isPresent(p),
    pct: clampPct(p.dlPct),
  }));
}

export function overlaySelf(seats: readonly SeatDownload[], you: number, localPct: number): SeatDownload[] {
  const mine = clampPct(localPct);
  return seats.map((s) => (s.slot === you ? { ...s, pct: Math.max(s.pct, mine) } : s));
}

export function allSeatsReady(seats: readonly SeatDownload[]): boolean {
  return seats.filter((s) => s.present).every((s) => s.pct >= 100);
}

export function labelKind(pct: number): "ready" | "pending" | "progress" {
  if (pct >= 100) {return "ready";}
  if (pct <= 0) {return "pending";}
  return "progress";
}

export type SeatTag = "reconnect" | "pending" | "progress" | "host" | "waiting";

export function seatTag(dropped: boolean, pct: number, isHost: boolean): SeatTag {
  if (dropped) {return "reconnect";}
  const kind = labelKind(pct);
  if (kind === "pending" || kind === "progress") {return kind;}
  return isHost ? "host" : "waiting";
}

type PlayerLike = {
  slot: number;
  name?: string;
  dropped?: boolean;
  connected?: boolean;
  dlPct?: number;
};

export function roomDownload<T extends PlayerLike>(
  players: readonly T[],
  you: number,
  localPct: number,
): { seats: SeatDownload[]; players: T[] } {
  const seats = overlaySelf(seatsOf(players), you, localPct);
  const pctBySlot = new Map(seats.map((s) => [s.slot, s.pct]));
  return {
    seats,
    players: players.map((p) => {
      const pct = pctBySlot.get(p.slot);
      return pct === undefined ? p : { ...p, dlPct: pct };
    }),
  };
}
