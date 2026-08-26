import { sameSeatClaim, type SeatClaim } from "../guest-identity.js";
import { HUB_CONFIG } from "./config.js";

export function isEngineJoin(options: { engine?: unknown } | undefined): boolean {
  return options?.engine === true;
}

export function seatClaimTakeover(
  players: ReadonlyArray<{ sessionId: string }>,
  claims: ReadonlyMap<string, SeatClaim>,
  claim: SeatClaim | null,
): boolean {
  if (!claim) {return false;}
  return players.some((p) => sameSeatClaim(claims.get(p.sessionId), claim));
}

export function playerJoinAllowed(playerCount: number, takeover: boolean): boolean {
  return takeover || playerCount < HUB_CONFIG.maxPlayers;
}

export function slotOfEngineClaim(
  players: ReadonlyArray<{ sessionId: string; slot: number }>,
  claims: ReadonlyMap<string, SeatClaim>,
  engineClaim: SeatClaim | undefined,
): number {
  if (!engineClaim) {return -1;}
  const owner = players.find((p) => sameSeatClaim(claims.get(p.sessionId), engineClaim));
  return owner?.slot ?? -1;
}

export function seatedSession(
  players: ReadonlyArray<{ sessionId: string }>,
  sessionId: string,
): boolean {
  return players.some((p) => p.sessionId === sessionId);
}
