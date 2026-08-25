import { HUB_CONFIG } from "./config.js";
import type { PlayerSchema } from "./lobby-state.js";
import type { SeatStart } from "./start-payload.js";

export function graceSeconds(phase: string): number {
  const ms = phase === "playing" ? HUB_CONFIG.gracePlayMs : HUB_CONFIG.graceLobbyMs;
  return ms / 1_000;
}

export function pickHostSessionId(players: readonly PlayerSchema[]): string {
  const host = [...players]
    .filter((p) => p.connected)
    .sort((a, b) => a.slot - b.slot).at(0);
  return host?.sessionId ?? "";
}

export function firstFreeSlot(usedSlots: readonly number[]): number {
  const used = new Set(usedSlots);
  for (let s = 0; s < HUB_CONFIG.maxPlayers; s++) {
    if (!used.has(s)) {return s;}
  }
  return usedSlots.length;
}

export function seatsPayloadOf(players: readonly PlayerSchema[]): SeatStart[] {
  return [...players]
    .sort((a, b) => a.slot - b.slot)
    .map((p) => ({ slot: p.slot, name: p.name, connected: p.connected }));
}
