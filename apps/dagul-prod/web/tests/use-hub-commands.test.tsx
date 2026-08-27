// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { HANDOFF, ROOM_LEAVE, WEB_STORE } from "@/lib/contract";
import { useHubCommands } from "@/hooks/useHubCommands";
import { lastInboundSnapOf, rememberInboundSnap, resetInboundSnapForTests } from "@/lib/hub/page-bridge";
import type { Room } from "@colyseus/sdk";

afterEach(() => {
  localStorage.clear();
  sessionStorage.clear();
  resetInboundSnapForTests();
});

describe("useHubCommands returnToLobby", () => {
  it("매치 종료 로비 복귀는 resume 을 폐기하고 방을 떠난다", () => {
    sessionStorage.setItem(HANDOFF.FROM_HUB, "1");
    sessionStorage.setItem(HANDOFF.MATCH, "{}");
    sessionStorage.setItem(HANDOFF.RESUME, "tok");
    localStorage.setItem(WEB_STORE.MY_ROOM, JSON.stringify({ roomId: "r1", host: true }));
    const leave = vi.fn();
    const room = { leave } as unknown as Room;
    const setJoinRequest = vi.fn();
    const setMatchInfo = vi.fn();
    const { result } = renderHook(() => useHubCommands(
      { current: "호스트" },
      room,
      setJoinRequest,
      setMatchInfo,
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
    ));
    act(() => {result.current.returnToLobby("호스트");});
    expect(sessionStorage.getItem(HANDOFF.RESUME)).toBeNull();
    expect(sessionStorage.getItem(HANDOFF.FROM_HUB)).toBeNull();
    expect(localStorage.getItem(WEB_STORE.MY_ROOM)).toBeNull();
    expect(leave).toHaveBeenCalledWith(ROOM_LEAVE.CONSENTED);
    expect(setJoinRequest).toHaveBeenCalledWith(null);
  });

  it("매치가 끝나지 않았으면 tryResume 이 resume 토큰을 유지한다", () => {
    sessionStorage.setItem(HANDOFF.RESUME, "tok");
    const setJoinRequest = vi.fn();
    const { result } = renderHook(() => useHubCommands(
      { current: "" },
      undefined,
      setJoinRequest,
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
    ));
    expect(result.current.tryResume()).toBe(true);
    expect(sessionStorage.getItem(HANDOFF.RESUME)).toBe("tok");
    expect(setJoinRequest).toHaveBeenCalledWith({ kind: "resume" });
  });
});

describe("useHubCommands leaveRoom", () => {
  it("방 이탈 시 lastInboundSnap 을 비운다", () => {
    rememberInboundSnap({ tick: 7, winner: 1 });
    expect(lastInboundSnapOf()).toEqual({ tick: 7, winner: 1 });
    const { result } = renderHook(() => useHubCommands(
      { current: "호스트" },
      undefined,
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
    ));
    act(() => {result.current.leaveRoom();});
    expect(lastInboundSnapOf()).toBeNull();
  });
});

describe("useHubCommands forgetMyRoom", () => {
  // 회귀: 로비 목록에서 내 방(살아있지만 연결 안 된)을 버리고 다른 방으로 갈 때
  // room.leave() 를 부르면 안 된다 — 지금 그 방에 붙어 있는 소켓이 없다.
  it("소켓을 안 건들이고 로컬 myRoom 표시만 지운다", () => {
    localStorage.setItem(WEB_STORE.MY_ROOM, JSON.stringify({ roomId: "r1", host: true }));
    const leave = vi.fn();
    const room = { leave } as unknown as Room;
    const { result } = renderHook(() => useHubCommands(
      { current: "호스트" },
      room,
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
      vi.fn(),
    ));
    act(() => {result.current.forgetMyRoom();});
    expect(localStorage.getItem(WEB_STORE.MY_ROOM)).toBeNull();
    expect(leave).not.toHaveBeenCalled();
  });
});
