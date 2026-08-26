// KO 사용자 문구 정합 — 안내문 계약의 회귀 방지.
import { describe, expect, it } from "vitest";
import { KO, HUB_CONFIG } from "@/lib/hub/config";
import { listCharacters } from "@/lib/characters";
import ko from "../messages/ko.json";
import en from "../messages/en.json";

describe("KO 안내문 함수", () => {
  it("플레이어 입장/퇴장 문구에 이름이 들어간다", () => {
    expect(KO.playerJoined("한스")).toBe("한스 이(가) 들어왔습니다.");
    expect(KO.playerLeft("한스")).toBe("한스 이(가) 나갔습니다.");
  });

  it("연결 끊김 안내에 유예 초수가 표시된다", () => {
    expect(KO.playerDropped("한스", 30)).toContain("한스");
    expect(KO.playerDropped("한스", 30)).toContain("30");
  });

  it("호스트 이탈 안내에 이름이, 강퇴 안내에 사유가 들어간다", () => {
    expect(KO.hostLeftEnd("한스")).toContain("한스");
    expect(KO.KICKED_MSG.length).toBeGreaterThan(0);
  });

  it("ROOM_FULL 은 maxPlayers 와 함께 렌더링된다", () => {
    expect(KO.ROOM_FULL).toBe(`방이 가득 찼습니다 (${HUB_CONFIG.maxPlayers})`);
  });
});

describe("game.errors 문구 — ko/en 키 대칭", () => {
  it("엔진 오류 키가 양쪽 로케일에 같다", () => {
    expect(Object.keys(ko.game.errors).sort()).toEqual(Object.keys(en.game.errors).sort());
    expect(ko.game.errors.webgl2Missing.length).toBeGreaterThan(0);
    expect(en.game.errors.webgl2Missing.length).toBeGreaterThan(0);
  });
});

describe("create 문구 — ko/en 키 대칭", () => {
  it("방 만들기 페이지 키가 양쪽 로케일에 같다", () => {
    expect(Object.keys(ko.create).sort()).toEqual(Object.keys(en.create).sort());
    for (const key of Object.keys(ko.create) as Array<keyof typeof ko.create>) {
      expect(ko.create[key].length).toBeGreaterThan(0);
      expect(en.create[key].length).toBeGreaterThan(0);
    }
  });
});

describe("캐릭터 표시 키 — 카탈로그 titleKey 가 ko/en 에 있다", () => {
  it("정본 항목마다 양쪽 로케일 문구가 비어 있지 않다", () => {
    const read = (bag: Record<string, unknown>, dotted: string): unknown =>
      dotted.split(".").reduce<unknown>((cur, key) => (
        cur && typeof cur === "object" ? (cur as Record<string, unknown>)[key] : undefined
      ), bag);
    for (const item of listCharacters()) {
      const koVal = read(ko as unknown as Record<string, unknown>, item.titleKey);
      const enVal = read(en as unknown as Record<string, unknown>, item.titleKey);
      expect(typeof koVal, item.titleKey).toBe("string");
      expect(typeof enVal, item.titleKey).toBe("string");
      expect(String(koVal).length, item.titleKey).toBeGreaterThan(0);
      expect(String(enVal).length, item.titleKey).toBeGreaterThan(0);
    }
    expect(Object.keys(ko.characters).sort()).toEqual(Object.keys(en.characters).sort());
  });
});

describe("방 제목 폴백", () => {
  it("게임 무관 문구를 쓴다", () => {
    expect(KO.roomTitleFallback("abc")).toBe("방 #abc");
  });
});
