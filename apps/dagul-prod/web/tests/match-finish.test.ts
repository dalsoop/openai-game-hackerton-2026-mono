import { describe, expect, it } from "vitest";
import {
  FINISH_CANCEL_AFTER, FINISH_DOWN_HOLD, FINISH_FLY, FINISH_FLY_ARC, FINISH_FLY_SPINS,
  FINISH_FLY_X, FINISH_FLY_Y, FINISH_HIT_STOP, FINISH_PREP, FINISH_RANGE, FINISH_RUSH,
  FINISH_RUSH_X, FINISH_TOTAL, apply, applyFinish, cancelFinishCine, packFinishCine,
  seed, seedFinishCine, tick, tickFinishCine, tryBeginFinish,
} from "@/lib/hub/match-finish";
import type { FinishCine, FinishHero, FinishKillFn } from "@/lib/hub/match-finish";

/** 확인사살 시네 — ultimate_effect.gd 수치 그대로의 회귀. */

const DT = 1 / 60;
const noop: FinishKillFn = (): void => undefined;

function hero(slot: number, over: Partial<FinishHero> = {}): FinishHero {
  return {
    slot, x: 400, y: 400, alive: true, downed: false, downLeft: 0,
    eliminated: false, vx: 12, vy: -8, ...over,
  };
}

function pair(overVic: Partial<FinishHero> = {}): {
  heroes: Map<number, FinishHero>;
  atk: FinishHero;
  vic: FinishHero;
} {
  const atk = hero(0);
  const vic = hero(1, { x: 500, y: 400, downed: true, downLeft: 4, ...overVic });
  return { heroes: new Map([[0, atk], [1, vic]]), atk, vic };
}

function beginNear(): { cine: FinishCine; heroes: Map<number, FinishHero>; vic: FinishHero } {
  const { heroes, vic } = pair();
  const cine = seedFinishCine();
  expect(tryBeginFinish(cine, heroes, 0)).toBe(true);
  return { cine, heroes, vic };
}

function stepUntilOff(
  cine: FinishCine,
  heroes: Map<number, FinishHero>,
  downHeroFn: FinishKillFn,
): number {
  let n = 0;
  while (cine.on && n < 400) {
    tickFinishCine(cine, heroes, {}, DT, downHeroFn);
    n += 1;
  }
  return n;
}

describe("상수 — ultimate_effect.gd FINISH_*", () => {
  it("prep 0.35 rush 0.184 hit-stop 0.40 total 1.525, fly 는 차감", () => {
    expect(FINISH_PREP).toBe(0.35);
    expect(FINISH_RUSH).toBe(0.184);
    expect(FINISH_HIT_STOP).toBe(0.40);
    expect(FINISH_TOTAL).toBe(1.525);
    expect(FINISH_FLY).toBeCloseTo(1.525 - 0.35 - 0.184 - 0.40, 12);
    expect(FINISH_RANGE).toBe(280);
    expect(FINISH_CANCEL_AFTER).toBe(0.12);
    expect(FINISH_DOWN_HOLD).toBe(0.12);
  });

  it("seed/apply/tick 별칭이 본 함수와 같다", () => {
    expect(seed).toBe(seedFinishCine);
    expect(apply).toBe(applyFinish);
    expect(tick).toBe(tickFinishCine);
  });
});

describe("try_begin_finish", () => {
  it("280 안 다운 생존자를 고르고 mid 는 중점", () => {
    const { cine, vic } = beginNear();
    expect(cine.on).toBe(true);
    expect(cine.atk).toBe(0);
    expect(cine.vic).toBe(1);
    expect(cine.t).toBe(0);
    expect(cine.hit).toBe(false);
    expect(cine.rush).toBe(false);
    expect(cine.midX).toBe((400 + vic.x) * 0.5);
    expect(cine.midY).toBe(400);
  });

  it("거리 280 이상은 실패, 279.999 는 성공", () => {
    const far = pair({ x: 400 + 280, y: 400 });
    expect(tryBeginFinish(seedFinishCine(), far.heroes, 0)).toBe(false);
    const near = pair({ x: 400 + 279.999, y: 400 });
    expect(tryBeginFinish(seedFinishCine(), near.heroes, 0)).toBe(true);
  });

  it("대상이 살아 있지 않거나 다운이 아니면 실패", () => {
    expect(tryBeginFinish(seedFinishCine(), pair({ downed: false }).heroes, 0)).toBe(false);
    expect(tryBeginFinish(seedFinishCine(), pair({ alive: false }).heroes, 0)).toBe(false);
  });

  it("공격자가 다운이거나 죽어 있으면 실패, cine 중이면 재시작 금지", () => {
    const { heroes, atk } = pair();
    atk.downed = true;
    expect(tryBeginFinish(seedFinishCine(), heroes, 0)).toBe(false);
    atk.downed = false;
    atk.alive = false;
    expect(tryBeginFinish(seedFinishCine(), heroes, 0)).toBe(false);
    const live = pair();
    const cine = seedFinishCine();
    expect(tryBeginFinish(cine, live.heroes, 0)).toBe(true);
    expect(tryBeginFinish(cine, live.heroes, 0)).toBe(false);
  });

  it("같은 거리면 슬롯이 앞선 다운을 고른다", () => {
    const atk = hero(0, { x: 0, y: 0 });
    const a = hero(2, { x: 100, y: 0, downed: true });
    const b = hero(1, { x: 100, y: 0, downed: true });
    const cine = seedFinishCine();
    tryBeginFinish(cine, new Map([[0, atk], [2, a], [1, b]]), 0);
    expect(cine.vic).toBe(1);
  });
});

