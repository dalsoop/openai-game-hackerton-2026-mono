import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";
import {
  allSeatsMatchReady, loadWaitTimedOut, lobbyReadySig, matchWaitNames, pendingLoadNames,
  shouldHoldCountdown,
} from "@/lib/domain/match-load-ready";
import { lobbyFieldsOf } from "@/lib/hub/waiting-room-roster";
import type { RosterSnapshot } from "@/lib/domain/roster";
import { packPctFromLoader } from "@/lib/hub/loader-pack-pct";
import { START_COUNTDOWN, MatchSim } from "@/lib/hub/match-sim";
import { makeEquipment } from "@/lib/hub/match-equipment";
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
  it("미완료 좌석이 있으면 붙잡고, 전원이 ready 면 연다", () => {
    expect(shouldHoldCountdown([seat(false)])).toBe(true);
    expect(shouldHoldCountdown([seat(true)])).toBe(false);
    expect(shouldHoldCountdown([seat(true), seat(true)])).toBe(false);
  });

  it("대기 상한이 지나도 미완료면 붙잡는다 — 상한은 강퇴 신호다", () => {
    expect(shouldHoldCountdown([seat(false)])).toBe(true);
    expect(loadWaitTimedOut(59_999, 60_000)).toBe(false);
    expect(loadWaitTimedOut(60_000, 60_000)).toBe(true);
    expect(shouldHoldCountdown([seat(true)])).toBe(false);
  });

  it("20초 강제 시작은 컷오프하고 대기는 1분이다", () => {
    const root = process.cwd();
    const src = (rel: string): string => readFileSync(join(root, rel), "utf8");
    expect(src("lib/hub/config.ts")).not.toContain("loadReadyTimeoutMs");
    expect(src("lib/hub/config.ts")).not.toContain("20_000");
    expect(HUB_CONFIG.loadReadyWaitMs).toBe(60_000);
    expect(shouldHoldCountdown([seat(false)])).toBe(true);
    expect(loadWaitTimedOut(20_000, HUB_CONFIG.loadReadyWaitMs)).toBe(false);
    expect(loadWaitTimedOut(60_000, HUB_CONFIG.loadReadyWaitMs)).toBe(true);
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

  it("lobbyFieldsOf 는 좌석을 평문 복사하고 readySig 를 계산한다", () => {
    const row = { slot: 0, sessionId: "h", name: "호스트", connected: true, matchReady: true };
    const players = { *[Symbol.iterator](): Generator<typeof row> { yield row; } };
    const snap = lobbyFieldsOf({
      phase: "lobby",
      hostSessionId: "h",
      players: players as unknown as RosterSnapshot["players"],
    });
    expect(Array.isArray(players)).toBe(false);
    expect(snap.players).not.toBe(players as unknown as RosterSnapshot["players"]);
    expect(snap.players[0]).toEqual({
      slot: 0, sessionId: "h", name: "호스트", connected: true, packPct: undefined,
      characterId: undefined, matchReady: true,
    });
    expect(snap.readySig).toContain("0:1");
  });

  it("lobbyFieldsOf 가 startInSec 을 평문으로 복사한다", () => {
    const snap = lobbyFieldsOf({
      phase: "lobby",
      hostSessionId: "h",
      startInSec: 4,
      players: [
        { slot: 0, sessionId: "h", name: "호스트", connected: true, matchReady: false },
      ],
    });
    expect(snap.startInSec).toBe(4);
    expect(lobbyFieldsOf({
      phase: "lobby",
      hostSessionId: "h",
      players: [],
    }).startInSec).toBe(0);
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
    expect(shouldHoldCountdown([seat(false)])).toBe(true);
  });
});

describe("MatchSim 카운트다운 장벽", () => {
  it("개전 대기는 3초", () => {
    expect(START_COUNTDOWN).toBe(3);
  });

  it("held 면 입력이 와도 카운트다운을 깎지 않는다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdownHeld = true;
    sim.pushInput(0, { mx: 1, my: 0, seq: 1 });
    for (let i = 0; i < 60; i += 1) {sim.step(1 / 60);}
    expect(sim.countdown).toBe(START_COUNTDOWN);
  });

  it("개전 뒤 held 를 다시 켜면 움직임을 멈춘다", () => {
    const sim = new MatchSim([{ slot: 0 }]);
    sim.countdownHeld = false;
    sim.countdown = 0;
    const hero = sim.heroes.get(0);
    if (!hero) {return;}
    const x0 = hero.x;
    sim.pushInput(0, { mx: 1, my: 0, seq: 1 });
    sim.step(1 / 60);
    expect(hero.x).toBeGreaterThan(x0);
    sim.countdownHeld = true;
    const x1 = hero.x;
    sim.pushInput(0, { mx: 1, my: 0, seq: 2 });
    sim.step(1 / 60);
    expect(hero.x).toBe(x1);
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

  it("장벽 동안 쌓인 dash·firePressed 는 개전에 재생되지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdownHeld = true;
    const hero = sim.heroes.get(0);
    if (!hero) {return;}
    hero.equipment = makeEquipment("brawler");
    hero.mag = hero.equipment.magSize;
    const x0 = hero.x;
    for (let i = 0; i < 40; i += 1) {
      sim.pushInput(0, {
        mx: 1, my: 0, dash: true, fire: true, firePressed: true,
        aimX: hero.x + 200, aimY: hero.y, seq: i + 1,
      });
      sim.step(1 / 60);
    }
    expect(sim.countdown).toBe(START_COUNTDOWN);
    expect(hero.mobilityCd).toBe(0);
    expect(sim.bullets.size).toBe(0);
    sim.countdownHeld = false;
    const ticks = Math.ceil(START_COUNTDOWN * 60) + 2;
    for (let i = 0; i < ticks; i += 1) {sim.step(1 / 60);}
    expect(sim.countdown).toBe(0);
    expect(hero.mobilityCd).toBe(0);
    expect(sim.bullets.size).toBe(0);
    expect(hero.x).toBeGreaterThan(x0);
  });
});
