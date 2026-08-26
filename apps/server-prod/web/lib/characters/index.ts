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

/** 매치 좌석 정체. 고른 id 는 중복을 허용하고, 랜덤·빈 CPU 만 여기서 한 번 푼다. */
export function assignSeatIdentity(
  raw: unknown,
  ctx: { cpu?: boolean; slot?: number } = {},
): { characterId: string; animal: number } {
  const key = matchBindKey();
  const empty = raw == null || raw === "";
  if (ctx.cpu && empty) {
    const pool = listCharacters().filter((row) => typeof row.binds?.[key] === "number");
    if (pool.length === 0) {
      return { characterId: "", animal: 0 };
    }
    const picked = pool[Math.max(0, ctx.slot ?? 0) % pool.length];
    return { characterId: picked.id, animal: characterBindNumber(picked.id, key) ?? 0 };
  }
  const characterId = resolveMatchCharacterId(raw, key);
  return { characterId, animal: characterBindNumber(characterId, key) ?? 0 };
}
