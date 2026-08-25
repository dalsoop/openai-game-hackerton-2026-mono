import { describe, expect, it } from "vitest";
import { displayNameOf, downloadStartsInRoom, phaseAfterMatchEnd, phaseFromHubStatus, reconnectJoinId, shouldMarkRoomDropped, shouldShowConnectionLost, shouldShowReconnect } from "@/lib/game-flow-state";
import type { GamePhase, HubStatus } from "@/types";

const HUB_STATUSES: HubStatus[] = ["offline", "connecting", "lobby", "in-room", "playing"];
const PHASES: GamePhase[] = ["intro", "lobby", "room", "playing"];

describe("phaseFromHubStatus — 전 조합 전수 검증", () => {
  it.each(HUB_STATUSES)("status=%s → 전이 규칙", (status) => {
    for (const current of PHASES) {
      const next = phaseFromHubStatus(status, current);
      if (status === "in-room") {expect(next).toBe("room");}
      else if (status === "playing") {expect(next).toBe("playing");}
      else if (current === "room" && status === "offline") {expect(next).toBe("intro");}
      else if (current === "room") {expect(next).toBe("lobby");}
      else {expect(next).toBe(current);}
    }
  });

  it("대기실에서 강퇴되면 로비로 돌아간다 — 빈 대기실을 붙잡지 않는다", () => {
    expect(phaseFromHubStatus("lobby", "room")).toBe("lobby");
    expect(phaseFromHubStatus("connecting", "room")).toBe("lobby");
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

describe("shouldMarkRoomDropped — Godot 양도는 튕김이 아님", () => {
  it("handoff 는 dropReason 을 남기지 않는다", () => {
    expect(shouldMarkRoomDropped("handoff")).toBe(false);
  });

  it("그 외 onLeave 는 강제 퇴장이다", () => {
    expect(shouldMarkRoomDropped("drop")).toBe(true);
  });
});

describe("shouldShowReconnect — 회색 화면 대신 모달", () => {
  it("강퇴·강제 퇴장은 허브 상태와 무관하게 모달", () => {
    expect(shouldShowReconnect("lobby", "lobby", "kicked")).toBe(true);
    expect(shouldShowReconnect("in-room", "room", "dropped")).toBe(true);
  });

  it("이유가 없으면 기존 오프라인 규칙을 따른다", () => {
    expect(shouldShowReconnect("offline", "intro", null)).toBe(false);
    expect(shouldShowReconnect("offline", "lobby", null)).toBe(true);
    expect(shouldShowReconnect("lobby", "lobby", null)).toBe(false);
  });

  it("핸드오프 직후(playing·이유 없음)는 캔버스를 가리지 않는다", () => {
    expect(shouldShowReconnect("playing", "playing", null)).toBe(false);
  });
});

describe("reconnectJoinId — 재접속 대상", () => {
  it("강퇴는 로비만 — 닫힌 방으로 들어가지 않는다", () => {
    expect(reconnectJoinId("kicked", "abc")).toBeNull();
  });

  it("끊김은 마지막 방으로 다시 들어간다", () => {
    expect(reconnectJoinId("dropped", "abc")).toBe("abc");
    expect(reconnectJoinId("offline", "abc")).toBe("abc");
    expect(reconnectJoinId("dropped", "")).toBeNull();
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
