// @vitest-environment jsdom
import { act, renderHook } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { lastInboundSnapOf, rememberInboundSnap, resetInboundSnapForTests } from "@/lib/hub/page-bridge";
import { useGameFlow } from "@/hooks/useGameFlow";
import { WEB_STORE } from "@/lib/contract";
import type { HubStatus } from "@/types";

const hub = vi.hoisted(() => ({
  status: "offline" as HubStatus,
  gameId: "dagul",
  matchInfo: null,
  roomId: "",
  you: 0,
  resumeToken: "",
  tryResume: vi.fn((): boolean => false),
  resumeFailed: false,
  dropReason: null,
  sendPackPct: (): void => {},
  connect: vi.fn(),
  joinRoom: vi.fn(),
  startMatch: (): void => {},
  disconnect: (): void => {},
  leaveRoom: vi.fn(),
  returnToLobby: vi.fn(),
}));

const session = vi.hoisted(() => ({
  nickname: "",
  guestName: "guest",
  saveNickname: vi.fn(),
  clearNickname: vi.fn(),
}));

vi.mock("@/hooks/useHub", () => ({
  useHub: (): typeof hub => hub,
}));

vi.mock("@/hooks/useSession", () => ({
  useSession: (): typeof session => session,
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
  sessionStorage.clear();
  hub.status = "offline";
  session.nickname = "";
  hub.tryResume.mockReset();
  hub.tryResume.mockReturnValue(false);
  hub.connect.mockClear();
  hub.joinRoom.mockClear();
  hub.leaveRoom.mockClear();
  hub.returnToLobby.mockClear();
  session.saveNickname.mockClear();
});

describe("useGameFlow inbound snap", () => {
  it("leaveToLobby 는 lastInboundSnap 을 비운다", () => {
    rememberInboundSnap({ tick: 2, winner: 0 });
    const { result } = renderHook(() => useGameFlow("player"));
    act(() => {result.current.leaveToLobby();});
    expect(lastInboundSnapOf()).toBeNull();
    expect(hub.leaveRoom).toHaveBeenCalledTimes(1);
  });

  it("엔진 오류 로비로 돌아가기는 방을 떠난다", () => {
    hub.status = "playing";
    rememberInboundSnap({ tick: 4, winner: 0 });
    const { result } = renderHook(() => useGameFlow("player"));
    act(() => {result.current.errorToIntro();});
    expect(lastInboundSnapOf()).toBeNull();
    expect(hub.leaveRoom).toHaveBeenCalledTimes(1);
    expect(result.current.phase).toBe("lobby");
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

describe("useGameFlow 로그인 세션 + 공유 링크", () => {
  it("저장된 닉이 있으면 링크만으로 방에 들어간다", () => {
    session.nickname = "한스";
    sessionStorage.setItem(WEB_STORE.PENDING_JOIN, JSON.stringify({ roomId: "r1", password: "0420" }));
    const { result } = renderHook(() => useGameFlow("player"));
    expect(hub.connect).toHaveBeenCalledWith("한스");
    expect(hub.joinRoom).toHaveBeenCalledWith("r1", { password: "0420" });
    expect(hub.tryResume).not.toHaveBeenCalled();
    expect(result.current.phase).toBe("lobby");
    expect(sessionStorage.getItem(WEB_STORE.PENDING_JOIN)).toBeNull();
  });

  it("첫 방문(닉 없음)은 시작하기 전까지 자동 입장하지 않는다", () => {
    session.nickname = "";
    sessionStorage.setItem(WEB_STORE.PENDING_JOIN, JSON.stringify({ roomId: "r1", password: "0420" }));
    const { result } = renderHook(() => useGameFlow("player"));
    expect(hub.connect).not.toHaveBeenCalled();
    expect(hub.joinRoom).not.toHaveBeenCalled();
    expect(result.current.phase).toBe("intro");
    expect(result.current.hasSavedName).toBe(false);
  });

  it("닉은 있어도 공유 링크가 없으면 로비에 머물지 않는다", () => {
    session.nickname = "한스";
    const { result } = renderHook(() => useGameFlow("player"));
    expect(hub.joinRoom).not.toHaveBeenCalled();
    expect(result.current.hasSavedName).toBe(true);
    expect(result.current.phase).toBe("intro");
  });

  it("수동 시작하기도 대기 입장을 소비한다", () => {
    session.nickname = "";
    sessionStorage.setItem(WEB_STORE.PENDING_JOIN, JSON.stringify({ roomId: "open1", password: "" }));
    const { result } = renderHook(() => useGameFlow("player"));
    act(() => {result.current.findRoom();});
    expect(hub.connect).toHaveBeenCalledTimes(1);
    expect(hub.joinRoom).toHaveBeenCalledWith("open1", { password: "" });
    expect(sessionStorage.getItem(WEB_STORE.PENDING_JOIN)).toBeNull();
  });
});
