import { describe, expect, it } from "vitest";
import {
  asCharacterId, assignSeatIdentity, characterBindNumber, defaultCharacterId, findCharacter,
  idForBind, listCharacters, matchBindKey, resolveMatchCharacterId, stepCharacterId,
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

  it("좌석 정체는 고른 id 를 중복 허용하고 랜덤만 한 번 푼다", () => {
    const key = matchBindKey();
    const a2 = `${canon.sheets?.[0]?.idPrefix}2`;
    expect(assignSeatIdentity(a2).characterId).toBe(a2);
    expect(assignSeatIdentity(a2).characterId).toBe(assignSeatIdentity(a2).characterId);
    expect(assignSeatIdentity(a2).animal).toBe(2);
    const rolled = assignSeatIdentity(defaultCharacterId());
    expect(rolled.characterId).not.toBe(defaultCharacterId());
    expect(characterBindNumber(rolled.characterId, key)).toBe(rolled.animal);
    expect(resolveMatchCharacterId(a2)).toBe(a2);
    const cpu = assignSeatIdentity(undefined, { cpu: true, slot: 5 });
    expect(cpu.characterId).toBe(idForBind(key, 5));
    expect(cpu.animal).toBe(5);
  });

  it("CPU 는 usedIds 를 피해 slot 결정론으로 고르고 풀 고갈 시에만 중복 폴백한다", () => {
    const key = matchBindKey();
    const prefix = canon.sheets?.[0]?.idPrefix ?? "a";
    const taken = new Set([`${prefix}1`]);
    const cpu = assignSeatIdentity(undefined, { cpu: true, slot: 1, usedIds: taken });
    expect(cpu.characterId).not.toBe(`${prefix}1`);
    expect(characterBindNumber(cpu.characterId, key)).toBe(cpu.animal);
    // 같은 입력이면 같은 결과 (결정론)
    const again = assignSeatIdentity(undefined, { cpu: true, slot: 1, usedIds: taken });
    expect(again.characterId).toBe(cpu.characterId);
    // 풀 전체가 사용됐으면 빈 id 가 아니라 중복 허용 폴백
    const pool = listCharacters().filter((row) => typeof row.binds?.[key] === "number");
    const all = new Set(pool.map((row) => row.id));
    const exhausted = assignSeatIdentity(undefined, { cpu: true, slot: 3, usedIds: all });
    expect(exhausted.characterId).not.toBe("");
    expect(all.has(exhausted.characterId)).toBe(true);
  });

  it("pool.length===0 폴백은 현재 카탈로그 데이터로 도달 불가능하다", () => {
    const key = matchBindKey();
    const pool = listCharacters().filter((row) => typeof row.binds?.[key] === "number");
    expect(pool.length).toBeGreaterThan(0);
    for (let slot = 0; slot < 8; slot++) {
      expect(assignSeatIdentity(undefined, { cpu: true, slot }).characterId).not.toBe("");
    }
  });

  it("토끼 a3 는 4×3 시트 index 3 이다", () => {
    const sheet = canon.sheets?.[0];
    expect(sheet).toEqual(expect.objectContaining({
      src: "/characters/animals.png", cols: 4, rows: 3, idPrefix: "a",
    }));
    expect(findCharacter("a3")?.portrait).toEqual({
      src: "/characters/animals.png", cols: 4, rows: 3, index: 3,
    });
    expect(findCharacter("a3")?.titleKey).toBe("characters.a3");
  });

  it("정본 길이는 entries + 시트 칸이다", () => {
    const cells = (canon.sheets ?? []).reduce((n, s) => n + s.cols * s.rows, 0);
    expect(listCharacters()).toHaveLength((canon.entries ?? []).length + cells);
  });
});
