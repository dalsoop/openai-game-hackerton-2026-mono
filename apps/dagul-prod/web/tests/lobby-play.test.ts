import { afterEach, describe, expect, it, vi } from "vitest";
import type { Client } from "colyseus";
import { HUB_CONFIG, MSG } from "@/lib/hub/config";
import { commitTickSnap, scheduleLobbyReset } from "@/lib/hub/lobby-play";
import { LobbyState } from "@/lib/hub/lobby-state";
import type { LobbyBag, LobbyHandle } from "@/lib/hub/lobby-waiting";

function clientOf(sessionId: string, send: ReturnType<typeof vi.fn>): Client {
  return { sessionId, send } as unknown as Client;
}

function roomOf(state: LobbyState, extra: Partial<LobbyHandle> = {}): LobbyHandle {
  return {
    state,
    clients: [],
    metadata: {},
    setMetadata: vi.fn(),
    clock: {
      setTimeout: (cb: () => void, ms: number): { clear: () => void } => {
        const id = setTimeout(cb, ms);
        return { clear: (): void => {clearTimeout(id);} };
      },
    },
    broadcast: vi.fn(),
    ...extra,
  };
}

function emptyBag(): LobbyBag {
  return {
    lastSnap: null, prevSnap: null, gameTimer: null, idleTimer: null,
    authority: null, hostLossTimer: null,
  };
}

describe("scheduleLobbyReset", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("승패 직후 10초는 playing, 끝나면 전원 lobby", () => {
    vi.useFakeTimers();
    const state = new LobbyState();
    state.phase = "playing";
    state.seed = 42;
    const room = roomOf(state);
    const bag: LobbyBag = {
      lastSnap: { result: "won" },
      prevSnap: { result: "playing" },
      gameTimer: null,
      idleTimer: null,
      authority: null,
      hostLossTimer: null,
    };
    scheduleLobbyReset(room, bag);
    expect(state.phase).toBe("playing");
    vi.advanceTimersByTime(HUB_CONFIG.resetToLobbyDelayMs - 1);
    expect(state.phase).toBe("playing");
    vi.advanceTimersByTime(1);
    expect(state.phase).toBe("lobby");
    expect(state.seed).toBe(0);
  });
});

describe("commitTickSnap opt-out", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("SNAP_OFF 세션에는 스냅을 안 보내고 SNAP_ON 후 다시 보낸다", () => {
    const sent: Array<{ id: string; type: string }> = [];
    const sendA = vi.fn((type: string) => {sent.push({ id: "a", type });});
    const sendB = vi.fn((type: string) => {sent.push({ id: "b", type });});
    const optOut = new Set<string>(["a"]);
    const room = roomOf(new LobbyState(), {
      clients: [clientOf("a", sendA), clientOf("b", sendB)],
      snapOptOut: optOut,
    });
    const bag = emptyBag();
    commitTickSnap(room, bag, { tick: 1, result: "playing" });
    expect(sendA).not.toHaveBeenCalled();
    expect(sendB).toHaveBeenCalledWith(MSG.SNAP, { tick: 1, result: "playing" });
    optOut.delete("a");
    commitTickSnap(room, bag, { tick: 2, result: "playing" });
    expect(sendA).toHaveBeenCalledWith(MSG.SNAP, { tick: 2, result: "playing" });
    expect(sent.filter((row) => row.id === "a")).toHaveLength(1);
  });

  it("전원이 opt-out 이면 send 하지 않고 승패 판정은 유지한다", () => {
    vi.useFakeTimers();
    const send = vi.fn();
    const state = new LobbyState();
    state.phase = "playing";
    const room = roomOf(state, {
      clients: [clientOf("eng", send)],
      snapOptOut: new Set(["eng"]),
    });
    const bag = emptyBag();
    bag.lastSnap = { result: "playing" };
    commitTickSnap(room, bag, { result: "won" });
    expect(send).not.toHaveBeenCalled();
    expect(state.phase).toBe("playing");
    vi.advanceTimersByTime(HUB_CONFIG.resetToLobbyDelayMs);
    expect(state.phase).toBe("lobby");
  });
});
