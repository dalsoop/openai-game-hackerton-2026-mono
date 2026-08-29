import { afterEach, describe, expect, it, vi } from "vitest";
import type { Client } from "colyseus";
import {
  LOBBY_LEAVE_LOCK_SEC,
  LOBBY_START_SEC,
  lobbyLeaveLocked,
  lobbyStartCancelOnHostLeave,
} from "@/lib/domain/waiting-room-start";
import { LobbyState, PlayerSchema } from "@/lib/hub/lobby-state";
import {
  cancelLobbyStartIfHostLeft,
  handleSetGame,
  handleStart,
  type LobbyBag,
  type LobbyHandle,
} from "@/lib/hub/lobby-waiting";

function emptyBag(): LobbyBag {
  return {
    lastSnap: null, prevSnap: null, gameTimer: null, idleTimer: null,
    authority: null, hostLossTimer: null, shutdownTimer: null, loadWaitMs: 0, startTimer: null, matchStartedAtMs: 0,
  };
}

function roomWithHost(): { room: LobbyHandle; bag: LobbyBag; commits: { n: number }; commit: () => void } {
  const state = new LobbyState();
  state.phase = "lobby";
  const host = new PlayerSchema();
  host.sessionId = "host";
  host.slot = 0;
  state.players.push(host);
  state.hostSessionId = "host";
  const commits = { n: 0 };
  const commit = (): void => {commits.n += 1;};
  const room: LobbyHandle = {
    state,
    clients: [{ sessionId: "host", send: vi.fn() } as unknown as Client],
    metadata: {},
    setMetadata: vi.fn(),
    clock: {
      setTimeout: (cb: () => void, ms: number): { clear: () => void } => {
        const id = setTimeout(cb, ms);
        return { clear: (): void => {clearTimeout(id);} };
      },
    },
    broadcast: vi.fn(),
    roomId: "room1",
  };
  return { room, bag: emptyBag(), commits, commit };
}

describe("대기실 시작 카운트다운 규칙", () => {
  it("5·4초는 나갈 수 있고 3초부터는 잠근다", () => {
    expect(lobbyLeaveLocked(0)).toBe(false);
    expect(lobbyLeaveLocked(5)).toBe(false);
    expect(lobbyLeaveLocked(4)).toBe(false);
    expect(lobbyLeaveLocked(3)).toBe(true);
    expect(lobbyLeaveLocked(2)).toBe(true);
    expect(lobbyLeaveLocked(1)).toBe(true);
    expect(LOBBY_START_SEC).toBe(5);
    expect(LOBBY_LEAVE_LOCK_SEC).toBe(3);
    expect(lobbyStartCancelOnHostLeave(5)).toBe(true);
    expect(lobbyStartCancelOnHostLeave(4)).toBe(true);
    expect(lobbyStartCancelOnHostLeave(3)).toBe(false);
  });
});

describe("handleStart 대기실 카운트다운", () => {
  afterEach(() => {vi.useRealTimers();});

  it("누르면 바로 playing 이 아니라 5초를 센다", () => {
    vi.useFakeTimers();
    const { room, bag, commits, commit } = roomWithHost();
    expect(handleStart(room, bag, { sessionId: "host" } as unknown as Client, commit)).toBe(true);
    expect(String(room.state.phase)).toBe("lobby");
    expect(room.state.startInSec).toBe(5);
    expect(commits.n).toBe(0);
    vi.advanceTimersByTime(1000);
    expect(room.state.startInSec).toBe(4);
    expect(lobbyLeaveLocked(room.state.startInSec)).toBe(false);
    vi.advanceTimersByTime(1000);
    expect(room.state.startInSec).toBe(3);
    expect(lobbyLeaveLocked(room.state.startInSec)).toBe(true);
    vi.advanceTimersByTime(3000);
    expect(room.state.startInSec).toBe(0);
    expect(String(room.state.phase)).toBe("playing");
    expect(commits.n).toBe(1);
  });

  it("5·4초에서 호스트가 나가면 카운트를 취소한다", () => {
    vi.useFakeTimers();
    const { room, bag, commits, commit } = roomWithHost();
    handleStart(room, bag, { sessionId: "host" } as unknown as Client, commit);
    vi.advanceTimersByTime(1000);
    expect(room.state.startInSec).toBe(4);
    cancelLobbyStartIfHostLeft(room, bag, true);
    expect(room.state.startInSec).toBe(0);
    expect(String(room.state.phase)).toBe("lobby");
    vi.advanceTimersByTime(5000);
    expect(String(room.state.phase)).toBe("lobby");
    expect(commits.n).toBe(0);
  });

  it("3초부터는 호스트가 나가도 카운트를 유지한다", () => {
    vi.useFakeTimers();
    const { room, bag, commits, commit } = roomWithHost();
    handleStart(room, bag, { sessionId: "host" } as unknown as Client, commit);
    vi.advanceTimersByTime(2000);
    expect(room.state.startInSec).toBe(3);
    cancelLobbyStartIfHostLeft(room, bag, true);
    expect(room.state.startInSec).toBe(3);
    vi.advanceTimersByTime(3000);
    expect(String(room.state.phase)).toBe("playing");
    expect(commits.n).toBe(1);
  });

  it("세는 중에 START 를 다시 눌러도 건너뛰지 않는다", () => {
    vi.useFakeTimers();
    const { room, bag, commits, commit } = roomWithHost();
    const host = { sessionId: "host" } as unknown as Client;
    expect(handleStart(room, bag, host, commit)).toBe(true);
    expect(handleStart(room, bag, host, commit)).toBe(false);
    expect(room.state.startInSec).toBe(5);
    vi.advanceTimersByTime(2000);
    expect(room.state.startInSec).toBe(3);
    expect(String(room.state.phase)).toBe("lobby");
    expect(commits.n).toBe(0);
  });

  it("게스트가 나가도 카운트는 이어진다", () => {
    vi.useFakeTimers();
    const { room, bag, commits, commit } = roomWithHost();
    handleStart(room, bag, { sessionId: "host" } as unknown as Client, commit);
    vi.advanceTimersByTime(1000);
    cancelLobbyStartIfHostLeft(room, bag, false);
    expect(room.state.startInSec).toBe(4);
    vi.advanceTimersByTime(4000);
    expect(String(room.state.phase)).toBe("playing");
    expect(commits.n).toBe(1);
  });

  it("세는 동안 SET_GAME 은 버린다", () => {
    vi.useFakeTimers();
    const { room, bag, commit } = roomWithHost();
    handleStart(room, bag, { sessionId: "host" } as unknown as Client, commit);
    expect(room.state.gameId).toBe("dagul");
    handleSetGame(room, { sessionId: "host" } as unknown as Client, { game: "sparring" });
    expect(room.state.gameId).toBe("dagul");
    expect(room.state.startInSec).toBe(5);
  });

  it("비호스트 START 는 거부하고 카운트를 켜지 않는다", () => {
    const { room, bag, commits, commit } = roomWithHost();
    const send = vi.fn();
    const guest = { sessionId: "guest", send } as unknown as Client;
    expect(handleStart(room, bag, guest, commit)).toBe(false);
    expect(room.state.startInSec).toBe(0);
    expect(String(room.state.phase)).toBe("lobby");
    expect(commits.n).toBe(0);
    expect(send).toHaveBeenCalled();
  });
});
