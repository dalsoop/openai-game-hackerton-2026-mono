// 게임 카탈로그 도메인 — 유즈맵 모델의 정본 계약.
import { describe, expect, it } from "vitest";
import { GAME_CATALOG, DEFAULT_GAME_ID, asGameId, isKnownGame, findGame, defaultModeOf, modeI18nKey, packOf, catalogPacks } from "@/lib/games/catalog";
import { readCatalogPacks } from "../scripts/catalog-packs.mjs";

describe("GAME_CATALOG", () => {
  it("기본 게임은 다굴이며 카탈로그에 등재돼 있다", () => {
    expect(DEFAULT_GAME_ID).toBe("dagul");
    expect(isKnownGame(DEFAULT_GAME_ID)).toBe(true);
  });

  it("카탈로그 항목은 id·표시명 키를 갖추고 id 는 유일하다", () => {
    const ids = GAME_CATALOG.map((g) => g.id);
    expect(new Set(ids).size).toBe(ids.length);
    for (const g of GAME_CATALOG) {
      expect(g.id.length).toBeGreaterThan(0);
      expect(g.titleKey.length).toBeGreaterThan(0);
      expect(g.blurbKey.length).toBeGreaterThan(0);
      expect(g.thumbSrc.startsWith("/")).toBe(true);
      expect(g.defaultMode.length).toBeGreaterThan(0);
      expect(g.pack.length).toBeGreaterThan(0);
    }
  });
});

describe("packOf — GameId 와 웹 산출물 폴더", () => {
  it("유즈맵은 같은 팩을 가리킨다", () => {
    expect(packOf(asGameId("dagul"))).toBe("dagul");
    expect(packOf(asGameId("sparring"))).toBe(packOf(asGameId("dagul")));
  });

  it("catalogPacks 는 중복 없는 pack 집합이다", () => {
    const packs = catalogPacks();
    expect(packs.length).toBeGreaterThan(0);
    expect(new Set(packs).size).toBe(packs.length);
    for (const g of GAME_CATALOG) {
      expect(packs).toContain(g.pack);
    }
    expect(readCatalogPacks()).toEqual([...packs]);
  });
});

describe("asGameId — 신뢰 불가 입력 정규화", () => {
  it("등재된 id 는 그대로 통과한다", () => {
    expect(asGameId("dagul")).toBe("dagul");
  });

  it("미등재·빈 값·비문자열은 기본 게임으로 떨어진다", () => {
    expect(asGameId("unknown-game")).toBe(DEFAULT_GAME_ID);
    expect(asGameId("")).toBe(DEFAULT_GAME_ID);
    expect(asGameId(undefined)).toBe(DEFAULT_GAME_ID);
    expect(asGameId(42)).toBe(DEFAULT_GAME_ID);
    expect(asGameId({ id: "dagul" })).toBe(DEFAULT_GAME_ID);
  });
});

describe("findGame", () => {
  it("등재 조회는 디스크립터를, 미등재는 undefined 를 돌려준다", () => {
    expect(findGame("dagul")?.titleKey).toBe("games.dagul.title");
    expect(findGame("nope")).toBeUndefined();
  });
});

describe("defaultModeOf", () => {
  it("등재 게임의 defaultMode 를 돌려준다", () => {
    expect(defaultModeOf(asGameId("dagul"))).toBe("classic");
    expect(defaultModeOf(asGameId("sparring"))).toBe("default");
  });

  it("대기실 표기 키는 서버 mode 원문과 대응한다", () => {
    expect(modeI18nKey("classic")).toBe("classic");
    expect(modeI18nKey("full")).toBe("full");
    expect(modeI18nKey("default")).toBe("default");
    expect(modeI18nKey("unknown-mode")).toBeNull();
  });
});
