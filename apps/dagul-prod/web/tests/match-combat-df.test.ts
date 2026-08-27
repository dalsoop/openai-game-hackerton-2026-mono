import { describe, expect, it } from "vitest";
import { packAuthoritySnap } from "@/lib/hub/match-authority-snap";
import { CRATE_MAX_HP, CRATE_RADIUS } from "@/lib/hub/match-crate";
import { CORE_RADIUS } from "@/lib/hub/match-core";
import { ComboCap } from "@/lib/hub/match-combo-cap";
import { HERO_RADIUS } from "@/lib/hub/match-covers";
import { makeEquipment } from "@/lib/hub/match-equipment";
import { applyGunLoot, MORTAR_RADIUS_MIN, MORTAR_SPLASH, RADIUS_FIRE_MUL, tryNormalAttack } from "@/lib/hub/match-gun";
import { MatchSim } from "@/lib/hub/match-sim";
import { TOWER_MAX_HP, TOWER_RADIUS } from "@/lib/hub/match-tower";

const DT = 1 / 60;

function readySim(): MatchSim {
  const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
  sim.countdown = 0;
  return sim;
}

describe("P0 전투 결함", () => {
  it("1 mortar 일반공격은 직선 로켓 radius max(27,12) splash 120", () => {
    const h = readySim().heroes.get(0);
    if (!h) {throw new Error("hero");}
    h.equipment = makeEquipment("mortar");
    h.mag = h.equipment.magSize;
    const r = tryNormalAttack(h, { x: 1, y: 0 });
    expect(r.projectiles).toHaveLength(1);
    const [p] = r.projectiles;
    expect(p.arc ?? false).toBe(false);
    expect(p.kind).toBe("shell");
    expect(p.radius).toBe(Math.max(9 * RADIUS_FIRE_MUL, MORTAR_RADIUS_MIN));
    expect(p.splash).toBe(MORTAR_SPLASH);
    expect(p.vx).toBeCloseTo(620, 8);
  });

  it("2 DOUBLE BARREL 은 펠릿 6·mag 2·버스트 2", () => {
    const eq = makeEquipment("bomb");
    expect(eq.projectiles).toBe(6);
    expect(eq.burstShots).toBe(2);
    expect(eq.magSize).toBe(2);
    expect(eq.kind).toBe("pellet");
    const sim = readySim();
    const h = sim.heroes.get(0);
    if (!h) {throw new Error("hero");}
    h.equipment = eq;
    h.mag = 2;
    const r = tryNormalAttack(h, { x: 1, y: 0 });
    expect(r.projectiles).toHaveLength(6);
    expect(r.projectiles.every((p) => !p.arc && p.kind === "pellet")).toBe(true);
    expect(h.mag).toBe(1);
  });

  it("3 유탄 착탄은 풀딜 존 · radius+HERO_RADIUS", () => {
    const sim = readySim();
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    if (!a || !b) {throw new Error("heroes");}
    a.x = 2000;
    a.y = 2400;
    b.x = 2000 + 120 + HERO_RADIUS - 1;
    b.y = 2400;
    b.spawnProtect = 0;
    const hp = b.hp;
    sim.bullets.set(1, {
      id: 1, x: 1900, y: 2400, vx: 0, vy: 0, owner: 0, ttl: DT * 0.5, kind: "shell",
      damage: 88, radius: 11, splash: 120, pierce: 0, knockback: 42,
      source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [], homing: 0,
      arc: true, landingX: 2000, landingY: 2400, maxTtl: 0.4, comboFinisher: false,
      label: "", controlKind: "slow",
    });
    sim.step(DT);
    expect(sim.bullets.size).toBe(0);
    const applied = Math.min(88, ComboCap.limitOf(b.maxHp, b.equipment.comboCapRatio));
    expect(b.hp).toBeCloseTo(hp - applied, 4);
  });

  it("4 다운 중 use 는 메드킷을 쓰지 않는다", () => {
    const sim = readySim();
    const h = sim.heroes.get(0);
    if (!h) {throw new Error("hero");}
    h.downed = true;
    h.downLeft = 5;
    h.hp = 0;
    h.alive = true;
    h.medkits = 2;
    sim.pushInput(0, { use: true, seq: 1 });
    sim.step(DT);
    expect(h.medkits).toBe(2);
    expect(h.hp).toBe(0);
  });
});

