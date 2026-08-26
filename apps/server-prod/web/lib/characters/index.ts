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

export function resolveMatchCharacterId(
  raw: unknown,
  bindKey = "animal",
  roll?: (max: number) => number,
): string {
  return registry.resolveForMatch(raw, bindKey, roll);
}
