import { describe, expect, it } from "vitest";
import { CLOSE_CODE } from "@/lib/contract";
import {
  canOfferReconnect,
  dropReasonFromKick,
  reconnectJoinId,
  roomEndKindFromCode,
  shouldMarkRoomDropped,
  shouldShowReconnect,
} from "@/lib/hub/room-end";

describe("roomEndKindFromCode", () => {
  it("CONSENTED(강퇴 close 와 같은 코드)는 동의 퇴장이다", () => {
    expect(roomEndKindFromCode(CLOSE_CODE.CONSENTED)).toBe("consented");
  });

  it("그 외 코드는 튕김이다", () => {
    expect(roomEndKindFromCode(1001)).toBe("drop");
    expect(roomEndKindFromCode(undefined)).toBe("drop");
  });
});

describe("shouldMarkRoomDropped", () => {
  it("양도와 동의 퇴장은 모달을 남기지 않는다", () => {
    expect(shouldMarkRoomDropped("handoff")).toBe(false);
    expect(shouldMarkRoomDropped("consented")).toBe(false);
  });

  it("비동의 onLeave 만 dropReason 후보이다", () => {
    expect(shouldMarkRoomDropped("drop")).toBe(true);
  });
});

describe("dropReasonFromKick", () => {
  it("reason=idle 만 유휴로 본다", () => {
    expect(dropReasonFromKick({ msg: "x", reason: "idle" })).toBe("idle");
    expect(dropReasonFromKick({ msg: "x" })).toBe("kicked");
    expect(dropReasonFromKick(null)).toBe("kicked");
  });

  it("reason=takeover 는 좌석 이어받기 안내다 — 재접속 제안 없음", () => {
    expect(dropReasonFromKick({ msg: "x", reason: "takeover" })).toBe("takeover");
    expect(canOfferReconnect("takeover")).toBe(false);
    expect(reconnectJoinId("takeover", "abc")).toBeNull();
  });

  it("reason=load-wait 는 로딩 타임아웃 퇴장이다 — 재접속 제안 없음", () => {
    expect(dropReasonFromKick({ msg: "x", reason: "load-wait" })).toBe("load-wait");
    expect(canOfferReconnect("load-wait")).toBe(false);
    expect(reconnectJoinId("load-wait", "abc")).toBeNull();
  });
});

describe("canOfferReconnect / reconnectJoinId", () => {
  it("끊김·오프라인만 마지막 방으로 다시 들어간다", () => {
    expect(canOfferReconnect("dropped")).toBe(true);
    expect(canOfferReconnect("offline")).toBe(true);
    expect(canOfferReconnect("kicked")).toBe(false);
    expect(canOfferReconnect("idle")).toBe(false);
    expect(canOfferReconnect("load-wait")).toBe(false);
    expect(reconnectJoinId("dropped", "abc")).toBe("abc");
    expect(reconnectJoinId("idle", "abc")).toBeNull();
    expect(reconnectJoinId("kicked", "abc")).toBeNull();
    expect(reconnectJoinId("dropped", "")).toBeNull();
  });
});

describe("shouldShowReconnect", () => {
  it("강퇴·유휴·끊김은 허브 상태와 무관하게 모달", () => {
    expect(shouldShowReconnect("lobby", "lobby", "kicked")).toBe(true);
    expect(shouldShowReconnect("lobby", "lobby", "idle")).toBe(true);
    expect(shouldShowReconnect("in-room", "room", "dropped")).toBe(true);
  });

  it("이유가 없으면 오프라인 규칙을 따른다", () => {
    expect(shouldShowReconnect("offline", "intro", null)).toBe(false);
    expect(shouldShowReconnect("offline", "lobby", null)).toBe(true);
    expect(shouldShowReconnect("lobby", "lobby", null)).toBe(false);
  });

  it("핸드오프 직후(playing·이유 없음)는 캔버스를 가리지 않는다", () => {
    expect(shouldShowReconnect("playing", "playing", null)).toBe(false);
  });
});