describe("P1 전투 결함", () => {
  it("5 상자 명중 시 탄을 지운다", () => {
    const sim = readySim();
    const crate = sim.crates.find((c) => c.alive);
    if (!crate) {throw new Error("crate");}
    const hp = crate.hp;
    sim.bullets.set(3, {
      id: 3, x: crate.x, y: crate.y, vx: 0, vy: 0, owner: 0, ttl: 1, kind: "bolt",
      damage: 10, radius: CRATE_RADIUS, splash: 0, pierce: 0, knockback: 0,
      source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [], homing: 0,
      arc: false, landingX: 0, landingY: 0, maxTtl: 1, comboFinisher: false,
      label: "", controlKind: "slow",
    });
    sim.step(DT);
    expect(sim.bullets.size).toBe(0);
    expect(crate.hp).toBe(hp - 10);
    expect(hp).toBe(CRATE_MAX_HP);
  });

  it("5 코어 명중 시 탄을 지운다", () => {
    const sim = readySim();
    const core = sim.cores.find((c) => c.alive && c.slot === 1);
    const owner = sim.heroes.get(1);
    if (!core || !owner) {throw new Error("core");}
    owner.x = core.x + 400;
    owner.y = core.y;
    owner.stunTime = 1;
    const hp = core.hp;
    sim.bullets.set(4, {
      id: 4, x: core.x, y: core.y, vx: 0, vy: 0, owner: 0, ttl: 1, kind: "bolt",
      damage: 20, radius: CORE_RADIUS, splash: 0, pierce: 0, knockback: 0,
      source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [], homing: 0,
      arc: false, landingX: 0, landingY: 0, maxTtl: 1, comboFinisher: false,
      label: "", controlKind: "slow",
    });
    sim.step(DT);
    expect(sim.bullets.size).toBe(0);
    expect(core.hp).toBeLessThan(hp);
  });

  it("6 타워 피격이 탄을 소거한다", () => {
    const sim = readySim();
    sim.midTower.alive = true;
    sim.midTower.spawned = true;
    sim.midTower.hp = TOWER_MAX_HP;
    const hp = sim.midTower.hp;
    sim.bullets.set(5, {
      id: 5, x: sim.midTower.x, y: sim.midTower.y, vx: 0, vy: 0, owner: 0, ttl: 1, kind: "bolt",
      damage: 40, radius: TOWER_RADIUS, splash: 0, pierce: 0, knockback: 0,
      source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [], homing: 0,
      arc: false, landingX: 0, landingY: 0, maxTtl: 1, comboFinisher: false,
      label: "", controlKind: "slow",
    });
    sim.step(DT);
    expect(sim.bullets.size).toBe(0);
    expect(sim.midTower.hp).toBe(hp - 40);
  });

  it("7 총 루팅 후 스냅 weaponId 가 새 총이다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 1, "gun-semi");
    sim.countdown = 0;
    const h = sim.heroes.get(0);
    if (!h) {throw new Error("hero");}
    expect(h.equipmentId).toBe("rail");
    expect(applyGunLoot(h, "gun-semi")).toBe(true);
    const snap = packAuthoritySnap(sim, new Map(), "gun-semi") as {
      players: Array<{ slot: number; weaponId: string; weapon: string }>;
    };
    const row = snap.players.find((p) => p.slot === 0);
    expect(h.equipmentId).toBe("burst");
    expect(row?.weaponId).toBe("burst");
    expect(row?.weapon).toBe("GLOCK 18");
  });
});
