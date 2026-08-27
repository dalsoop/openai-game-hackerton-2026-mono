import { describe, expect, it } from "vitest";
import { ComboCap } from "@/lib/hub/match-combo-cap";
import { COMBO_TIME_FINISHER, tickCc } from "@/lib/hub/match-cc";
import { EQUIPMENT_DEFS, makeEquipment } from "@/lib/hub/match-equipment";
import { DOWN_FINISH_HP, MatchSim, type SimBullet, type SimHero } from "@/lib/hub/match-sim";
import { ARENA_CENTER } from "@/lib/hub/match-covers";
import { startLaunch } from "@/lib/hub/match-launch";

/** pjh smoke_test.gd:560-586 · 11_STATUS_DESIGN.md §2.2 — 한 콤보로 안 죽고, 킬은 4~5콤보다. */
const DT = 1 / 60;
/** 피니셔 창 0.38 + 만료 면역 0.58 보다 긴 간격 — smoke `_update_timers(1.2)`. */
const COMBO_GAP = 1.2;
const STRING_HITS = 4;
const STRING_DAMAGE = 50;
const STRING_KNOCKBACK = 22;

type HurtFn = (
  owner: number,
  victim: SimHero,
  amount: number,
  source?: string,
  ctx?: { attackFinisher?: boolean; knockback?: number },
) => void;

function openFight(): { sim: MatchSim; a: SimHero; b: SimHero; hurt: HurtFn } {
  const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
  sim.countdown = 0;
  sim.matchTime = 20;
  const a = sim.heroes.get(0);
  const b = sim.heroes.get(1);
  if (!a || !b) {throw new Error("heroes");}
  a.spawnProtect = 0;
  b.spawnProtect = 0;
  a.x = ARENA_CENTER.x;
  a.y = ARENA_CENTER.y;
  b.x = a.x + 80;
  b.y = a.y;
  const hurt = (sim as unknown as { hurtHero: HurtFn }).hurtHero.bind(sim);
  return { sim, a, b, hurt };
}

function wear(hero: SimHero, equipmentId: string): void {
  hero.equipment = makeEquipment(equipmentId);
  hero.maxHp = hero.equipment.maxHp;
  hero.hp = hero.maxHp;
  hero.weight = hero.equipment.weight;
}

function strikeString(hurt: HurtFn, owner: number, victim: SimHero): void {
  for (let hit = 0; hit < STRING_HITS; hit += 1) {
    hurt(owner, victim, STRING_DAMAGE, "normal", {
      attackFinisher: hit === STRING_HITS - 1,
      knockback: STRING_KNOCKBACK,
    });
  }
}

function waitComboGap(sim: MatchSim): void {
  const ticks = Math.ceil(COMBO_GAP / DT);
  for (let i = 0; i < ticks; i += 1) {tickCc(sim.heroes.values(), DT);}
}

/** 서 있음 = 살아 있고 다운이 아님. 4타 문자열 중 다운 직후 남은 타가 확인사살하면 alive 도 꺼진다. */
function standing(hero: SimHero): boolean {
  return hero.alive && !hero.downed;
}

function pelletAt(sim: MatchSim, id: number, owner: number, x: number, y: number, damage: number): void {
  const bullet: SimBullet = {
    id, x, y, vx: 0, vy: 0, owner, ttl: 1, kind: "pellet",
    damage, radius: 80, splash: 0, pierce: 0, knockback: 24,
    source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [],
    homing: 0, arc: false, landingX: 0, landingY: 0, maxTtl: 1, comboFinisher: false,
    label: "", controlKind: "slow",
  };
  sim.bullets.set(id, bullet);
}

