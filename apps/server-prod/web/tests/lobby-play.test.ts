import { afterEach, describe, expect, it, vi } from "vitest";
import { HUB_CONFIG } from "@/lib/hub/config";
import { scheduleLobbyReset } from "@/lib/hub/lobby-play";
import { LobbyState } from "@/lib/hub/lobby-state";
import type { LobbyBag, LobbyHandle } from "@/lib/hub/lobby-waiting";

function roomOf(state: LobbyState): LobbyHandle {
  return {
    state,
    clients: [],
    metadata: {},
    setMetadata: vi.fn(),
    clock: {
      setTimeout: (cb, ms) => {
        const id = setTimeout(cb, ms);
        return { clear: (): void => {clearTimeout(id);} };
      },
    },
    broadcast: vi.fn(),
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
