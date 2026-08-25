import { describe, expect, it } from "vitest";
import { displayNameOf, downloadStartsInRoom, phaseAfterMatchEnd, phaseFromHubStatus, shouldShowConnectionLost } from "@/lib/game-flow-state";
import type { GamePhase, HubStatus } from "@/types";

const HUB_STATUSES: HubStatus[] = ["offline", "connecting", "lobby", "in-room", "playing"];
const PHASES: GamePhase[] = ["intro", "lobby", "room", "playing"];

describe("phaseFromHubStatus — 전 조합 전수 검증", () => {
  it.each(HUB_STATUSES)("status=%s → 전이 규칙", (status) => {
    for (const current of PHASES) {
      const next = phaseFromHubStatus(status, current);
      if (status === "in-room") {expect(next).toBe("room");}
      else if (status === "playing") {expect(next).toBe("playing");}
      else {expect(next).toBe(current);} // 나머지 상태는 현재 페이즈 유지
    }
  });
});

describe("phaseAfterMatchEnd", () => {
  it.each(["playing", "in-room", "lobby"] as HubStatus[])("연결 생존(%s) → 로비", (status) => {
    expect(phaseAfterMatchEnd(status)).toBe("lobby");
  });

  it.each(["offline", "connecting"] as HubStatus[])("연결 단절(%s) → 인트로", (status) => {
    expect(phaseAfterMatchEnd(status)).toBe("intro");
  });
});

describe("displayNameOf", () => {
  it("입력값 우선", () => {expect(displayNameOf("  다굴  ", "기본")).toBe("다굴");});
  it("빈 값은 기본 플레이어", () => {
    expect(displayNameOf("", "기본")).toBe("기본");
    expect(displayNameOf("   ", "기본")).toBe("기본");
  });
});

describe("shouldShowConnectionLost — 모달 표시 조건", () => {
  it("인트로(접속 전) 오프라인은 모달 아님", () => {
    expect(shouldShowConnectionLost("offline", "intro")).toBe(false);
  });

  it.each(["lobby", "room", "playing"] as GamePhase[])("진행 중(%s) 오프라인은 모달", (phase) => {
    expect(shouldShowConnectionLost("offline", phase)).toBe(true);
  });

  it.each(["connecting", "lobby", "in-room", "playing"] as HubStatus[])("오프라인이 아니면(%s) 모달 아님", (status) => {
    expect(shouldShowConnectionLost(status, "lobby")).toBe(false);
  });
});

describe("downloadStartsInRoom — 유즈맵 다운로드 시점", () => {
  it("대기실에서만 시작한다", () => {
    expect(downloadStartsInRoom("room")).toBe(true);
  });

  it.each(["intro", "lobby", "playing"] as GamePhase[])("방 밖(%s)에서는 시작하지 않는다", (phase) => {
    expect(downloadStartsInRoom(phase)).toBe(false);
  });
});
