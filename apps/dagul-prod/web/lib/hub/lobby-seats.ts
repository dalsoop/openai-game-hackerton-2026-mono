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

/** 대기실에서 빈 칸을 메운다. 플레이 중 슬롯은 시뮬 신원이라 당기지 않는다. */
export function compactLobbySlots(players: ReadonlyArray<{ slot: number }>): void {
  const ordered = [...players].sort((a, b) => a.slot - b.slot);
  for (let i = 0; i < ordered.length; i++) {
    ordered[i].slot = i;
  }
}

export function firstFreeSlot(usedSlots: readonly number[]): number {
  const used = new Set(usedSlots);
  for (let s = 0; s < HUB_CONFIG.maxPlayers; s++) {
    if (!used.has(s)) {return s;}
  }
  return usedSlots.length;
}

/** 대기실 빈 자리는 시작 시 CPU. 허브 권위 시드에 8칸을 맞춘다. */
export function fillMatchSeats(
  players: ReadonlyArray<{ slot: number; name: string; characterId?: string }>,
): Array<{ slot: number; name: string; characterId?: string; cpu: boolean }> {
  const seats: Array<{ slot: number; name: string; characterId?: string; cpu: boolean }> = [];
  const used = new Set<number>();
  for (const p of players) {
    if (p.slot < 0 || used.has(p.slot)) {continue;}
    used.add(p.slot);
    seats.push({ slot: p.slot, name: p.name, characterId: p.characterId, cpu: false });
  }
  for (let slot = 0; slot < HUB_CONFIG.maxPlayers; slot++) {
    if (used.has(slot)) {continue;}
    seats.push({ slot, name: `CPU${slot + 1}`, cpu: true });
  }
  return seats.sort((a, b) => a.slot - b.slot);
}

export function seatsPayloadOf(players: readonly PlayerSchema[]): SeatStart[] {
  return [...players]
    .sort((a, b) => a.slot - b.slot)
    .map((p) => ({
      slot: p.slot,
      name: p.name,
      connected: p.connected,
      characterId: p.characterId,
    }));
}
