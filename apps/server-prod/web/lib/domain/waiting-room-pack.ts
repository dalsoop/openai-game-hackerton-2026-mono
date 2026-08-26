import { Seat, clampPackPct } from "./roster";

export { clampPackPct };

export function overlayOwnPackPct(seats: readonly Seat[], you: number, ownPackPct: number): Seat[] {
  const mine = clampPackPct(ownPackPct);
  return seats.map((s) => {
    if (s.slot !== you) {return s;}
    const pct = Math.max(s.packPct, mine);
    if (pct === s.packPct) {return s;}
    return new Seat(s.slot, s.playerId, s.name, s.isHost, s.connected, pct, s.characterId);
  });
}

export function connectedSeatsPacked(seats: readonly Seat[]): boolean {
  return seats.filter((s) => s.connected).every((s) => s.packPct >= 100);
}

export type PackKind = "ready" | "pending" | "progress";

export function packKind(pct: number): PackKind {
  if (pct >= 100) {return "ready";}
  if (pct <= 0) {return "pending";}
  return "progress";
}

export type SlotBadge = "reconnect" | "pending" | "progress" | "host" | "waiting";

export function slotBadge(seat: Pick<Seat, "connected" | "packPct" | "isHost">): SlotBadge {
  if (!seat.connected) {return "reconnect";}
  const kind = packKind(seat.packPct);
  if (kind === "pending" || kind === "progress") {return kind;}
  return seat.isHost ? "host" : "waiting";
}

export function shouldSendPackPct(prev: number | null, next: number): boolean {
  const pct = clampPackPct(next);
  if (prev === null) {return true;}
  if (pct === prev) {return false;}
  if (pct === 0 || pct === 100) {return true;}
  return pct >= prev + 5;
}
