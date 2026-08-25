// KO 사용자 문구 정합 — 안내문 계약의 회귀 방지.
import { describe, expect, it } from "vitest";
import { KO, HUB_CONFIG } from "@/lib/hub/config";
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

describe("create 문구 — ko/en 키 대칭", () => {
  it("방 만들기 페이지 키가 양쪽 로케일에 같다", () => {
    expect(Object.keys(ko.create).sort()).toEqual(Object.keys(en.create).sort());
    for (const key of Object.keys(ko.create) as Array<keyof typeof ko.create>) {
      expect(ko.create[key].length).toBeGreaterThan(0);
      expect(en.create[key].length).toBeGreaterThan(0);
    }
  });
});

describe("방 제목 폴백", () => {
  it("게임 무관 문구를 쓴다", () => {
    expect(KO.roomTitleFallback("abc")).toBe("방 #abc");
  });
});
