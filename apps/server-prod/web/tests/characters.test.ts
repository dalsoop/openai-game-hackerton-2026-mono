import { describe, expect, it } from "vitest";
import {
  asCharacterId, characterBindNumber, defaultCharacterId, findCharacter,
  listCharacters, stepCharacterId,
} from "@/lib/characters";
import { CharacterRegistry } from "@/lib/characters/registry";
import { CharacterSheetSource, type CharacterCatalogData } from "@/lib/characters/sheet-source";
import type { CharacterDescriptor, CharacterSource } from "@/lib/characters/types";
import data from "@/lib/characters/characters.json";

const canon = data as CharacterCatalogData;

function sourceOf(items: CharacterDescriptor[], fallback: string): CharacterSource {
  return { load: () => items, defaultId: () => fallback };
}

function item(id: string, bind?: number): CharacterDescriptor {
  return {
    id,
    titleKey: `t.${id}`,
    portrait: { src: `/${id}.png` },
    binds: bind === undefined ? undefined : { animal: bind },
  };
}

describe("CharacterRegistry — 가짜 소스", () => {
  const registry = new CharacterRegistry(sourceOf([item("def"), item("x", 3), item("y", 7)], "def"));

  it("없는 id·비문자열은 defaultId 로 정규화한다", () => {
    expect(registry.normalize("nope")).toBe("def");
    expect(registry.normalize(1)).toBe("def");
    expect(registry.normalize(undefined)).toBe("def");
    expect(registry.normalize("x")).toBe("x");
  });

  it("defaultId 가 목록에 없으면 첫 항목을 쓴다", () => {
    const r = new CharacterRegistry(sourceOf([item("a"), item("b")], "missing"));
    expect(r.defaultId()).toBe("a");
    expect(r.normalize("")).toBe("a");
  });

  it("빈 소스는 빈 id 로 버틴다", () => {
    const r = new CharacterRegistry(sourceOf([], "z"));
    expect(r.defaultId()).toBe("");
    expect(r.list()).toEqual([]);
    expect(r.step("z", 1)).toBe("");
  });

  it("bindNumber 는 숫자 binds 만 돌려준다", () => {
    expect(registry.bindNumber("x", "animal")).toBe(3);
    expect(registry.bindNumber("def", "animal")).toBeUndefined();
    expect(registry.bindNumber("nope", "animal")).toBeUndefined();
    expect(registry.bindNumber("x", "other")).toBeUndefined();
  });

  it("step 은 큰 델타와 음수 델타를 같은 원으로 접는다", () => {
    expect(registry.step("def", 3)).toBe("def");
    expect(registry.step("def", -3)).toBe("def");
    expect(registry.step("x", 2)).toBe("def");
    expect(registry.step("nope", 1)).toBe("x");
  });
});

describe("CharacterSheetSource — 합성 카탈로그", () => {
  it("entries 와 시트를 이어 붙이고 시트 칸은 prefix+index 다", () => {
    const src = new CharacterSheetSource({
      defaultId: "z",
      entries: [{ id: "z", titleKey: "t.z", portrait: { src: "/z.png" } }],
      sheets: [{
        src: "/s.png", cols: 2, rows: 2, idPrefix: "c", titleKeyPrefix: "t.c", indexBind: "animal",
      }],
    });
    const ids = src.load().map((row) => row.id);
    expect(ids).toEqual(["z", "c0", "c1", "c2", "c3"]);
    const cell = src.load()[3];
    expect(cell.portrait).toEqual({ src: "/s.png", cols: 2, rows: 2, index: 2 });
    expect(cell.binds).toEqual({ animal: 2 });
    expect(cell.titleKey).toBe("t.c2");
  });

  it("시트 칸이 0 이거나 필드가 비면 전개하지 않는다", () => {
    const src = new CharacterSheetSource({
      defaultId: "z",
      entries: [],
      sheets: [
        { src: "/s.png", cols: 0, rows: 3, idPrefix: "c", titleKeyPrefix: "t.c" },
        { src: "/s.png", cols: 2, rows: 1, idPrefix: "n", titleKeyPrefix: "t.n" },
      ],
    });
    const rows = src.load();
    expect(rows).toHaveLength(2);
    expect(rows[0].id).toBe("n0");
    expect(rows[0].binds).toBeUndefined();
  });
});

describe("정본 카탈로그 공개 API", () => {
  const registry = new CharacterRegistry(new CharacterSheetSource(canon));

  it("모듈 함수는 레지스트리와 같은 기본값·정규화를 쓴다", () => {
    expect(defaultCharacterId()).toBe(canon.defaultId);
    expect(asCharacterId("")).toBe(canon.defaultId);
    expect(findCharacter(canon.defaultId)?.portrait.src).toBe("/characters/unknown.png");
    expect(listCharacters().map((row) => row.id)).toEqual(registry.list().map((row) => row.id));
  });

  it("시트 칸 bind 는 index 이고 기본 항목은 animal 이 없다", () => {
    const sheet = canon.sheets?.[0];
    expect(sheet).toBeDefined();
    if (!sheet) {return;}
    const id = `${sheet.idPrefix}4`;
    expect(characterBindNumber(id, sheet.indexBind ?? "")).toBe(4);
    expect(characterBindNumber(canon.defaultId, "animal")).toBeUndefined();
    expect(stepCharacterId(canon.defaultId, 1)).toBe(`${sheet.idPrefix}0`);
    expect(stepCharacterId(`${sheet.idPrefix}0`, -1)).toBe(canon.defaultId);
  });

  it("정본 길이는 entries + 시트 칸이다", () => {
    const cells = (canon.sheets ?? []).reduce((n, s) => n + s.cols * s.rows, 0);
    expect(listCharacters()).toHaveLength((canon.entries ?? []).length + cells);
  });
});
