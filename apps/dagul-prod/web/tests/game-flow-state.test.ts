import { describe, expect, it } from "vitest";
import { displayNameOf, lobbyBgmOn, matchmakePending, packLoadStartsInRoom, godotMayHubReconnect, phaseAfterMatchEnd, phaseFromHubStatus, phaseOnMount, reactOwnsResume, shouldShowConnectionLost } from "@/lib/game-flow-state";
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

describe("lobbyBgmOn", () => {
  it("시작하기 화면만 켜고 로비·대기실·매치는 끈다", () => {
    expect(lobbyBgmOn("intro")).toBe(true);
    expect(lobbyBgmOn("lobby")).toBe(false);
    expect(lobbyBgmOn("room")).toBe(false);
    expect(lobbyBgmOn("playing")).toBe(false);
  });
});

describe("matchmakePending", () => {
  it("생성·입장 요청이 로비에 남아 있는 동안만 참", () => {
    expect(matchmakePending("create", "lobby")).toBe(true);
    expect(matchmakePending("join", "connecting")).toBe(true);
    expect(matchmakePending("create", "in-room")).toBe(false);
    expect(matchmakePending("join", "playing")).toBe(false);
    expect(matchmakePending("resume", "lobby")).toBe(false);
    expect(matchmakePending(null, "lobby")).toBe(false);
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

describe("reactOwnsResume — 허브 reconnect 주인은 React", () => {
  it("토큰이 있으면 FROM_HUB 와 무관하게 React 가 재개한다", () => {
    expect(reactOwnsResume(null, "room:tok")).toBe(true);
    expect(reactOwnsResume("1", "room:tok")).toBe(true);
  });

  it("반전: 옛 계약(FROM_HUB 면 Godot 가 토큰을 가져감)은 실패해야 한다", () => {
    expect(reactOwnsResume("1", "room:tok")).not.toBe(false);
  });

  it("토큰이 없으면 재개하지 않는다", () => {
    expect(reactOwnsResume(null, null)).toBe(false);
    expect(reactOwnsResume("1", "")).toBe(false);
  });
});

describe("godotMayHubReconnect", () => {
  it("반전: Godot 허브 reconnect 는 항상 금지", () => {
    expect(godotMayHubReconnect()).toBe(false);
  });
});

describe("phaseOnMount", () => {
  it("재개 성공이면 로비에서 허브 상태를 기다린다", () => {
    expect(phaseOnMount(true)).toBe("lobby");
  });

  it("반전: FROM_HUB 만으로 플레이에 들어가지 않는다", () => {
    expect(phaseOnMount(false)).toBeNull();
  });
});

describe("packLoadStartsInRoom — 유즈맵 팩 받기 시점", () => {
  it("대기실에서만 시작한다", () => {
    expect(packLoadStartsInRoom("room")).toBe(true);
  });

  it.each(["intro", "lobby", "playing"] as GamePhase[])("방 밖(%s)에서는 시작하지 않는다", (phase) => {
    expect(packLoadStartsInRoom(phase)).toBe(false);
  });
});
