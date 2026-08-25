// 게임 카탈로그 도메인 — 유즈맵 모델의 정본 계약.
import { describe, expect, it } from "vitest";
import { GAME_CATALOG, DEFAULT_GAME_ID, asGameId, isKnownGame, findGame } from "@/lib/games/catalog";

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
    }
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
