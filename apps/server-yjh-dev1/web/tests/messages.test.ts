// KO 사용자 문구 · MODES 정합 — 안내문 계약의 회귀 방지.
import { describe, expect, it } from "vitest";
import { KO, MODES, HUB_CONFIG } from "@/lib/hub/config";

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

describe("MODES 모드 사전", () => {
  it("기본 모드(defaultMode)는 MODES 에 실재한다", () => {
    expect(MODES[HUB_CONFIG.defaultMode]).toBeDefined();
  });

  it("각 모드는 id·제목·설명을 갖춘다", () => {
    for (const mode of Object.values(MODES)) {
      expect(mode.id.length).toBeGreaterThan(0);
      expect(mode.title.length).toBeGreaterThan(0);
      expect(mode.blurb.length).toBeGreaterThan(0);
    }
  });
});
