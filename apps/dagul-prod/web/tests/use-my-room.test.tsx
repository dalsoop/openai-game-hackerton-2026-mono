// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import { WEB_STORE } from "@/lib/contract";
import { useMyRoom } from "@/hooks/useMyRoom";

afterEach(() => {
  localStorage.clear();
});

describe("useMyRoom", () => {
  it("파생 방이 있으면 저장하고 그 식별자를 쓴다", () => {
    const { result } = renderHook(() => useMyRoom({ roomId: "live", isHost: true }, [], false));
    expect(result.current).toEqual({ roomId: "live", host: true });
    expect(JSON.parse(localStorage.getItem(WEB_STORE.MY_ROOM) ?? "null")).toEqual({
      roomId: "live", host: true,
    });
  });

  it("목록에 없는 저장 id 는 유령이라 로비에 내 방으로 안 내려준다", () => {
    localStorage.setItem(WEB_STORE.MY_ROOM, JSON.stringify({ roomId: "ghost", host: true }));
    const { result } = renderHook(() => useMyRoom(null, [], true));
    expect(result.current).toBeNull();
  });

  it("목록이 준비되고 방이 없으면 저장소에서 지운다", () => {
    localStorage.setItem(WEB_STORE.MY_ROOM, JSON.stringify({ roomId: "ghost", host: true }));
    renderHook(() => useMyRoom(null, [], true));
    expect(localStorage.getItem(WEB_STORE.MY_ROOM)).toBeNull();
  });

  it("목록에 있으면 저장 식별자를 유지한다", () => {
    localStorage.setItem(WEB_STORE.MY_ROOM, JSON.stringify({ roomId: "mine", host: false }));
    const { result } = renderHook(() => useMyRoom(null, [{ id: "mine" }], true));
    expect(result.current).toEqual({ roomId: "mine", host: false });
    expect(localStorage.getItem(WEB_STORE.MY_ROOM)).toContain("mine");
  });

  it("목록이 아직이면 저장소를 비우지 않는다", () => {
    localStorage.setItem(WEB_STORE.MY_ROOM, JSON.stringify({ roomId: "mine", host: true }));
    renderHook(() => useMyRoom(null, [], false));
    expect(localStorage.getItem(WEB_STORE.MY_ROOM)).toContain("mine");
  });

  it("목록이 나중에 비면 유령을 지운다", () => {
    localStorage.setItem(WEB_STORE.MY_ROOM, JSON.stringify({ roomId: "mine", host: true }));
    const { result, rerender } = renderHook(
      ({ rooms, ready }) => useMyRoom(null, rooms, ready),
      { initialProps: { rooms: [{ id: "mine" }], ready: true } },
    );
    expect(result.current?.roomId).toBe("mine");
    act(() => {rerender({ rooms: [], ready: true });});
    expect(result.current).toBeNull();
    expect(localStorage.getItem(WEB_STORE.MY_ROOM)).toBeNull();
  });
});
