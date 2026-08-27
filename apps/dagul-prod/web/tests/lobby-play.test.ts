import { afterEach, describe, expect, it, vi } from "vitest";
import type { Client } from "colyseus";
import { CLOSE_CODE, HUB_CONFIG, KO, MSG } from "@/lib/hub/config";
import {
  commitTickSnap, holdLoadBarrier, parkSeat, resetSeatAck, scheduleLobbyReset, tryReleaseLoadBarrier,
} from "@/lib/hub/lobby-play";
import { seed as seedAuthority } from "@/lib/hub/match-authority";
import { LobbyState, PlayerSchema } from "@/lib/hub/lobby-state";
import type { LobbyBag, LobbyHandle } from "@/lib/hub/lobby-waiting";

function clientOf(
  sessionId: string,
  send: ReturnType<typeof vi.fn>,
  extra: Partial<Client> = {},
): Client {
  return { sessionId, send, ...extra } as unknown as Client;
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
    authority: null, hostLossTimer: null, loadWaitMs: 0,
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
      loadWaitMs: 0,
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

function playingRoom(
  ready: readonly boolean[],
): { room: LobbyHandle; bag: LobbyBag; state: LobbyState } {
  const state = new LobbyState();
  state.phase = "playing";
  state.loadHeld = true;
  ready.forEach((matchReady, i) => {
    const p = new PlayerSchema();
    p.sessionId = `s${i}`;
    p.slot = i;
    p.matchReady = matchReady;
    state.players.push(p);
  });
  const bag = emptyBag();
  bag.authority = seedAuthority(
    ready.map((_, i) => ({ slot: i, name: `P${i}` })),
    "classic",
  );
  bag.authority.sim.countdownHeld = true;
  return { room: roomOf(state), bag, state };
}

describe("tryReleaseLoadBarrier", () => {
  it("한 명이라도 matchReady 가 아니면 열지 않는다", () => {
    const { room, bag, state } = playingRoom([true, false]);
    tryReleaseLoadBarrier(room, bag);
    expect(bag.authority?.sim.countdownHeld).toBe(true);
    expect(state.loadHeld).toBe(true);
  });

  it("전원 matchReady 면 즉시 연다", () => {
    const { room, bag, state } = playingRoom([true, true]);
    tryReleaseLoadBarrier(room, bag);
    expect(bag.authority?.sim.countdownHeld).toBe(false);
    expect(state.loadHeld).toBe(false);
  });

  it("이미 열린 장벽은 tryRelease 가 다시 닫지 않는다", () => {
    const { room, bag, state } = playingRoom([false]);
    if (!bag.authority) {return;}
    bag.authority.sim.countdownHeld = false;
    state.loadHeld = false;
    tryReleaseLoadBarrier(room, bag);
    expect(bag.authority.sim.countdownHeld).toBe(false);
    expect(state.loadHeld).toBe(false);
  });

  it("1분이 지나도 미완료면 그 좌석만 내보낸 뒤 연다", () => {
    const { room, bag, state } = playingRoom([true, false]);
    const kicked = vi.fn();
    const leave = vi.fn();
    room.dropSeat = (sessionId: string): void => {
      const idx = state.players.findIndex((p) => p.sessionId === sessionId);
      if (idx >= 0) {state.players.splice(idx, 1);}
      tryReleaseLoadBarrier(room, bag);
    };
    room.clients = [
      clientOf("s0", vi.fn()),
      clientOf("s1", kicked, { leave }),
    ];
    tryReleaseLoadBarrier(room, bag, 59_999);
    expect(state.loadHeld).toBe(true);
    expect(state.players.length).toBe(2);
    expect(kicked).not.toHaveBeenCalled();
    tryReleaseLoadBarrier(room, bag, 1);
    expect(kicked).toHaveBeenCalledWith(MSG.KICKED, {
      msg: KO.LOAD_WAIT_TIMEOUT, reason: "load-wait",
    });
    expect(leave).toHaveBeenCalledWith(CLOSE_CODE.KICKED);
    expect(state.players.map((p) => p.sessionId)).toEqual(["s0"]);
    expect(state.loadHeld).toBe(false);
    expect(bag.authority?.sim.countdownHeld).toBe(false);
  });

  it("대기 상한이 지나도 dropSeat 가 없으면 미완료와 같이 붙잡는다", () => {
    const { room, bag, state } = playingRoom([true, false]);
    tryReleaseLoadBarrier(room, bag, 60_000);
    expect(state.loadHeld).toBe(true);
    expect(state.players.length).toBe(2);
    expect(bag.authority?.sim.countdownHeld).toBe(true);
  });

  it("이어받기 장벽은 열린 뒤에도 다시 닫는다", () => {
    const { room, bag, state } = playingRoom([true, true]);
    tryReleaseLoadBarrier(room, bag);
    expect(state.loadHeld).toBe(false);
    state.players[0].matchReady = false;
    holdLoadBarrier(room, bag);
    expect(bag.authority?.sim.countdownHeld).toBe(true);
    expect(state.loadHeld).toBe(true);
    tryReleaseLoadBarrier(room, bag);
    expect(state.loadHeld).toBe(true);
  });
});

describe("parkSeat", () => {
  it("이탈 true · 복귀 false, CPU 는 무시한다", () => {
    const bag = emptyBag();
    bag.authority = seedAuthority(
      [
        { slot: 0, name: "호스트" },
        { slot: 1, name: "게스트" },
        { slot: 2, name: "CPU3", cpu: true },
      ],
      "full",
    );
    parkSeat(bag, 1, true);
    expect(bag.authority.sim.heroes.get(1)?.parked).toBe(true);
    parkSeat(bag, 1, false);
    expect(bag.authority.sim.heroes.get(1)?.parked).toBe(false);
    parkSeat(bag, 2, true);
    expect(bag.authority.sim.heroes.get(2)?.parked).toBe(false);
  });
});

describe("resetSeatAck", () => {
  it("인간 좌석 ack 만 0 으로 돌리고 CPU 는 무시한다", () => {
    const bag = emptyBag();
    bag.authority = seedAuthority(
      [
        { slot: 0, name: "호스트" },
        { slot: 1, name: "게스트" },
        { slot: 2, name: "CPU3", cpu: true },
      ],
      "full",
    );
    const guest = bag.authority.sim.heroes.get(1);
    const cpu = bag.authority.sim.heroes.get(2);
    expect(guest).toBeDefined();
    expect(cpu).toBeDefined();
    if (!guest || !cpu) {return;}
    guest.ack = 2400;
    cpu.ack = 9;
    resetSeatAck(bag, 1);
    resetSeatAck(bag, 2);
    expect(bag.authority.sim.heroes.get(1)?.ack).toBe(0);
    expect(bag.authority.sim.heroes.get(2)?.ack).toBe(9);
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
