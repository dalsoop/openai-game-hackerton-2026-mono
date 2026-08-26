import type { CharacterDescriptor } from "./types";
import { CharacterRegistry } from "./registry";
import { CharacterSheetSource, type CharacterCatalogData } from "./sheet-source";
import data from "./characters.json";

const registry = new CharacterRegistry(new CharacterSheetSource(data as CharacterCatalogData));

export type { CharacterDescriptor, CharacterPortrait, CharacterSource } from "./types";
export { CharacterRegistry } from "./registry";
export { CharacterSheetSource } from "./sheet-source";
export { portraitStyle, portraitFrameStyle, portraitImageStyle } from "./portrait";

export function listCharacters(): readonly CharacterDescriptor[] {
  return registry.list();
}

export function findCharacter(id: string): CharacterDescriptor | undefined {
  return registry.find(id);
}

export function defaultCharacterId(): string {
  return registry.defaultId();
}

export function asCharacterId(raw: unknown): string {
  return registry.normalize(raw);
}

export function characterBindNumber(id: string, key: string): number | undefined {
  return registry.bindNumber(id, key);
}

export function stepCharacterId(id: string, delta: number): string {
  return registry.step(id, delta);
}

export function isRandomCharacterId(id: string): boolean {
  return registry.isRandomPick(id);
}

export function matchBindKey(): string {
  const key = (data as CharacterCatalogData).sheets?.[0]?.indexBind;
  return key && key !== "" ? key : "animal";
}

export function resolveMatchCharacterId(
  raw: unknown,
  bindKey = matchBindKey(),
  roll?: (max: number) => number,
): string {
  return registry.resolveForMatch(raw, bindKey, roll);
}

export function idForBind(key: string, value: number): string | undefined {
  return listCharacters().find((row) => row.binds?.[key] === value)?.id;
}

/** 매치 좌석 정체. 고른 id 는 중복을 허용하고, 랜덤·빈 CPU 만 여기서 한 번 푼다.
 * usedIds 를 주면 CPU 는 그 id 들을 제외한 풀에서 slot 결정론으로 고른다(풀 고갈 시 중복 폴백). */
export function assignSeatIdentity(
  raw: unknown,
  ctx: { cpu?: boolean; slot?: number; usedIds?: ReadonlySet<string> } = {},
): { characterId: string; animal: number } {
  const key = matchBindKey();
  const empty = raw == null || raw === "";
  if (ctx.cpu && empty) {
    return assignCpuIdentity(key, ctx);
  }
  const characterId = resolveMatchCharacterId(raw, key);
  return { characterId, animal: characterBindNumber(characterId, key) ?? 0 };
}

export type SeatIdentitySeed = { slot: number; characterId?: string; cpu?: boolean };
export type SeatIdentity = { characterId: string; animal: number };

/** 사람 좌석을 먼저 확정해 사용된 id 를 모으고, CPU 좌석은 그 집합을 피해서 고른다. */
export function seedSeatIdentities(seats: readonly SeatIdentitySeed[]): Map<number, SeatIdentity> {
  const out = new Map<number, SeatIdentity>();
  const used = new Set<string>();
  const seed = (seat: SeatIdentitySeed, cpuPass: boolean): void => {
    if (Boolean(seat.cpu) !== cpuPass || seat.slot < 0) {return;}
    const seeded = assignSeatIdentity(seat.characterId, {
      cpu: seat.cpu, slot: seat.slot, usedIds: used,
    });
    out.set(seat.slot, seeded);
    if (seeded.characterId !== "") {used.add(seeded.characterId);}
  };
  for (const seat of seats) {seed(seat, false);}
  for (const seat of seats) {seed(seat, true);}
  return out;
}

function assignCpuIdentity(
  key: string,
  ctx: { slot?: number; usedIds?: ReadonlySet<string> },
): { characterId: string; animal: number } {
  const pool = listCharacters().filter((row) => typeof row.binds?.[key] === "number");
  if (pool.length === 0) {
    return { characterId: "", animal: 0 };
  }
  const open = pool.filter((row) => !ctx.usedIds?.has(row.id));
  const source = open.length > 0 ? open : pool;
  const picked = source[Math.max(0, ctx.slot ?? 0) % source.length];
  return { characterId: picked.id, animal: characterBindNumber(picked.id, key) ?? 0 };
}