describe("커리어 콤보 예산 — 11_STATUS_DESIGN.md §2.2", () => {
  it("12 커리어 모두 한 콤보 한도는 체력의 24~27% 다", () => {
    expect(EQUIPMENT_DEFS).toHaveLength(12);
    for (const def of EQUIPMENT_DEFS) {
      const eq = makeEquipment(def.id);
      expect(eq.comboCapRatio, def.id).toBeGreaterThanOrEqual(0.24);
      expect(eq.comboCapRatio, def.id).toBeLessThanOrEqual(0.27);
      const limit = ComboCap.limitOf(eq.maxHp, eq.comboCapRatio);
      expect(limit, def.id).toBeLessThan(eq.maxHp * 0.5);
      expect(limit, def.id).toBeGreaterThan(eq.maxHp * 0.2);
    }
  });

  it("한도는 피해자 몸통이지 공격자 총이 아니다", () => {
    const { a, b, hurt } = openFight();
    wear(a, "rail");
    wear(b, "shield");
    const victimCap = ComboCap.limitOf(b.maxHp, b.equipment.comboCapRatio);
    const attackerCap = ComboCap.limitOf(a.maxHp, a.equipment.comboCapRatio);
    expect(victimCap).not.toBeCloseTo(attackerCap, 5);
    hurt(0, b, 142);
    expect(b.comboDamage).toBeCloseTo(victimCap, 5);
    expect(b.hp).toBeCloseTo(b.maxHp - victimCap, 5);
    expect(b.downed).toBe(false);
  });

  it("풀피에서 한 콤보(4타)로는 어떤 커리어도 다운되지 않는다", () => {
    for (const def of EQUIPMENT_DEFS) {
      const { b, hurt } = openFight();
      wear(b, def.id);
      strikeString(hurt, 0, b);
      const floor = b.maxHp * (1 - b.equipment.comboCapRatio);
      expect(b.alive, def.id).toBe(true);
      expect(b.downed, def.id).toBe(false);
      expect(b.comboHits, def.id).toBe(STRING_HITS);
      expect(b.hp, def.id).toBeGreaterThanOrEqual(floor - 0.01);
    }
  });

  it("AWM 한 발은 유리 몸(버스트)을 한 방에 다운시키지 않는다", () => {
    const { a, b, hurt } = openFight();
    wear(a, "rail");
    wear(b, "burst");
    hurt(0, b, a.equipment.damage);
    expect(b.downed).toBe(false);
    expect(b.hp).toBeCloseTo(b.maxHp - ComboCap.limitOf(b.maxHp, b.equipment.comboCapRatio), 5);
  });

  it("SPAS 5펠릿이 한 틱에 다 맞아도 한 콤보 예산을 넘지 않는다", () => {
    const { sim, a, b } = openFight();
    wear(a, "scatter");
    wear(b, "burst");
    const floor = b.maxHp * (1 - b.equipment.comboCapRatio);
    for (let i = 0; i < a.equipment.projectiles; i += 1) {
      pelletAt(sim, 200 + i, 0, b.x, b.y, a.equipment.damage);
    }
    sim.step(DT);
    expect(sim.bullets.size).toBe(0);
    expect(b.downed).toBe(false);
    expect(b.hp).toBeGreaterThanOrEqual(floor - 0.01);
    expect(b.comboDamage).toBeCloseTo(ComboCap.limitOf(b.maxHp, b.equipment.comboCapRatio), 5);
  });

  it("더블배럴 12펠릿이 같은 콤보 창에 들어와도 한 예산이다", () => {
    const { sim, a, b } = openFight();
    wear(a, "bomb");
    wear(b, "burst");
    const pellets = a.equipment.projectiles * Math.max(1, a.equipment.burstShots);
    for (let i = 0; i < pellets; i += 1) {
      pelletAt(sim, 300 + i, 0, b.x, b.y, a.equipment.damage);
    }
    sim.step(DT);
    expect(b.downed).toBe(false);
    expect(b.hp).toBeGreaterThanOrEqual(b.maxHp * (1 - b.equipment.comboCapRatio) - 0.01);
  });

  it("콤보가 끊긴 뒤에는 예산이 리셋되고, 4~5콤보 안에 다운된다", () => {
    const { sim, b, hurt } = openFight();
    wear(b, "burst");
    strikeString(hurt, 0, b);
    expect(standing(b)).toBe(true);
    let comboCount = 1;
    while (standing(b) && comboCount < 5) {
      waitComboGap(sim);
      comboCount += 1;
      strikeString(hurt, 0, b);
    }
    expect(standing(b)).toBe(false);
    expect(comboCount).toBeGreaterThanOrEqual(4);
    expect(comboCount).toBeLessThanOrEqual(5);
  });

  it("탱크 몸(브레이커)도 5콤보를 넘기기 전에 다운된다", () => {
    const { sim, b, hurt } = openFight();
    wear(b, "breaker");
    strikeString(hurt, 0, b);
    let comboCount = 1;
    while (standing(b) && comboCount < 5) {
      waitComboGap(sim);
      comboCount += 1;
      strikeString(hurt, 0, b);
    }
    expect(standing(b)).toBe(false);
    expect(comboCount).toBeGreaterThanOrEqual(4);
    expect(comboCount).toBeLessThanOrEqual(5);
  });

  it("한 콤보의 마지막 타는 살린 채로 피니셔 런치를 연다", () => {
    const { b, hurt } = openFight();
    wear(b, "burst");
    strikeString(hurt, 0, b);
    expect(b.downed).toBe(false);
    expect(b.comboTime).toBe(COMBO_TIME_FINISHER);
    expect(Math.hypot(b.launchVel.x, b.launchVel.y)).toBeGreaterThan(1200);
  });

  it("모빌리티 피해는 콤보 예산을 쓰지 않는다", () => {
    const { b, hurt } = openFight();
    wear(b, "burst");
    hurt(0, b, 200, "mobility");
    expect(b.comboDamage).toBe(0);
    expect(b.downed).toBe(true);
    expect(b.hp).toBe(0);
  });

  it("다운 중 확인사살은 콤보 상한을 타지 않는다", () => {
    const { b, hurt } = openFight();
    wear(b, "burst");
    b.hp = 0;
    b.downed = true;
    b.downLeft = 5;
    b.downTaken = 0;
    hurt(0, b, DOWN_FINISH_HP);
    expect(b.alive).toBe(false);
    expect(b.downed).toBe(false);
  });

  it("벽 튕김은 히트가 남긴 잔여 예산을 이어서 쓴다", () => {
    const eq = makeEquipment("burst");
    const cap = ComboCap.limitOf(eq.maxHp, eq.comboCapRatio);
    const spent = cap - 6;
    const launch = startLaunch({
      pos: { x: 2000, y: 2000 },
      direction: { x: 1, y: 0 },
      launchKnockback: 126,
      weight: eq.weight,
      owner: 0,
      source: "normal",
      comboDamage: spent,
    });
    expect(launch.launchWallDamage).toBe(spent);
    const wall = { ...launch, maxHp: eq.maxHp, comboCapRatio: eq.comboCapRatio };
    expect(ComboCap.takeWall(wall, 36)).toBeCloseTo(6, 10);
    expect(wall.launchWallDamage).toBeCloseTo(cap, 10);
    expect(ComboCap.takeWall(wall, 15)).toBe(0);
  });
});
