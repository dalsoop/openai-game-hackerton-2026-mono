// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { lastInboundSnapOf, rememberInboundSnap, resetInboundSnapForTests } from "@/lib/hub/page-bridge";
import { useGameFlow } from "@/hooks/useGameFlow";
import type { HubStatus } from "@/types";

const hub = vi.hoisted(() => ({
  status: "offline" as HubStatus,
  gameId: "dagul",
  matchInfo: null,
  roomId: "",
  you: 0,
  resumeToken: "",
  tryResume: (): boolean => false,
  resumeFailed: false,
  dropReason: null,
  sendPackPct: (): void => {},
  connect: (): void => {},
  startMatch: (): void => {},
  disconnect: (): void => {},
  leaveRoom: vi.fn(),
  returnToLobby: vi.fn(),
}));

vi.mock("@/hooks/useHub", () => ({
  useHub: (): typeof hub => hub,
}));

vi.mock("@/hooks/useSession", () => ({
  useSession: (): {
    nickname: string;
    guestName: string;
    saveNickname: () => void;
    clearNickname: () => void;
  } => ({
    nickname: "",
    guestName: "guest",
    saveNickname: (): void => {},
    clearNickname: (): void => {},
  }),
}));

vi.mock("@/hooks/useGodotLoader", () => ({
  useGodotLoader: (): {
    state: string;
    progress: number;
    bytesLoaded: number;
    bytesTotal: number;
    error: string | null;
    start: () => void;
  } => ({
    state: "idle",
    progress: 0,
    bytesLoaded: 0,
    bytesTotal: 0,
    error: null,
    start: (): void => {},
  }),
}));

vi.mock("@/hooks/useDeployRevision", () => ({
  useDeployRevision: (): { stale: boolean; reload: () => void } => ({ stale: false, reload: (): void => {} }),
}));

vi.mock("@/hooks/useWaitingRoomPack", () => ({
  useWaitingRoomPack: (): { ownPackPct: number } => ({ ownPackPct: 0 }),
}));

vi.mock("@/hooks/useLobbyAudio", () => ({
  holdLobbyBgmOff: (): void => {},
}));

afterEach(() => {
  resetInboundSnapForTests();
  hub.status = "offline";
  hub.leaveRoom.mockClear();
  hub.returnToLobby.mockClear();
});

describe("useGameFlow inbound snap", () => {
  it("leaveToLobby 는 lastInboundSnap 을 비운다", () => {
    rememberInboundSnap({ tick: 2, winner: 0 });
    const { result } = renderHook(() => useGameFlow("player"));
    act(() => {result.current.leaveToLobby();});
    expect(lastInboundSnapOf()).toBeNull();
    expect(hub.leaveRoom).toHaveBeenCalledTimes(1);
  });

  it("matchEnd 는 lastInboundSnap 을 비운다", () => {
    hub.status = "playing";
    rememberInboundSnap({ tick: 3, winner: 2 });
    const { result } = renderHook(() => useGameFlow("player"));
    act(() => {result.current.matchEnd();});
    expect(lastInboundSnapOf()).toBeNull();
    expect(hub.returnToLobby).toHaveBeenCalledTimes(1);
  });
});
