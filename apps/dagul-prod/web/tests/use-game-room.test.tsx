// @vitest-environment jsdom
import { act, renderHook, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useState, useEffect } from "react";
import { HANDOFF, MSG } from "@/lib/contract";
import { useGameRoom } from "@/hooks/useGameRoom";
import type { Client } from "@colyseus/sdk";

type Handler = (raw: unknown) => void;

interface FakeRoom {
  roomId: string;
  sessionId: string;
  reconnectionToken: string;
  connection: { url: string };
  state: { gameId: string };
  leave: ReturnType<typeof vi.fn>;
  send: ReturnType<typeof vi.fn>;
  onMessage: (type: string, cb: Handler) => void;
  onLeave: (cb: (code?: number) => void) => void;
  emit: (type: string, raw: unknown) => void;
  drop: (code?: number) => void;
}

function makeRoom(): FakeRoom {
  const messages = new Map<string, Handler>();
  let leaveCb: ((code?: number) => void) | undefined;
  const leave = vi.fn();
  return {
    roomId: "r1",
    sessionId: "s1",
    reconnectionToken: "tok",
    connection: { url: "" },
    state: { gameId: "dagul" },
    leave,
    send: vi.fn(),
    onMessage: (type: string, cb: Handler): void => {messages.set(type, cb);},
    onLeave: (cb: (code?: number) => void): void => {leaveCb = cb;},
    emit: (type: string, raw: unknown): void => {messages.get(type)?.(raw);},
    drop: (code?: number): void => {leaveCb?.(code);},
  };
}

vi.mock("@colyseus/react", () => ({
  useRoom: (factory: (() => Promise<unknown>) | null): { room: unknown; error: Error | undefined } => {
    const [room, setRoom] = useState<unknown>(undefined);
    const [error, setError] = useState<Error | undefined>(undefined);
    const enabled = factory !== null;
    useEffect(() => {
      if (!factory) {
        setRoom(undefined);
        return;
      }
      let cancelled = false;
      void factory().then((next) => {
        if (!cancelled) {setRoom(next);}
      }).catch((err: Error) => {
        if (!cancelled) {setError(err);}
      });
      return (): void => {cancelled = true;};
    }, [enabled, factory]);
    return { room, error };
  },
}));

const startBody = {
  you: 0,
  host: true,
  seed: 42,
  mode: "full",
  seats: [{ slot: 0, name: "호스트", connected: true }],
};

afterEach(() => {
  localStorage.clear();
  sessionStorage.clear();
  vi.unstubAllGlobals();
});

describe("useGameRoom START", () => {
  it("START 후에도 leave 하지 않고 matchInfo 만 남긴다", async () => {
    const room = makeRoom();
    const onEnded = vi.fn();
    const joinRequest = { kind: "create" as const, game: "dagul" };
    const { result } = renderHook(() => useGameRoom(
      joinRequest,
      () => "호스트",
      () => ({ create: () => Promise.resolve(room) }) as unknown as Client,
      onEnded,
      vi.fn(),
    ));
    await waitFor(() => {expect(result.current.room).toBe(room);});
    act(() => {room.emit(MSG.START, startBody);});
    expect(room.leave).not.toHaveBeenCalled();
    expect(result.current.matchInfo?.slot).toBe(0);
    expect(sessionStorage.getItem(HANDOFF.FROM_HUB)).toBe("1");
    expect(onEnded).not.toHaveBeenCalled();
  });

  it("반전: 깨진 START 는 방을 떠나지도 matchInfo 를 쓰지도 않는다", async () => {
    const room = makeRoom();
    const joinRequest = { kind: "create" as const };
    const { result } = renderHook(() => useGameRoom(
      joinRequest,
      () => "호스트",
      () => ({ create: () => Promise.resolve(room) }) as unknown as Client,
      vi.fn(),
      vi.fn(),
    ));
    await waitFor(() => {expect(result.current.room).toBe(room);});
    act(() => {room.emit(MSG.START, { you: 0, seed: 0 });});
    expect(room.leave).not.toHaveBeenCalled();
    expect(result.current.matchInfo).toBeNull();
  });

  it("저장된 MATCH 로 브릿지용 matchInfo 를 복원한다", async () => {
    sessionStorage.setItem(HANDOFF.MATCH, JSON.stringify(startBody));
    const room = makeRoom();
    const joinRequest = { kind: "resume" as const };
    const { result } = renderHook(() => useGameRoom(
      joinRequest,
      () => "호스트",
      () => ({ reconnect: () => Promise.resolve(room) }) as unknown as Client,
      vi.fn(),
      vi.fn(),
    ));
    await waitFor(() => {expect(result.current.matchInfo?.resumeToken).toBe("tok");});
    expect(room.leave).not.toHaveBeenCalled();
  });

  it("CONSENTED onLeave 는 consented 로 끝난다", async () => {
    const room = makeRoom();
    const onEnded = vi.fn();
    const joinRequest = { kind: "create" as const };
    const { result } = renderHook(() => useGameRoom(
      joinRequest,
      () => "호스트",
      () => ({ create: () => Promise.resolve(room) }) as unknown as Client,
      onEnded,
      vi.fn(),
    ));
    await waitFor(() => {expect(result.current.room).toBe(room);});
    const { CLOSE_CODE } = await import("@/lib/contract");
    act(() => {room.drop(CLOSE_CODE.CONSENTED);});
    expect(onEnded).toHaveBeenCalledWith("consented");
  });

  it("비동의 onLeave 는 drop 이다", async () => {
    const room = makeRoom();
    const onEnded = vi.fn();
    const joinRequest = { kind: "create" as const };
    const { result } = renderHook(() => useGameRoom(
      joinRequest,
      () => "호스트",
      () => ({ create: () => Promise.resolve(room) }) as unknown as Client,
      onEnded,
      vi.fn(),
    ));
    await waitFor(() => {expect(result.current.room).toBe(room);});
    act(() => {room.drop(1001);});
    expect(onEnded).toHaveBeenCalledWith("drop");
  });
});
