import { describe, expect, it } from "vitest";
import {
  allSeatsMatchReady, lobbyReadySig, matchWaitNames, pendingLoadNames, shouldHoldCountdown,
} from "@/lib/domain/match-load-ready";
import { lobbyFieldsOf } from "@/lib/hub/waiting-room-roster";
import type { RosterSnapshot } from "@/lib/domain/roster";
import { packPctFromLoader } from "@/lib/hub/loader-pack-pct";
import { START_COUNTDOWN, MatchSim } from "@/lib/hub/match-sim";
import { HUB_CONFIG } from "@/lib/hub/config";

function seat(matchReady: boolean): { connected: boolean; matchReady: boolean; name: string } {
  return { connected: true, matchReady, name: matchReady ? "완료" : "대기" };
}

describe("allSeatsMatchReady", () => {
  it("자리에 남은 좌석이 전부 ready 여야 한다", () => {
    expect(allSeatsMatchReady([seat(true), seat(true)])).toBe(true);
    expect(allSeatsMatchReady([seat(true), seat(false)])).toBe(false);
  });

  it("끊긴 좌석도 로딩 대기에서 빼지 않는다", () => {
    expect(allSeatsMatchReady([
      { connected: true, matchReady: true, name: "나" },
      { connected: false, matchReady: false, name: "너" },
    ])).toBe(false);
  });

  it("접속자가 없어도 자리에 남으면 기다린다. 빈 명단만 바로 푼다", () => {
    expect(allSeatsMatchReady([])).toBe(true);
    expect(allSeatsMatchReady([{ connected: false, matchReady: false, name: "유예" }])).toBe(false);
  });
});

describe("shouldHoldCountdown", () => {
  it("타임아웃 전이면 미완료를 붙잡는다", () => {
    expect(shouldHoldCountdown([seat(false)], 0, 20_000)).toBe(true);
    expect(shouldHoldCountdown([seat(true)], 0, 20_000)).toBe(false);
  });

  it("타임아웃이면 미완료여도 푼다", () => {
    expect(shouldHoldCountdown([seat(false)], 20_000, 20_000)).toBe(false);
    expect(shouldHoldCountdown([seat(false)], 19_999, 20_000)).toBe(true);
  });
});

describe("pendingLoadNames", () => {
  it("ready 가 아닌 이름만 남긴다", () => {
    expect(pendingLoadNames([
      { name: "호스트", matchReady: true },
      { name: "게스트", matchReady: false },
    ])).toEqual(["게스트"]);
  });

  it("내 좌석은 목록에서 뺀다", () => {
    expect(pendingLoadNames([
      { slot: 0, name: "호스트", matchReady: false },
      { slot: 1, name: "게스트", matchReady: false },
    ], 0)).toEqual(["게스트"]);
  });
});

describe("matchWaitNames", () => {
  it("장벽이 열리면 빈 목록이다", () => {
    expect(matchWaitNames([
      { slot: 0, name: "호스트", matchReady: true },
      { slot: 1, name: "게스트", matchReady: false },
    ], 0, false)).toEqual([]);
  });

  it("장벽이 닫혀 있으면 남만 보여 준다", () => {
    expect(matchWaitNames([
      { slot: 0, name: "호스트", matchReady: false },
      { slot: 1, name: "게스트", matchReady: false },
    ], 0, true)).toEqual(["게스트"]);
  });
});

describe("lobbyReadySig", () => {
  it("중첩 matchReady 가 바뀌면 지문이 달라진다", () => {
    const players = [
      { slot: 0, matchReady: true },
      { slot: 1, matchReady: false },
    ];
    const held = lobbyReadySig(players, true);
    const open = lobbyReadySig(players, false);
    expect(held).not.toBe(open);
    expect(lobbyReadySig([{ slot: 1, matchReady: true }], true)).not.toBe(held);
  });

  it("lobbyFieldsOf 가 readySig 를 넣는다", () => {
    const snap = lobbyFieldsOf({
      phase: "playing",
      hostSessionId: "h",
      loadHeld: true,
      players: [
        { slot: 0, sessionId: "h", name: "호스트", connected: true, matchReady: false },
        { slot: 1, sessionId: "g", name: "게스트", connected: true, matchReady: true },
      ],
    });
    expect(snap.readySig).toBe(lobbyReadySig(snap.players, true));
    expect(snap.readySig).toContain("0:0");
    expect(snap.readySig).toContain("1:1");
  });

  it("lobbyFieldsOf 는 ArraySchema 이터러블도 좌석으로 본다", () => {
    const row = { slot: 0, sessionId: "h", name: "호스트", connected: true, matchReady: true };
    const players = { *[Symbol.iterator](): Generator<typeof row> { yield row; } };
    const snap = lobbyFieldsOf({
      phase: "lobby",
      hostSessionId: "h",
      players: players as unknown as RosterSnapshot["players"],
    });
    expect(Array.isArray(players)).toBe(false);
    expect(snap.players).toEqual([row]);
    expect(snap.readySig).toContain("0:1");
  });
});

describe("로딩 경로 — 팩 받기와 인게임 ready 는 다르다", () => {
  it("WASM 다운로드 중이면 packPct 만 오르고 matchReady 가 아니다", () => {
    expect(packPctFromLoader("downloading", 0.42)).toBe(42);
    expect(packPctFromLoader("idle", 0)).toBe(0);
    expect(packPctFromLoader("compiling", 0.1)).toBe(100);
    expect(packPctFromLoader("ready", 0)).toBe(100);
    expect(packPctFromLoader("running", 1)).toBe(100);
    expect(allSeatsMatchReady([seat(false)])).toBe(false);
  });

  it("컴파일 완료(100)만으로 카운트다운을 풀지 않는다", () => {
    expect(packPctFromLoader("ready", 1)).toBe(100);
    expect(shouldHoldCountdown([seat(false)], 100, HUB_CONFIG.loadReadyTimeoutMs)).toBe(true);
  });
});

describe("MatchSim 카운트다운 장벽", () => {
  it("held 면 입력이 와도 3초를 깎지 않는다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdownHeld = true;
    sim.pushInput(0, { mx: 1, my: 0, seq: 1 });
    for (let i = 0; i < 60; i += 1) {sim.step(1 / 60);}
    expect(sim.countdown).toBe(START_COUNTDOWN);
  });

  it("held 를 끄면 같은 틱에서 깎이기 시작한다", () => {
    const sim = new MatchSim([{ slot: 0 }]);
    sim.countdownHeld = true;
    sim.step(1 / 60);
    expect(sim.countdown).toBe(START_COUNTDOWN);
    sim.countdownHeld = false;
    sim.step(1 / 60);
    expect(sim.countdown).toBeLessThan(START_COUNTDOWN);
  });
});
