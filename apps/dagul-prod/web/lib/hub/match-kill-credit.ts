/**
 * 확정 킬 정산 — lifeHits 원장은 downHero 가 지운다.
 * 어시·스트릭은 지우기 전에 스냅하고, 점수·룰렛은 그 스냅으로만 지급한다.
 * F 확인사살과 총 막타가 같은 계약을 쓴다.
 */
import { downHero, type LifeHero } from "./match-life.js";
import { awardKillScore, type ScoreFields, type StreakCalloutState } from "./match-score.js";
import {
  assistSlots, grantKillRoulettes, isBountyVictim,
  type LifeHitRec, type RouletteHero, type RouletteRng, type WantedState,
} from "./match-wanted.js";

export type KillCreditHero = LifeHero & {
  killStreak: number;
  lifeHits: Record<string, LifeHitRec>;
};

export type KillCredit = {
  owner: number;
  target: number;
  defeatedStreak: number;
  assists: readonly number[];
  bountyKill: boolean;
};

export function snapshotKillCredit(
  owner: number,
  victim: KillCreditHero,
  heroes: ReadonlyMap<number, { alive: boolean; maxHp: number }>,
  tick: number,
  wanted: WantedState,
): KillCredit {
  return {
    owner,
    target: victim.slot,
    defeatedStreak: victim.killStreak,
    assists: assistSlots(owner, victim.slot, victim.lifeHits, heroes, tick),
    bountyKill: isBountyVictim(wanted, victim.slot),
  };
}

export function grantKillCreditRoulettes(
  heroes: ReadonlyMap<number, RouletteHero>,
  credit: KillCredit,
  rng: RouletteRng,
): void {
  grantKillRoulettes(
    heroes, credit.owner, credit.target, credit.bountyKill, credit.assists, rng,
  );
}

/** F 확인사살: 원장 스냅 → downHero → 점수·룰렛. */
export function settleExecuteKill<H extends KillCreditHero & RouletteHero & ScoreFields>(
  heroes: ReadonlyMap<number, H>,
  owner: number,
  victim: H,
  tick: number,
  wanted: WantedState,
  rng: RouletteRng,
  callout?: StreakCalloutState,
): KillCredit {
  const credit = snapshotKillCredit(owner, victim, heroes, tick, wanted);
  downHero(heroes, owner, victim);
  awardKillScore(heroes, owner, victim.slot, credit.defeatedStreak, callout);
  grantKillCreditRoulettes(heroes, credit, rng);
  return credit;
}
