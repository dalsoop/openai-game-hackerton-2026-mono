import { describe, expect, it } from "vitest";
import { CharacterRegistry } from "@/lib/characters/registry";
import { CharacterSheetSource, type CharacterCatalogData } from "@/lib/characters/sheet-source";
import data from "@/lib/characters/characters.json";

describe("CharacterSheetSource", () => {
  const source = new CharacterSheetSource(data as CharacterCatalogData);
  const registry = new CharacterRegistry(source);

  it("정본 defaultId 만 기본값으로 쓴다", () => {
    expect(registry.defaultId()).toBe(source.defaultId());
    expect(registry.normalize("nope")).toBe(source.defaultId());
    expect(registry.find(source.defaultId())).toBeDefined();
  });

  it("시트는 idPrefix+index 로만 전개하고 binds 키는 indexBind 다", () => {
    const sheet = (data as CharacterCatalogData).sheets?.[0];
    expect(sheet).toBeDefined();
    if (!sheet) {return;}
    const count = sheet.cols * sheet.rows;
    const first = registry.find(`${sheet.idPrefix}0`);
    const last = registry.find(`${sheet.idPrefix}${count - 1}`);
    expect(first?.binds?.[sheet.indexBind ?? ""]).toBe(0);
    expect(last?.binds?.[sheet.indexBind ?? ""]).toBe(count - 1);
    expect(first?.portrait.index).toBe(0);
    expect(last?.portrait.index).toBe(count - 1);
  });

  it("step 은 카탈로그 순서를 순환한다", () => {
    const ids = registry.list().map((item) => item.id);
    expect(ids.length).toBeGreaterThan(1);
    expect(registry.step(ids[0], 1)).toBe(ids[1]);
    expect(registry.step(ids[0], -1)).toBe(ids[ids.length - 1]);
    expect(registry.step(ids[ids.length - 1], 1)).toBe(ids[0]);
  });

  it("목록 길이는 entries + 시트 칸 수다", () => {
    const catalog = data as CharacterCatalogData;
    const sheetCells = (catalog.sheets ?? []).reduce((n, s) => n + s.cols * s.rows, 0);
    expect(registry.list()).toHaveLength((catalog.entries ?? []).length + sheetCells);
  });
});