describe("apply_human F", () => {
  it("첫 F 는 시작하고, cine 중 두 번째 F 는 즉시 취소", () => {
    const { heroes } = pair();
    const cine = seedFinishCine();
    applyFinish(cine, heroes, 0, false);
    expect(cine.on).toBe(false);
    applyFinish(cine, heroes, 0, true);
    expect(cine.on).toBe(true);
    applyFinish(cine, heroes, 0, true);
    expect(cine.on).toBe(false);
  });
});

describe("tick_finish_cine 타임라인", () => {
  it("prep 후 rush, rush_t^3 으로 atk_x, 히트 전 vic 변위 0", () => {
    const { cine, heroes } = beginNear();
    tickFinishCine(cine, heroes, {}, FINISH_PREP, noop);
    expect(cine.rush).toBe(true);
    expect(cine.atkX).toBe(0);
    expect(cine.hit).toBe(false);
    tickFinishCine(cine, heroes, {}, FINISH_RUSH * 0.5, noop);
    expect(cine.atkX).toBeCloseTo(FINISH_RUSH_X * 0.125, 10);
    expect(cine.vicX).toBe(0);
  });

  it("rush 끝에서 hit, 히트스톱 동안 fly 0, 이후 ease 비행", () => {
    const { cine, heroes } = beginNear();
    tickFinishCine(cine, heroes, {}, FINISH_PREP + FINISH_RUSH, noop);
    expect(cine.hit).toBe(true);
    expect(cine.rush).toBe(false);
    expect(cine.atkX).toBeCloseTo(FINISH_RUSH_X, 10);
    expect(cine.hitAge).toBe(0);
    tickFinishCine(cine, heroes, {}, FINISH_HIT_STOP, noop);
    expect(cine.fly).toBe(0);
    expect(cine.vicX).toBe(0);
    tickFinishCine(cine, heroes, {}, FINISH_FLY * 0.5, noop);
    const flyT = 0.5;
    const ease = 1 - (1 - flyT) ** 3;
    expect(cine.vicX).toBeCloseTo(FINISH_FLY_X * ease, 8);
    expect(cine.vicY).toBeCloseTo(FINISH_FLY_Y * ease - FINISH_FLY_ARC * Math.sin(Math.PI * flyT), 8);
    expect(cine.vicSpin).toBeCloseTo(Math.PI * 2 * FINISH_FLY_SPINS * ease, 8);
  });

  it("총 길이 후 down_hero(atk, vic) 하고 cine 를 비운다", () => {
    const { cine, heroes } = beginNear();
    let killed: [number, number] | null = null;
    const n = stepUntilOff(cine, heroes, (a: number, v: number): void => { killed = [a, v]; });
    expect(killed).toEqual([0, 1]);
    expect(cine.on).toBe(false);
    expect(n * DT).toBeGreaterThan(FINISH_TOTAL - DT * 2);
    expect(n * DT).toBeLessThan(FINISH_TOTAL + DT * 3);
  });

  it("시네 중 공격자 vel=0, 피해자 down_left >= 0.12", () => {
    const { cine, heroes, vic } = beginNear();
    const atk = heroes.get(0);
    if (atk === undefined) {throw new Error("atk");}
    vic.downLeft = 0.01;
    tickFinishCine(cine, heroes, {}, DT, noop);
    expect(atk.vx).toBe(0);
    expect(atk.vy).toBe(0);
    expect(vic.downLeft).toBe(FINISH_DOWN_HOLD);
  });

  it("t > 0.12 이후 command.finish 면 취소하고 down_hero 없음", () => {
    const { cine, heroes } = beginNear();
    let killed = 0;
    const countKill = (): void => { killed += 1; };
    tickFinishCine(cine, heroes, { finish: true }, 0.12, countKill);
    expect(cine.on).toBe(true);
    tickFinishCine(cine, heroes, { finish: true }, DT, countKill);
    expect(cine.on).toBe(false);
    expect(killed).toBe(0);
  });

  it("피해자 기상·사망 또는 공격자 탈락이면 취소", () => {
    const a = beginNear();
    a.vic.downed = false;
    tickFinishCine(a.cine, a.heroes, {}, DT, noop);
    expect(a.cine.on).toBe(false);
    const b = beginNear();
    const atk = b.heroes.get(0);
    if (atk === undefined) {throw new Error("atk");}
    atk.eliminated = true;
    tickFinishCine(b.cine, b.heroes, {}, DT, noop);
    expect(b.cine.on).toBe(false);
  });
});

describe("스냅 pack_finish_cine", () => {
  it("off 는 {}, on 은 snake_case + mx/my", () => {
    expect(packFinishCine(seedFinishCine())).toEqual({});
    const { cine } = beginNear();
    cine.t = 0.2;
    cine.rush = true;
    cine.atkX = 10;
    expect(packFinishCine(cine)).toEqual({
      on: true, atk: 0, vic: 1, t: 0.2, hit: false, hit_age: 0, fly: 0,
      vic_x: 0, vic_y: 0, vic_spin: 0, atk_x: 10, rush: true, mx: 450, my: 400,
    });
  });
});

describe("cancel_finish_cine", () => {
  it("필드를 seed 와 같게 비운다", () => {
    const { cine } = beginNear();
    cancelFinishCine(cine);
    expect(cine).toEqual(seedFinishCine());
  });
});
