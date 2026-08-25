import { describe, expect, it } from "vitest";
import { deriveStatus } from "@/lib/hub/status";
import type { MatchInfo } from "@/types";

const match: MatchInfo = { roomId: "r", name: "n", slot: 0, resumeToken: "t" };
const inRoom = { status: "in-room" as const };

describe("deriveStatus — 접속 상태 사다리", () => {
  it("매치 진행이 최상위 — 나머지 조건 무시", () => {
    expect(deriveStatus(null, false, undefined, false, match)).toBe("playing");
    expect(deriveStatus(inRoom, true, new Error("x"), true, match)).toBe("playing");
  });

  it("방 파생 상태가 다음 — 접속 시도 상태 무시", () => {
    expect(deriveStatus(inRoom, false, undefined, true, null)).toBe("in-room");
  });

  it("미접속 > 리스트 오류 > 연결 중 > 로비", () => {
    expect(deriveStatus(null, false, undefined, false, null)).toBe("offline");
    expect(deriveStatus(null, true, new Error("x"), false, null)).toBe("offline");
    expect(deriveStatus(null, true, undefined, true, null)).toBe("connecting");
    expect(deriveStatus(null, true, undefined, false, null)).toBe("lobby");
  });
});
