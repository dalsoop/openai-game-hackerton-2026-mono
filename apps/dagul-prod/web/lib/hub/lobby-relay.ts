import { MSG } from "../contract/wire.js";
import type { EngineJoin, SeatStart, StartPayload } from "./start-payload.js";

export function matchJustEnded(
  data: Record<string, unknown>,
  prevSnap: Record<string, unknown> | null,
): boolean {
  const ended = Boolean(data.result && data.result !== "playing");
  return ended && (prevSnap === null || prevSnap["result"] === "playing");
}

export function startBodies(
  players: ReadonlyArray<{ sessionId: string; slot: number }>,
  hostSessionId: string,
  seed: number,
  mode: string,
  seats: SeatStart[],
  engineJoin?: EngineJoin,
): Array<{ sessionId: string; type: typeof MSG.START; payload: StartPayload }> {
  return players.map((p) => ({
    sessionId: p.sessionId,
    type: MSG.START,
    payload: engineJoin
      ? {
        you: p.slot,
        host: p.sessionId === hostSessionId,
        seed,
        mode,
        seats,
        engineJoin,
      }
      : {
        you: p.slot,
        host: p.sessionId === hostSessionId,
        seed,
        mode,
        seats,
      },
  }));
}
