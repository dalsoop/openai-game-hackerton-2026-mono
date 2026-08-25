// 방 설정 계약(room-options) — 서버와 클라가 공유하는 정규화 규칙의 회귀 방지.
import { describe, expect, it } from "vitest";
import { parsePlayerName, parseRoomTitle, parseRoomSettings, hubLimits } from "@/lib/hub/room-options";
import { DEFAULT_GAME_ID } from "@/lib/games/catalog";
import { HUB_CONFIG } from "@/lib/hub/config";

describe("parsePlayerName — 표시명 소독", () => {
  it("특수문자 제거·트림·길이 컷", () => {
    expect(parsePlayerName("  한스 ", 12, "손님")).toBe("한스");
    expect(parsePlayerName("<script>", 12, "손님")).toBe("script");
    expect(parsePlayerName("가".repeat(20), 12, "손님")).toHaveLength(12);
  });

  it("빈 값·불량은 기본명으로", () => {
    expect(parsePlayerName("", 12, "손님")).toBe("손님");
    expect(parsePlayerName(null, 12, "손님")).toBe("손님");
  });
});

describe("parseRoomTitle — 제목", () => {
  it("소독 후 빈 값이면 fallback", () => {
    expect(parseRoomTitle("  우리방 ", 24, "기본")).toBe("우리방");
    expect(parseRoomTitle("   ", 24, "기본 #1")).toBe("기본 #1");
  });
});

describe("parseRoomSettings — 일괄 정규화", () => {
  const limits = { maxTitle: 24, maxName: 12, defaultName: "손님", fallbackTitle: "기본방" };

  it("전체 필드 정규화", () => {
    const s = parseRoomSettings({ game: "dagul", title: "우리방", name: "한스"}, limits);
    expect(s.game).toBe("dagul");
    expect(s.title).toBe("우리방");
    expect(s.name).toBe("한스");
  });

  it("미등재 게임·불량 값은 기본으로 수렴", () => {
    const s = parseRoomSettings({ game: "없는게임"}, limits);
    expect(s.game).toBe(DEFAULT_GAME_ID);
    expect(s.title).toBe("기본방");
    expect(s.name).toBe("손님");
  });
});

describe("hubLimits — 한도는 HUB_CONFIG 정본", () => {
  it("길이·기본명을 config 에서 가져오고 fallback 만 호출부가 정한다", () => {
    const limits = hubLimits("합본 #room");
    expect(limits.maxTitle).toBe(HUB_CONFIG.maxTitleLength);
    expect(limits.maxName).toBe(HUB_CONFIG.maxNameLength);
    expect(limits.defaultName).toBe(HUB_CONFIG.defaultName);
    expect(limits.fallbackTitle).toBe("합본 #room");
  });

  it("parseRoomSettings 와 같이 쓰면 빈 제목이 fallback 으로 간다", () => {
    const s = parseRoomSettings({ name: "한스" }, hubLimits("합본 #1"));
    expect(s.title).toBe("합본 #1");
    expect(s.name).toBe("한스");
    expect(s.game).toBe(DEFAULT_GAME_ID);
  });
});
