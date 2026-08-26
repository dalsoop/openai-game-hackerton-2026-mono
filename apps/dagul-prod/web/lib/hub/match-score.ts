/**
 * 점수·킬 스트릭·셧다운 — 원본 _reward_attacker(match_lifecycle.gd:462-503) +
 * damage_system.gd:343-345 의 결정론 포팅. RNG·시계 없음.
 */
import { ELIMINATE_SCORE } from "./match-core.js";
import { applyHeroDamage } from "./match-life.js";
import type { LifeEvent, LifeHero } from "./match-life.js";
import { applyShutdownBountyDrop, awardKillBounty } from "./match-wanted.js";

/** 킬 확정 점수 — attacker["score"] += 120.0. */
export const KILL_SCORE = 120;
/** 스트릭 보너스 계수 — (streak_after - 1) * 15.0. */
export const STREAK_BONUS_STEP = 15;
/** 셧다운 발동 최소 피살자 스트릭 — defeated_streak >= 3. */
export const SHUTDOWN_MIN_STREAK = 3;
/** 셧다운 보너스 — min(230, 90 + (defeated_streak - 3) * 35). */
export const SHUTDOWN_BASE = 90;
export const SHUTDOWN_STEP = 35;
export const SHUTDOWN_MAX = 230;
/** 킬 threat 가산 — match_lifecycle.gd:472. */
export const KILL_THREAT_GAIN = 18;
/** 킬 궁극기 충전 — match_lifecycle.gd:481. */
export const KILL_ULT_GAIN = 35;
/** 모멘텀 힐 — max_hp * min(0.10, 0.055 + streak*0.01). */
export const KILL_HEAL_BASE = 0.055;
export const KILL_HEAL_STEP = 0.01;
export const KILL_HEAL_CAP = 0.10;
/** 킬 쿨다운 감소 — equipment 0.50+streak*0.10, mobility 0.35+streak*0.08. */
export const KILL_EQUIP_CD_BASE = 0.50;
export const KILL_EQUIP_CD_STEP = 0.10;
export const KILL_MOBILITY_CD_BASE = 0.35;
export const KILL_MOBILITY_CD_STEP = 0.08;
/** 셧다운 전투 보상 — 힐 max_hp*0.14, CD *0.50, 궁 +20. */
export const SHUTDOWN_HEAL_RATIO = 0.14;
export const SHUTDOWN_CD_MUL = 0.50;
export const SHUTDOWN_ULT_GAIN = 20;
/** 우승 점수 — safe_zone_logic.gd:111. */
export const WIN_SCORE = 500;
/** 콜아웃 표시 틱 — show_streak_callout ticks=150. */
export const STREAK_CALLOUT_TICKS = 150;
/** game_world.gd ULTIMATE_MAX — 이 파일에서만 쓰는 상한(export 충돌 방지). */
const ULT_CAP = 100;

export { ELIMINATE_SCORE };

export type ScoreFields = {
  score: number;
  killStreak: number;
  bestStreak: number;
  damageDealt: number;
};

export type KillCombatFields = {
  threat: number;
  bounty: number;
  equipmentCd: number;
  mobilityCd: number;
  ultimateCharge: number;
  eliminations: number;
  equipment?: { characterName?: string };
};

export type ScoreHero = LifeHero & ScoreFields & Partial<KillCombatFields>;

export type StreakCalloutState = {
  streakCallout: string;
  streakSubtitle: string;
  streakCalloutTicks: number;
  streakCalloutShutdown: boolean;
};

/** SimHero 생성 시 점수/스트릭 초기 필드 묶음. */
export function scoreSeedFields(): ScoreFields {
  return { score: 0, killStreak: 0, bestStreak: 0, damageDealt: 0 };
}

export function streakCalloutSeed(): StreakCalloutState {
  return {
    streakCallout: "", streakSubtitle: "", streakCalloutTicks: 0, streakCalloutShutdown: false,
  };
}

/** 콜아웃 틱 감소 — match_lifecycle.gd:15. */
export function tickStreakCallout(state: StreakCalloutState): void {
  state.streakCalloutTicks = Math.max(0, state.streakCalloutTicks - 1);
}

