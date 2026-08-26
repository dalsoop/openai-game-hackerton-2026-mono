/**
 * 점수·킬 스트릭·셧다운 — 원본 _reward_attacker(match_lifecycle.gd:462-503) +
 * damage_system.gd:343-345 의 결정론 포팅. RNG·시계 없음.
 */
import { applyHeroDamage } from "./match-life.js";
import type { LifeEvent, LifeHero } from "./match-life.js";

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

export type ScoreFields = {
  score: number;
  killStreak: number;
  bestStreak: number;
  damageDealt: number;
};

export type ScoreHero = LifeHero & ScoreFields;

/** SimHero 생성 시 점수/스트릭 초기 필드 묶음. */
export function scoreSeedFields(): ScoreFields {
  return { score: 0, killStreak: 0, bestStreak: 0, damageDealt: 0 };
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

/**
 * 킬 보상 — kill 120 + 생존 시 스트릭 갱신·(streak-1)*15 보너스 + 셧다운 보너스.
 * 자해(owner === target)·환경(owner<0)은 미지급 — _reward_attacker 첫 가드 그대로.
 */
export function awardKillScore(
  heroes: ReadonlyMap<number, ScoreHero>,
  owner: number,
  targetSlot: number,
  defeatedStreak: number,
): void {
  if (owner < 0 || owner === targetSlot) {return;}
  const attacker = heroes.get(owner);
  if (!attacker) {return;}
  attacker.score += KILL_SCORE;
  if (attacker.alive) {
    const streakAfter = attacker.killStreak + 1;
    attacker.killStreak = streakAfter;
    attacker.bestStreak = Math.max(attacker.bestStreak, streakAfter);
    attacker.score += Math.max(0, (streakAfter - 1) * STREAK_BONUS_STEP);
  }
  attacker.score += shutdownBonus(defeatedStreak);
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
): LifeEvent {
  if (!target.alive || target.spawnProtect > 0) {return "none";}
  const defeatedStreak = target.killStreak;
  const event = applyHeroDamage(heroes, owner, target, amount);
  awardDamageScore(heroes, owner, target.slot, amount);
  if (event === "dead") {awardKillScore(heroes, owner, target.slot, defeatedStreak);}
  return event;
}

/** 사망자 스트릭 소거 — down_hero 의 kill_streak=0. 환경사(자기장·출혈) 포함 전 경로. */
export function resetDeadStreaks(heroes: Iterable<ScoreHero>): void {
  for (const h of heroes) {
    if (!h.alive) {h.killStreak = 0;}
  }
}
