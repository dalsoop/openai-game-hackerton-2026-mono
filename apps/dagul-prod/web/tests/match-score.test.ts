import { describe, expect, it } from "vitest";
import { packAuthoritySnap, type SnapPlayer } from "@/lib/hub/match-authority";
import {
  DOWN_FINISH_HP,
  EMOTE_TIME,
  KILL_SCORE,
  MatchSim,
  SHUTDOWN_BASE,
  SHUTDOWN_MAX,
  applyScoredDamage,
  resetDeadStreaks,
  shutdownBonus,
  type SimHero,
} from "@/lib/hub/match-sim";

const DT = 1 / 60;
const SHOT = 13.26;

function twoHeroSim(): { sim: MatchSim; killer: SimHero; victim: SimHero } {
  const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
  sim.countdown = 0;
  const killer = sim.heroes.get(0);
  const victim = sim.heroes.get(1);
  if (!killer || !victim) {throw new Error("seed failed");}
  return { sim, killer, victim };
}

/** 피살자를 확인사살 한 방 직전 상태로 만든다. */
function primeFinish(victim: SimHero): void {
  victim.alive = true;
  victim.downed = true;
  victim.hp = 0;
  victim.downTaken = DOWN_FINISH_HP - 1;
  victim.spawnProtect = 0;
}

describe("match-score", () => {
  it("확정 킬은 120점 + 피해 1:1 을 적립한다", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    expect(applyScoredDamage(sim.heroes, 0, victim, SHOT)).toBe("dead");
    expect(killer.score).toBeCloseTo(KILL_SCORE + SHOT);
    expect(killer.damageDealt).toBeCloseTo(SHOT);
    expect(killer.kills).toBe(1);
    expect(killer.killStreak).toBe(1);
    expect(killer.bestStreak).toBe(1);
  });

  it("연속 킬은 (streak-1)*15 스트릭 보너스를 더한다", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    const before = killer.score;
    primeFinish(victim);
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    expect(killer.killStreak).toBe(2);
    expect(killer.score - before).toBeCloseTo(SHOT + KILL_SCORE + 15);
  });

  it("피살자 스트릭 3 이상이면 셧다운 보너스(90+35*n, 최대 230)", () => {
    expect(shutdownBonus(2)).toBe(0);
    expect(shutdownBonus(3)).toBe(SHUTDOWN_BASE);
    expect(shutdownBonus(4)).toBe(SHUTDOWN_BASE + 35);
    expect(shutdownBonus(9)).toBe(SHUTDOWN_MAX);
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    victim.killStreak = 3;
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    expect(killer.score).toBeCloseTo(SHOT + KILL_SCORE + SHUTDOWN_BASE);
  });

  it("환경(-1)·자해 킬은 점수를 주지 않고, 사망자 스트릭은 소거된다", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    victim.killStreak = 5;
    expect(applyScoredDamage(sim.heroes, -1, victim, SHOT)).toBe("dead");
    expect(killer.score).toBe(0);
    expect(victim.deaths).toBe(1);
    resetDeadStreaks(sim.heroes.values());
    expect(victim.killStreak).toBe(0);
  });

  it("일반 피해도 damageDealt·score 에 1:1 적립된다", () => {
    const { sim, killer, victim } = twoHeroSim();
    expect(applyScoredDamage(sim.heroes, 0, victim, SHOT)).toBe("none");
    expect(killer.damageDealt).toBeCloseTo(SHOT);
    expect(killer.score).toBeCloseTo(SHOT);
    expect(victim.hp).toBeCloseTo(victim.maxHp - SHOT);
  });

  it("스폰 무적 중에는 피해도 점수도 없다", () => {
    const { sim, killer, victim } = twoHeroSim();
    victim.spawnProtect = 1;
    expect(applyScoredDamage(sim.heroes, 0, victim, SHOT)).toBe("none");
    expect(killer.score).toBe(0);
    expect(victim.hp).toBe(victim.maxHp);
  });
});

describe("match-emote", () => {
  it("이모트 입력이 스냅 players 로 왕복한다", () => {
    const { sim } = twoHeroSim();
    sim.pushInput(0, { emote: 2, seq: 1 });
    sim.step(DT);
    const hero = sim.heroes.get(0);
    expect(hero?.emote).toBe(2);
    expect(hero?.emoteTime).toBeCloseTo(EMOTE_TIME);
    const snap = packAuthoritySnap(sim, new Map(), "full");
    const p0 = (snap.players as SnapPlayer[]).find((p) => p.slot === 0);
    expect(p0?.emote).toBe(2);
    expect(p0?.emoteTime).toBeCloseTo(EMOTE_TIME);
  });

  it("같은 입력 재적용은 재트리거하지 않고 타이머만 줄어든다", () => {
    const { sim } = twoHeroSim();
    sim.pushInput(0, { emote: 1, seq: 1 });
    sim.step(DT);
    sim.step(DT);
    const hero = sim.heroes.get(0);
    expect(hero?.emoteTime).toBeCloseTo(EMOTE_TIME - DT);
    sim.pushInput(0, { emote: -1, seq: 2 });
    sim.step(DT);
    sim.pushInput(0, { emote: 0, seq: 3 });
    sim.step(DT);
    expect(hero?.emote).toBe(0);
    expect(hero?.emoteTime).toBeCloseTo(EMOTE_TIME);
  });
});

describe("packAuthoritySnap 점수·탄 kind", () => {
  it("players 에 score·streak, bullets 에 kind 가 실린다", () => {
    const { sim, killer } = twoHeroSim();
    killer.score = 137.5;
    killer.killStreak = 2;
    sim.pushInput(0, { fire: true, aimX: killer.x + 100, aimY: killer.y, seq: 1 });
    sim.step(DT);
    const snap = packAuthoritySnap(sim, new Map(), "full");
    const p0 = (snap.players as SnapPlayer[]).find((p) => p.slot === 0);
    expect(p0?.score).toBeCloseTo(137.5);
    expect(p0?.streak).toBe(2);
    const bullets = snap.bullets as Array<{ kind: string }>;
    expect(bullets.length).toBeGreaterThan(0);
    expect(bullets[0].kind).toBe("bolt");
  });
});