/** 피해 1:1 적립 — damage_system.gd:344-345. 자해·환경(owner<0)은 미적립(사양 10번). */
export function awardDamageScore(
  heroes: ReadonlyMap<number, ScoreHero>,
  owner: number,
  targetSlot: number,
  amount: number,
): void {
  if (owner < 0 || owner === targetSlot) {return;}
  const attacker = heroes.get(owner);
  if (!attacker) {return;}
  attacker.damageDealt += amount;
  attacker.score += amount;
}

/** 셧다운 보너스 수치 — 피살자 스트릭 3 미만이면 0. */
export function shutdownBonus(defeatedStreak: number): number {
  if (defeatedStreak < SHUTDOWN_MIN_STREAK) {return 0;}
  return Math.min(
    SHUTDOWN_MAX,
    SHUTDOWN_BASE + (defeatedStreak - SHUTDOWN_MIN_STREAK) * SHUTDOWN_STEP,
  );
}

/** 모멘텀 힐 비율 — min(0.10, 0.055 + streak*0.01). */
export function momentumHealRatio(streakAfter: number): number {
  return Math.min(KILL_HEAL_CAP, KILL_HEAL_BASE + streakAfter * KILL_HEAL_STEP);
}

export function awardEliminateScore(attacker: { score: number }): void {
  attacker.score += ELIMINATE_SCORE;
}

export function awardWinScore(attacker: { score: number }): void {
  attacker.score += WIN_SCORE;
}

function addHp(hero: ScoreHero, amount: number): void {
  hero.hp = Math.min(hero.maxHp, hero.hp + amount);
}

function cutCd(hero: ScoreHero, key: "equipmentCd" | "mobilityCd", cut: number): void {
  const cur = hero[key];
  if (cur === undefined) {return;}
  hero[key] = Math.max(0, cur - cut);
}

function applyAliveKillRewards(attacker: ScoreHero): number {
  const streakAfter = attacker.killStreak + 1;
  attacker.killStreak = streakAfter;
  attacker.bestStreak = Math.max(attacker.bestStreak, streakAfter);
  addHp(attacker, attacker.maxHp * momentumHealRatio(streakAfter));
  cutCd(attacker, "equipmentCd", KILL_EQUIP_CD_BASE + streakAfter * KILL_EQUIP_CD_STEP);
  cutCd(attacker, "mobilityCd", KILL_MOBILITY_CD_BASE + streakAfter * KILL_MOBILITY_CD_STEP);
  attacker.score += Math.max(0, (streakAfter - 1) * STREAK_BONUS_STEP);
  return streakAfter;
}

function applyShutdownCombat(attacker: ScoreHero): void {
  if (!attacker.alive) {return;}
  addHp(attacker, attacker.maxHp * SHUTDOWN_HEAL_RATIO);
  if (attacker.equipmentCd !== undefined) {attacker.equipmentCd *= SHUTDOWN_CD_MUL;}
  if (attacker.mobilityCd !== undefined) {attacker.mobilityCd *= SHUTDOWN_CD_MUL;}
  if (attacker.ultimateCharge !== undefined) {
    attacker.ultimateCharge = Math.min(ULT_CAP, attacker.ultimateCharge + SHUTDOWN_ULT_GAIN);
  }
}

function showStreakCallout(
  state: StreakCalloutState, title: string, subtitle: string, shutdown: boolean,
): void {
  state.streakCallout = title;
  state.streakSubtitle = subtitle;
  state.streakCalloutShutdown = shutdown;
  state.streakCalloutTicks = STREAK_CALLOUT_TICKS;
}

/* eslint-disable no-restricted-syntax -- 원본 match_lifecycle.gd:246-255,494-498 한국어 콜아웃 정본 */
export function streakTitle(streak: number): string {
  if (streak >= 6) {return "막을 수 없습니다!";}
  if (streak === 5) {return "폭주 중!";}
  if (streak === 4) {return "학살 중!";}
  if (streak === 3) {return "연속 처치!";}
  return "더블 킬!";
}

function heroName(hero: ScoreHero | undefined, slot: number): string {
  return hero?.equipment?.characterName ?? `P${slot + 1}`;
}

