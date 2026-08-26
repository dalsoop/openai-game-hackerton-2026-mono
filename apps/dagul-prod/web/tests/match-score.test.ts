import { describe, expect, it } from "vitest";
import { packAuthoritySnap, type SnapPlayer } from "@/lib/hub/match-authority";
import {
  DOWN_FINISH_HP,
  ELIMINATE_SCORE,
  EMOTE_TIME,
  KILL_EQUIP_CD_BASE,
  KILL_EQUIP_CD_STEP,
  KILL_HEAL_CAP,
  KILL_MOBILITY_CD_BASE,
  KILL_MOBILITY_CD_STEP,
  KILL_SCORE,
  KILL_THREAT_GAIN,
  KILL_ULT_GAIN,
  MatchSim,
  SHUTDOWN_BASE,
  SHUTDOWN_CD_MUL,
  SHUTDOWN_HEAL_RATIO,
  SHUTDOWN_MAX,
  SHUTDOWN_ULT_GAIN,
  STREAK_CALLOUT_TICKS,
  WIN_SCORE,
  applyScoredDamage,
  awardEliminateScore,
  awardWinScore,
  momentumHealRatio,
  resetDeadStreaks,
  shutdownBonus,
  streakCalloutSeed,
  streakTitle,
  tickStreakCallout,
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

  it("킬 모멘텀 힐은 max_hp * min(0.10, 0.055 + streak*0.01)", () => {
    expect(momentumHealRatio(1)).toBeCloseTo(0.065);
    expect(momentumHealRatio(4)).toBeCloseTo(0.095);
    expect(momentumHealRatio(5)).toBe(KILL_HEAL_CAP);
    expect(momentumHealRatio(9)).toBe(KILL_HEAL_CAP);
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    killer.hp = killer.maxHp * 0.4;
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    expect(killer.hp).toBeCloseTo(killer.maxHp * 0.4 + killer.maxHp * 0.065);
  });

  it("킬 쿨다운 감소는 equipment 0.50+streak*0.10, mobility 0.35+streak*0.08", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    killer.equipmentCd = 4;
    killer.mobilityCd = 3;
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    const streak = 1;
    expect(killer.equipmentCd).toBeCloseTo(4 - (KILL_EQUIP_CD_BASE + streak * KILL_EQUIP_CD_STEP));
    expect(killer.mobilityCd).toBeCloseTo(3 - (KILL_MOBILITY_CD_BASE + streak * KILL_MOBILITY_CD_STEP));
  });

  it("셧다운은 힐 max_hp*0.14, 쿨다운 50%, 궁 +20", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    victim.killStreak = 3;
    killer.hp = killer.maxHp * 0.5;
    killer.equipmentCd = 2;
    killer.mobilityCd = 2;
    killer.ultimateCharge = 10;
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    const afterMomentum = killer.maxHp * 0.5 + killer.maxHp * momentumHealRatio(1);
    expect(killer.hp).toBeCloseTo(afterMomentum + killer.maxHp * SHUTDOWN_HEAL_RATIO);
    const equipAfterKill = 2 - (KILL_EQUIP_CD_BASE + 1 * KILL_EQUIP_CD_STEP);
    const mobAfterKill = 2 - (KILL_MOBILITY_CD_BASE + 1 * KILL_MOBILITY_CD_STEP);
    expect(killer.equipmentCd).toBeCloseTo(equipAfterKill * SHUTDOWN_CD_MUL);
    expect(killer.mobilityCd).toBeCloseTo(mobAfterKill * SHUTDOWN_CD_MUL);
    expect(killer.ultimateCharge).toBeCloseTo(10 + KILL_ULT_GAIN + SHUTDOWN_ULT_GAIN);
  });

  it("킬 시 threat +18, bounty +12, ult +35, eliminations++", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    const beforeThreat = killer.threat;
    const beforeBounty = killer.bounty;
    const beforeUlt = killer.ultimateCharge;
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    expect(killer.threat).toBeCloseTo(beforeThreat + KILL_THREAT_GAIN);
    expect(killer.bounty).toBeCloseTo(beforeBounty + 12);
    expect(killer.ultimateCharge).toBeCloseTo(beforeUlt + KILL_ULT_GAIN);
    expect(killer.eliminations).toBe(1);
  });

  it("셧다운이면 bounty -20", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    victim.killStreak = 3;
    killer.bounty = 40;
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    expect(killer.bounty).toBeCloseTo(40 + 12 - 20);
  });

  it("킬 시 threat +18", () => {
    const { sim, killer, victim } = twoHeroSim();
    primeFinish(victim);
    const before = killer.threat;
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    expect(killer.threat).toBeCloseTo(before + KILL_THREAT_GAIN);
  });

  it("탈락 +300, 우승 +500", () => {
    const attacker = { score: 10 };
    awardEliminateScore(attacker);
    expect(attacker.score).toBe(10 + ELIMINATE_SCORE);
    awardWinScore(attacker);
    expect(attacker.score).toBe(10 + ELIMINATE_SCORE + WIN_SCORE);
    expect(WIN_SCORE).toBe(500);
    expect(ELIMINATE_SCORE).toBe(300);
  });

  it("스트릭 콜아웃은 원본 한국어 제목·자막·150틱", () => {
    expect(streakTitle(2)).toBe("더블 킬!");
    expect(streakTitle(3)).toBe("연속 처치!");
    expect(streakTitle(4)).toBe("학살 중!");
    expect(streakTitle(5)).toBe("폭주 중!");
    expect(streakTitle(6)).toBe("막을 수 없습니다!");
    const { sim, killer, victim } = twoHeroSim();
    killer.equipment = { ...killer.equipment, characterName: "ZIP" };
    primeFinish(victim);
    applyScoredDamage(sim.heroes, 0, victim, SHOT);
    const callout = streakCalloutSeed();
    primeFinish(victim);
    applyScoredDamage(sim.heroes, 0, victim, SHOT, callout);
    expect(callout.streakCallout).toBe("더블 킬!");
    expect(callout.streakSubtitle).toBe("P1 ZIP님이 2연속 처치 중입니다.");
    expect(callout.streakCalloutTicks).toBe(STREAK_CALLOUT_TICKS);
    expect(callout.streakCalloutShutdown).toBe(false);
    primeFinish(victim);
    victim.killStreak = 3;
    victim.equipment = { ...victim.equipment, characterName: "REX" };
    applyScoredDamage(sim.heroes, 0, victim, SHOT, callout);
    expect(callout.streakCallout).toBe("연속 처치 종료!");
    expect(callout.streakSubtitle).toBe("P1 ZIP님이 P2 REX님의 3연속 처치를 끝냈습니다.");
    expect(callout.streakCalloutShutdown).toBe(true);
    tickStreakCallout(callout);
    expect(callout.streakCalloutTicks).toBe(STREAK_CALLOUT_TICKS - 1);
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
