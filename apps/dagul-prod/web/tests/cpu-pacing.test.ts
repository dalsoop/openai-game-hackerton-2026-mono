import { describe, expect, it } from "vitest";
import { MatchSim } from "@/lib/hub/match-sim";
import { MatchRng, RNG_FALLBACK_SEED } from "@/lib/hub/match-rng";

/** CPU 인간화 페이싱 회귀 — 시드 고정 결정론이므로 통과/실패가 항상 같다. */

const PACING_SEED = 20260826;
const TICKS_210_SEC = 12600;
const TICK_AT_60_SEC = 3600;
const SWEEP_SEEDS = [1, 2, 3, 7, 42, 1337, 99991, PACING_SEED];

function cpuOnlySim(seed: number): MatchSim {
  const seats = [0, 1, 2, 3, 4, 5, 6, 7].map((slot) => ({
    slot,
    name: `CPU${slot + 1}`,
    cpu: true,
  }));
  const sim = new MatchSim(seats, seed);
  sim.countdown = 0;
  return sim;
}

/** 생존 = 비 eliminated — 다운·리스폰 도입 후 '생존'은 영구 탈락하지 않았음을 뜻한다. */
function aliveCount(sim: MatchSim): number {
  return [...sim.heroes.values()].filter((h) => !h.eliminated).length;
}

/** 무사 생존 = 확정 킬을 한 번도 당하지 않은 비탈락자 — 경기 진행(사망 발생)의 신호. */
function unscathedCount(sim: MatchSim): number {
  return [...sim.heroes.values()].filter((h) => !h.eliminated && h.deaths === 0).length;
}

function aimsExactAtSomeone(
  sim: MatchSim,
  hero: { slot: number; aimX: number; aimY: number },
): boolean {
  return [...sim.heroes.values()].some(
    (o) => o.alive && o.slot !== hero.slot && o.x === hero.aimX && o.y === hero.aimY,
  );
}

describe("MatchRng", () => {
  it("같은 시드는 같은 스트림, 다른 시드는 다른 스트림", () => {
    const a = new MatchRng(7);
    const b = new MatchRng(7);
    const c = new MatchRng(8);
    const seqA = [a.next(), a.next(), a.next()];
    const seqB = [b.next(), b.next(), b.next()];
    const seqC = [c.next(), c.next(), c.next()];
    expect(seqA).toEqual(seqB);
    expect(seqA).not.toEqual(seqC);
  });

  it("시드 0/미지정은 고정 폴백 시드로 수렴한다", () => {
    const zero = new MatchRng(0);
    const missing = new MatchRng();
    const first = new MatchRng(RNG_FALLBACK_SEED).next();
    expect(zero.next()).toBe(first);
    expect(missing.next()).toBe(first);
  });

  it("rangef·rangei·chance 는 범위를 지킨다", () => {
    const rng = new MatchRng(42);
    for (let i = 0; i < 200; i++) {
      const f = rng.rangef(-0.085, 0.085);
      expect(f).toBeGreaterThanOrEqual(-0.085);
      expect(f).toBeLessThan(0.085);
      const n = rng.rangei(0, 3);
      expect(n).toBeGreaterThanOrEqual(0);
      expect(n).toBeLessThanOrEqual(3);
      expect(typeof rng.chance(0.5)).toBe("boolean");
    }
  });
});

describe("CPU 페이싱", () => {
  it("8인 CPU 전용 210초 — 60초 시점 생존자 4명 이상", () => {
    const sim = cpuOnlySim(PACING_SEED);
    let aliveAt60 = -1;
    for (let i = 0; i < TICKS_210_SEC; i++) {
      sim.step(1 / 60);
      if (sim.tick === TICK_AT_60_SEC) {aliveAt60 = aliveCount(sim);}
    }
    expect(aliveAt60).toBeGreaterThanOrEqual(4);
  });

  it("같은 시드는 같은 경기(결정론)", () => {
    const a = cpuOnlySim(PACING_SEED);
    const b = cpuOnlySim(PACING_SEED);
    for (let i = 0; i < 1800; i++) {
      a.step(1 / 60);
      b.step(1 / 60);
    }
    for (const [slot, ha] of a.heroes) {
      const hb = b.heroes.get(slot);
      expect(hb).toBeTruthy();
      if (!hb) {continue;}
      expect(hb.x).toBe(ha.x);
      expect(hb.y).toBe(ha.y);
      expect(hb.hp).toBe(ha.hp);
      expect(hb.alive).toBe(ha.alive);
    }
  });

  it("시드 스윕 8종 — 60초 시점 생존자 5~8명", { timeout: 30_000 }, () => {
    for (const seed of SWEEP_SEEDS) {
      const sim = cpuOnlySim(seed);
      for (let i = 0; i < TICK_AT_60_SEC; i++) {
        sim.step(1 / 60);
      }
      const alive = aliveCount(sim);
      expect(alive, `seed=${seed}`).toBeGreaterThanOrEqual(5);
      expect(alive, `seed=${seed}`).toBeLessThanOrEqual(8);
    }
  });

  // 다운·리스폰 도입 후 사망은 영구 퇴장이 아니므로, 진행 신호는 '무사 생존'으로 잰다.
  // 범위 수치(0~7)는 도입 전과 동일하게 유지한다.
  it("210초 종료 시 무사 생존 0~7명 — 경기가 실제로 진행된다", () => {
    const sim = cpuOnlySim(PACING_SEED);
    for (let i = 0; i < TICKS_210_SEC; i++) {
      sim.step(1 / 60);
    }
    const unscathed = unscathedCount(sim);
    expect(unscathed).toBeGreaterThanOrEqual(0);
    expect(unscathed).toBeLessThanOrEqual(7);
  });

  it("CPU 조준은 표적 정확 좌표가 아니다(각도 오차)", () => {
    const sim = cpuOnlySim(PACING_SEED);
    let inexactAim = false;
    for (let i = 0; i < 600 && !inexactAim; i++) {
      sim.step(1 / 60);
      inexactAim = [...sim.heroes.values()].some((h) => h.alive && !aimsExactAtSomeone(sim, h));
    }
    expect(inexactAim).toBe(true);
  });
});
