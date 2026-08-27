// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { HANDOFF, ROOM_LEAVE, WEB_STORE } from "@/lib/contract";
import { useHubCommands } from "@/hooks/useHubCommands";
import type { Room } from "@colyseus/sdk";

afterEach(() => {
  localStorage.clear();
  sessionStorage.clear();
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
