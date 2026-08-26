// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { DOM_EVT, MSG } from "@/lib/contract";
import { encodeBridgePacket } from "@/lib/hub/page-bridge";
import { usePageBridge } from "@/hooks/usePageBridge";
import type { MatchInfo } from "@/types";
import type { RosterSnapshot } from "@dalsoop/hub-kernel";
import type { Room } from "@colyseus/sdk";

const inbound = new Map<string, (raw: unknown) => void>();

vi.mock("@colyseus/react", () => ({
  useRoomMessage: (
    room: { roomId?: string } | undefined,
    type: string,
    cb: (raw: unknown) => void,
  ): void => {
    if (room) {inbound.set(type, cb);}
    else {inbound.delete(type);}
  },
}));

const matchInfo: MatchInfo = {
  roomId: "r1",
  name: "호스트",
  slot: 0,
  resumeToken: "tok",
};

const snap: RosterSnapshot = {
  phase: "playing",
  hostSessionId: "s1",
  players: [{ slot: 0, sessionId: "s1", name: "호스트", connected: true }],
};

afterEach(() => {
  inbound.clear();
});

describe("usePageBridge", () => {
  it("엔진 HOST_SNAP 을 room.send 로 넘긴다", () => {
    const send = vi.fn();
    const leave = vi.fn();
    const room = { roomId: "r1", sessionId: "s1", send, leave } as unknown as Room;
    renderHook(() => usePageBridge(room, matchInfo, snap));
    act(() => {
      window.dispatchEvent(new CustomEvent(DOM_EVT.FROM_ENGINE, {
        detail: encodeBridgePacket(MSG.HOST_SNAP, { tick: 2 }),
      }));
    });
    expect(send).toHaveBeenCalledWith(MSG.HOST_SNAP, { tick: 2 });
    expect(leave).not.toHaveBeenCalled();
  });

  it("허브 SNAP 은 TO_ENGINE 으로 나간다", () => {
    const seen: string[] = [];
    const onTo = (ev: Event): void => {seen.push(String((ev as CustomEvent).detail));};
    window.addEventListener(DOM_EVT.TO_ENGINE, onTo);
    const room = { roomId: "r1", sessionId: "s1", send: vi.fn(), leave: vi.fn() } as unknown as Room;
    renderHook(() => usePageBridge(room, matchInfo, snap));
    act(() => {inbound.get(MSG.SNAP)?.({ t: 3 });});
    expect(seen.some((d) => d.includes(MSG.SNAP) && d.includes("3"))).toBe(true);
    window.removeEventListener(DOM_EVT.TO_ENGINE, onTo);
  });

  it("반전: matchInfo 없으면 엔진 출력을 허브로 보내지 않는다", () => {
    const send = vi.fn();
    const room = { roomId: "r1", sessionId: "s1", send, leave: vi.fn() } as unknown as Room;
    renderHook(() => usePageBridge(room, null, snap));
    act(() => {
      window.dispatchEvent(new CustomEvent(DOM_EVT.FROM_ENGINE, {
        detail: encodeBridgePacket(MSG.HOST_SNAP, { tick: 9 }),
      }));
    });
    expect(send).not.toHaveBeenCalled();
  });
});