function fillKillCallout(
  state: StreakCalloutState | undefined,
  attacker: ScoreHero,
  victim: ScoreHero | undefined,
  owner: number,
  targetSlot: number,
  streakAfter: number,
  defeatedStreak: number,
  shutdown: boolean,
): void {
  if (!state) {return;}
  const atkName = heroName(attacker, owner);
  if (shutdown) {
    const vicName = heroName(victim, targetSlot);
    showStreakCallout(
      state, "연속 처치 종료!",
      `P${owner + 1} ${atkName}님이 P${targetSlot + 1} ${vicName}님의 ${defeatedStreak}연속 처치를 끝냈습니다.`,
      true,
    );
    return;
  }
  if (streakAfter < 2) {return;}
  showStreakCallout(
    state, streakTitle(streakAfter),
    `P${owner + 1} ${atkName}님이 ${streakAfter}연속 처치 중입니다.`,
    false,
  );
}
/* eslint-enable no-restricted-syntax */

/**
 * 킬 보상 — match_lifecycle.gd:462-503.
 * 120점 + bounty +12 + threat 18 + eliminations++ + 생존 시 스트릭·힐·CD·ult+35.
 * 셧다운이면 bounty -20 과 전투 보상. 자해·환경은 미지급.
 */
export function awardKillScore(
  heroes: ReadonlyMap<number, ScoreHero>,
  owner: number,
  targetSlot: number,
  defeatedStreak: number,
  callout?: StreakCalloutState,
): void {
  if (owner < 0 || owner === targetSlot) {return;}
  const attacker = heroes.get(owner);
  if (!attacker) {return;}
  attacker.score += KILL_SCORE;
  if (attacker.threat !== undefined) {attacker.threat += KILL_THREAT_GAIN;}
  if (attacker.bounty !== undefined) {awardKillBounty(attacker as { bounty: number });}
  if (attacker.eliminations !== undefined) {attacker.eliminations += 1;}
  let streakAfter = 0;
  if (attacker.alive) {
    streakAfter = applyAliveKillRewards(attacker);
    if (attacker.ultimateCharge !== undefined) {
      attacker.ultimateCharge = Math.min(ULT_CAP, attacker.ultimateCharge + KILL_ULT_GAIN);
    }
  }
  const bonus = shutdownBonus(defeatedStreak);
  attacker.score += bonus;
  if (bonus > 0) {
    applyShutdownCombat(attacker);
    if (attacker.bounty !== undefined) {applyShutdownBountyDrop(attacker as { bounty: number });}
  }
  fillKillCallout(
    callout, attacker, heroes.get(targetSlot), owner, targetSlot, streakAfter, defeatedStreak, bonus > 0,
  );
}

/**
 * 점수 연동 피해 파이프라인 — 탄·확인사살(다운 마무리) 공용.
 * 차단(사망·스폰 무적)은 match-life 와 같은 조건으로 선판정해 실제 적용분만 적립하고,
 * 확정 킬이면 다운 진입 전 피살자 스트릭으로 셧다운을 계산한다.
 */
export function applyScoredDamage(
  heroes: ReadonlyMap<number, ScoreHero>,
  owner: number,
  target: ScoreHero,
  amount: number,
  callout?: StreakCalloutState,
): LifeEvent {
  if (!target.alive || target.spawnProtect > 0) {return "none";}
  const defeatedStreak = target.killStreak;
  const event = applyHeroDamage(heroes, owner, target, amount);
  awardDamageScore(heroes, owner, target.slot, amount);
  if (event === "dead") {awardKillScore(heroes, owner, target.slot, defeatedStreak, callout);}
  return event;
}

/** 사망자 스트릭 소거 — down_hero 의 kill_streak=0. 환경사(자기장·출혈) 포함 전 경로. */
export function resetDeadStreaks(heroes: Iterable<ScoreHero>): void {
  for (const h of heroes) {
    if (!h.alive) {h.killStreak = 0;}
  }
}
export const seed = scoreSeedFields;
export const apply = applyScoredDamage;
export const tick = resetDeadStreaks;
