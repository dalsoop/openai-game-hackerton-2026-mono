import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";
import { downHero, DOWN_FINISH_HP, willConfirmKill } from "@/lib/hub/match-life";
import { ASSIST_HP_RATIO, recordLifeHit } from "@/lib/hub/match-wanted";
import {
  grantKillCreditRoulettes, settleExecuteKill, snapshotKillCredit,
} from "@/lib/hub/match-kill-credit";
import { FINISH_TOTAL, tryBeginFinish } from "@/lib/hub/match-finish";
import { ARENA_CENTER } from "@/lib/hub/match-covers";
import { applyScoredDamage, FIXED_DT, KILL_SCORE, MatchSim } from "@/lib/hub/match-sim";

function three(): MatchSim {
  const sim = new MatchSim([{ slot: 0 }, { slot: 1 }, { slot: 2 }]);
  sim.countdown = 0;
  return sim;
}

describe("snapshotKillCredit", () => {
  it("downHero 가 lifeHits 를 지워도 스냅의 어시는 남는다", () => {
    const sim = three();
    const vic = sim.heroes.get(1);
    const assist = sim.heroes.get(2);
    if (!vic || !assist) {return;}
    const need = Math.max(28, vic.maxHp * ASSIST_HP_RATIO);
    recordLifeHit(vic.lifeHits, 2, need, sim.tick);
    const credit = snapshotKillCredit(0, vic, sim.heroes, sim.tick, sim.wanted);
    expect(credit.assists).toEqual([2]);
    expect(credit.defeatedStreak).toBe(0);
    downHero(sim.heroes, 0, vic);
    expect(vic.lifeHits).toEqual({});
    grantKillCreditRoulettes(sim.heroes, credit, sim.matchRng);
    expect(assist.rouletteRank).toBe("assist");
  });
});

describe("settleExecuteKill", () => {
  it("F 확인사살은 킬 점수와 어시 룰렛을 같이 준다", () => {
    const sim = three();
    const atk = sim.heroes.get(0);
    const vic = sim.heroes.get(1);
    const assist = sim.heroes.get(2);
    if (!atk || !vic || !assist) {return;}
    vic.downed = true;
    vic.hp = 0;
    vic.killStreak = 0;
    recordLifeHit(vic.lifeHits, 2, Math.max(28, vic.maxHp * ASSIST_HP_RATIO), sim.tick);
    const before = atk.score;
    settleExecuteKill(sim.heroes, 0, vic, sim.tick, sim.wanted, sim.matchRng, sim.streakState);
    expect(vic.alive).toBe(false);
    expect(atk.kills).toBe(1);
    expect(atk.score).toBeCloseTo(before + KILL_SCORE);
    expect(atk.rouletteRank).toBe("kill");
    expect(assist.rouletteRank).toBe("assist");
  });
});

describe("MatchSim F 확인사살", () => {
  it("시네가 끝나면 점수·어시가 정산된다", () => {
    const sim = three();
    const atk = sim.heroes.get(0);
    const vic = sim.heroes.get(1);
    const assist = sim.heroes.get(2);
    if (!atk || !vic || !assist) {return;}
    atk.x = ARENA_CENTER.x;
    atk.y = ARENA_CENTER.y;
    vic.x = ARENA_CENTER.x + 80;
    vic.y = ARENA_CENTER.y;
    vic.alive = true;
    vic.downed = true;
    vic.hp = 0;
    vic.downLeft = 4;
    recordLifeHit(vic.lifeHits, 2, Math.max(28, vic.maxHp * ASSIST_HP_RATIO), sim.tick);
    expect(tryBeginFinish(sim.finishCine, sim.heroes, 0)).toBe(true);
    const ticks = Math.ceil(FINISH_TOTAL / FIXED_DT) + 8;
    for (let i = 0; i < ticks; i += 1) {sim.step(FIXED_DT);}
    expect(vic.alive).toBe(false);
    expect(atk.kills).toBe(1);
    expect(atk.score).toBeGreaterThanOrEqual(KILL_SCORE);
    expect(assist.rouletteRank).toBe("assist");
  });
});

describe("총 막타 확인사살", () => {
  it("hurtHero 와 같이 스냅 후 점수·어시를 지급한다", () => {
    const sim = three();
    const atk = sim.heroes.get(0);
    const vic = sim.heroes.get(1);
    const assist = sim.heroes.get(2);
    if (!atk || !vic || !assist) {return;}
    vic.alive = true;
    vic.downed = true;
    vic.hp = 0;
    vic.downTaken = DOWN_FINISH_HP - 1;
    recordLifeHit(vic.lifeHits, 2, Math.max(28, vic.maxHp * ASSIST_HP_RATIO), sim.tick);
    const shot = 8;
    expect(willConfirmKill(vic, shot)).toBe(true);
    const credit = snapshotKillCredit(0, vic, sim.heroes, sim.tick, sim.wanted);
    expect(credit.assists).toEqual([2]);
    expect(applyScoredDamage(sim.heroes, 0, vic, shot, sim.streakState)).toBe("dead");
    grantKillCreditRoulettes(sim.heroes, credit, sim.matchRng);
    expect(atk.kills).toBe(1);
    expect(atk.score).toBeGreaterThanOrEqual(KILL_SCORE);
    expect(assist.rouletteRank).toBe("assist");
  });
});

describe("원본 down_hero 계약", () => {
  it("허브 시네는 downHero 만 부르지 않고 settleExecuteKill 을 탄다", () => {
    const sim = readFileSync(join(process.cwd(), "lib/hub/match-sim.ts"), "utf8");
    const cine = sim.slice(sim.indexOf("private stepFinishCine"), sim.indexOf("private static readonly CORE_RADIUS"));
    expect(cine).toContain("settleExecuteKill");
    expect(cine).not.toMatch(/downHero\(/);
    const gd = readFileSync(join(process.cwd(), "..", "project/games/dagul/game.gd"), "utf8");
    expect(gd).not.toContain("func down_hero");
    expect(gd).not.toContain("_reward_attacker");
  });
});

