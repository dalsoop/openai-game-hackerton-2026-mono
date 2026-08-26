/** 대기실 팩 진행률 — 방 state와 좌석 문구의 정본. HTTP 다운로드 일반론이 아니다. */

export type PackSeat = {
  readonly slot: number;
  readonly present: boolean;
  readonly pct: number;
  readonly name: string;
};

export function clampPackPct(raw: unknown): number {
  const n = Math.round(Number(raw));
  if (!Number.isFinite(n)) {return 0;}
  return Math.max(0, Math.min(100, n));
}

export function isPresent(seat: { connected?: boolean; dropped?: boolean }): boolean {
  return seat.dropped !== true && seat.connected !== false;
}

export function packSeatsOf(
  players: readonly { slot: number; name?: string; connected?: boolean; dropped?: boolean; packPct?: number }[],
): PackSeat[] {
  return players.map((p) => ({
    slot: p.slot,
    name: p.name ?? "",
    present: isPresent(p),
    pct: clampPackPct(p.packPct),
  }));
}

export function overlayOwnPackPct(seats: readonly PackSeat[], you: number, ownPackPct: number): PackSeat[] {
  const mine = clampPackPct(ownPackPct);
  return seats.map((s) => (s.slot === you ? { ...s, pct: Math.max(s.pct, mine) } : s));
}

export function allPacksReceived(seats: readonly PackSeat[]): boolean {
  return seats.filter((s) => s.present).every((s) => s.pct >= 100);
}

export function packLabelKind(pct: number): "ready" | "pending" | "progress" {
  if (pct >= 100) {return "ready";}
  if (pct <= 0) {return "pending";}
  return "progress";
}

export type PackSeatTag = "reconnect" | "pending" | "progress" | "host" | "waiting";

export function packSeatTag(dropped: boolean, pct: number, isHost: boolean): PackSeatTag {
  if (dropped) {return "reconnect";}
  const kind = packLabelKind(pct);
  if (kind === "pending" || kind === "progress") {return kind;}
  return isHost ? "host" : "waiting";
}

type PlayerLike = {
  slot: number;
  name?: string;
  dropped?: boolean;
  connected?: boolean;
  packPct?: number;
};

export function waitingRoomPackView<T extends PlayerLike>(
  players: readonly T[],
  you: number,
  ownPackPct: number,
): { seats: PackSeat[]; players: T[] } {
  const seats = overlayOwnPackPct(packSeatsOf(players), you, ownPackPct);
  const pctBySlot = new Map(seats.map((s) => [s.slot, s.pct]));
  return {
    seats,
    players: players.map((p) => {
      const pct = pctBySlot.get(p.slot);
      return pct === undefined ? p : { ...p, packPct: pct };
    }),
  };
}
