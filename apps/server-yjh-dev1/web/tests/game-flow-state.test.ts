import { describe, expect, it } from "vitest";
import { displayNameOf, phaseAfterMatchEnd, phaseFromHubStatus } from "@/lib/game-flow-state";
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
