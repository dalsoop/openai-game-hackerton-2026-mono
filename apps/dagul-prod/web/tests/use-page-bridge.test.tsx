// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { DOM_EVT, MSG } from "@/lib/contract";
import { encodeBridgePacket } from "@/lib/hub/page-bridge";
import { usePageBridge } from "@/hooks/usePageBridge";
import type { MatchInfo } from "@/types";
import type { RosterSnapshot } from "@/lib/domain/roster";
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
  it("엔진 INPUT 을 room.send 로 넘긴다", () => {
    const send = vi.fn();
    const leave = vi.fn();
    const room = { roomId: "r1", sessionId: "s1", send, leave } as unknown as Room;
    renderHook(() => usePageBridge(room, matchInfo, snap));
    act(() => {
      window.dispatchEvent(new CustomEvent(DOM_EVT.FROM_ENGINE, {
        detail: encodeBridgePacket(MSG.INPUT, { mx: 1 }),
      }));
    });
    expect(send).toHaveBeenCalledWith(MSG.INPUT, { mx: 1 });
    expect(leave).not.toHaveBeenCalled();
  });

  it("허브 SNAP 은 TO_ENGINE 으로 나간다", async () => {
    // postToEngine 이 requestAnimationFrame 으로 디스패치를 미루므로(page-bridge.ts)
    // 한 프레임 흘려보내야 이벤트가 도착한다.
    const seen: string[] = [];
    const onTo = (ev: Event): void => {seen.push(String((ev as CustomEvent).detail));};
    window.addEventListener(DOM_EVT.TO_ENGINE, onTo);
    const room = { roomId: "r1", sessionId: "s1", send: vi.fn(), leave: vi.fn() } as unknown as Room;
    renderHook(() => usePageBridge(room, matchInfo, snap));
    await act(async () => {
      inbound.get(MSG.SNAP)?.({ t: 3 });
      await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
    });
    expect(seen.some((d) => d.includes(MSG.SNAP) && d.includes("3"))).toBe(true);
    window.removeEventListener(DOM_EVT.TO_ENGINE, onTo);
  });

  it("브릿지 부착·해제 때 SNAP_ON 을 보내 재접속 세션 opt-out 을 푼다", async () => {
    const send = vi.fn();
    const room = {
      roomId: "r1", sessionId: "s1", send, leave: vi.fn(),
      connection: { isOpen: true },
    } as unknown as Room;
    const view = renderHook(() => usePageBridge(room, matchInfo, snap));
    expect(send).toHaveBeenCalledWith(MSG.SNAP_ON, {});
    view.unmount();
    await act(async () => {await Promise.resolve();});
    expect(send.mock.calls.filter((c) => c[0] === MSG.SNAP_ON)).toHaveLength(2);
  });

  it("반전: 닫힌 소켓에는 해제 SNAP_ON 을 보내지 않는다", async () => {
    const conn = { isOpen: true };
    const send = vi.fn((_type?: string, _payload?: unknown) => {
      if (!conn.isOpen) {throw new Error("closed");}
    });
    const room = {
      roomId: "r1", sessionId: "s1", send, leave: vi.fn(), connection: conn,
    } as unknown as Room;
    const view = renderHook(
      ({ info }) => usePageBridge(room, info, snap),
      { initialProps: { info: matchInfo as MatchInfo | null } },
    );
    expect(send).toHaveBeenCalledWith(MSG.SNAP_ON, {});
    conn.isOpen = false;
    view.rerender({ info: null });
    await act(async () => {await Promise.resolve();});
    expect(send.mock.calls.filter((c) => c[0] === MSG.SNAP_ON)).toHaveLength(1);
  });

  it("matchInfo 객체 신원만 바뀌면 SNAP_ON 을 다시 보내지 않는다", async () => {
    const send = vi.fn();
    const room = { roomId: "r1", sessionId: "s1", send, leave: vi.fn() } as unknown as Room;
    const view = renderHook(
      ({ info }) => usePageBridge(room, info, snap),
      { initialProps: { info: matchInfo } },
    );
    expect(send.mock.calls.filter((c) => c[0] === MSG.SNAP_ON)).toHaveLength(1);
    view.rerender({ info: { ...matchInfo } });
    await act(async () => {await Promise.resolve();});
    expect(send.mock.calls.filter((c) => c[0] === MSG.SNAP_ON)).toHaveLength(1);
  });

  it("반전: matchInfo 없으면 엔진 출력을 허브로 보내지 않는다", () => {
    const send = vi.fn();
    const room = { roomId: "r1", sessionId: "s1", send, leave: vi.fn() } as unknown as Room;
    renderHook(() => usePageBridge(room, null, snap));
    act(() => {
      window.dispatchEvent(new CustomEvent(DOM_EVT.FROM_ENGINE, {
        detail: encodeBridgePacket(MSG.INPUT, { mx: 1 }),
      }));
    });
    expect(send).not.toHaveBeenCalled();
  });
});
