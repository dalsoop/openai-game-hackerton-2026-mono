import { describe, expect, it } from "vitest";
import { allConnectedMatchReady, shouldHoldCountdown } from "@/lib/domain/match-load-ready";
import { packPctFromLoader } from "@/lib/hub/loader-pack-pct";
import { START_COUNTDOWN, MatchSim } from "@/lib/hub/match-sim";
import { HUB_CONFIG } from "@/lib/hub/config";

function seat(connected: boolean, matchReady: boolean): { connected: boolean; matchReady: boolean } {
  return { connected, matchReady };
}

describe("allConnectedMatchReady", () => {
  it("접속 중인 좌석이 전부 ready 여야 한다", () => {
    expect(allConnectedMatchReady([seat(true, true), seat(true, true)])).toBe(true);
    expect(allConnectedMatchReady([seat(true, true), seat(true, false)])).toBe(false);
  });

  it("끊긴 좌석은 로딩 대기에서 뺀다", () => {
    expect(allConnectedMatchReady([seat(true, true), seat(false, false)])).toBe(true);
  });

  it("접속자가 없으면 바로 푼다", () => {
    expect(allConnectedMatchReady([])).toBe(true);
    expect(allConnectedMatchReady([seat(false, false)])).toBe(true);
  });
});

describe("shouldHoldCountdown", () => {
  it("타임아웃 전이면 미완료를 붙잡는다", () => {
    expect(shouldHoldCountdown([seat(true, false)], 0, 20_000)).toBe(true);
    expect(shouldHoldCountdown([seat(true, true)], 0, 20_000)).toBe(false);
  });

  it("타임아웃이면 미완료여도 푼다", () => {
    expect(shouldHoldCountdown([seat(true, false)], 20_000, 20_000)).toBe(false);
    expect(shouldHoldCountdown([seat(true, false)], 19_999, 20_000)).toBe(true);
  });
});

describe("로딩 경로 — 팩 받기와 인게임 ready 는 다르다", () => {
  it("WASM 다운로드 중이면 packPct 만 오르고 matchReady 가 아니다", () => {
    expect(packPctFromLoader("downloading", 0.42)).toBe(42);
    expect(packPctFromLoader("idle", 0)).toBe(0);
    expect(packPctFromLoader("compiling", 0.1)).toBe(100);
    expect(packPctFromLoader("ready", 0)).toBe(100);
    expect(packPctFromLoader("running", 1)).toBe(100);
    expect(allConnectedMatchReady([seat(true, false)])).toBe(false);
  });

  it("컴파일 완료(100)만으로 카운트다운을 풀지 않는다", () => {
    expect(packPctFromLoader("ready", 1)).toBe(100);
    expect(shouldHoldCountdown([seat(true, false)], 100, HUB_CONFIG.loadReadyTimeoutMs)).toBe(true);
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
