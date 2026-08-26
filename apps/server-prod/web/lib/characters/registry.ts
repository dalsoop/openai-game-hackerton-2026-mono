import type { CharacterDescriptor, CharacterSource } from "./types";

export class CharacterRegistry {
  private readonly byId = new Map<string, CharacterDescriptor>();
  private readonly fallbackId: string;

  constructor(source: CharacterSource) {
    const items = source.load();
    for (const item of items) {
      this.byId.set(item.id, item);
    }
    const want = source.defaultId();
    this.fallbackId = this.byId.has(want) ? want : (items[0]?.id ?? "");
  }

  list(): readonly CharacterDescriptor[] {
    return [...this.byId.values()];
  }

  find(id: string): CharacterDescriptor | undefined {
    return this.byId.get(id);
  }

  defaultId(): string {
    return this.fallbackId;
  }

  normalize(raw: unknown): string {
    const id = typeof raw === "string" ? raw : "";
    return this.byId.has(id) ? id : this.fallbackId;
  }

  bindNumber(id: string, key: string): number | undefined {
    const value = this.find(this.normalize(id))?.binds?.[key];
    return typeof value === "number" && Number.isFinite(value) ? value : undefined;
  }

  idsWithBind(key: string): readonly string[] {
    return this.list()
      .filter((item) => typeof item.binds?.[key] === "number")
      .map((item) => item.id);
  }

  isRandomPick(id: string): boolean {
    return this.find(this.normalize(id))?.pick === "random";
  }

  resolveForMatch(raw: unknown, key: string, roll: (max: number) => number = (max) => Math.floor(Math.random() * max)): string {
    const id = this.normalize(raw);
    if (!this.isRandomPick(id) && this.bindNumber(id, key) !== undefined) {
      return id;
    }
    const pool = this.idsWithBind(key);
    if (pool.length === 0) {return id;}
    return pool[roll(pool.length)] ?? id;
  }

  step(id: string, delta: number): string {
    const items = this.list();
    if (items.length === 0) {return this.fallbackId;}
    const at = items.findIndex((item) => item.id === this.normalize(id));
    const from = at < 0 ? 0 : at;
    const n = items.length;
    const shift = ((delta % n) + n) % n;
    return items[(from + shift) % n].id;
  }
}
