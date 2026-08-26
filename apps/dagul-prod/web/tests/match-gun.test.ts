import { describe, expect, it } from "vitest";
import { makeEquipment } from "@/lib/hub/match-equipment";
import {
  BLAST_HOP_DAMAGE, BLAST_HOP_KB, BLADE_EVADE, BRACE_GUARD, BREAKER_GUARD, BURST_LEFT_DEFAULT,
  BRAWLER_HEAVY_DMG, BRAWLER_HEAVY_RADIUS, BRAWLER_KICK_MUL, BRAWLER_KICK_Y, LEECH_HEAL,
  MORTAR_RADIUS_MIN, MORTAR_SPLASH, MUZZLE_FRAME, PASSIVE_MUL, RADIUS_FIRE_MUL, RAIL_PASSIVE_DIST,
  RELOAD_MIN, SPEAR_PASSIVE_DIST, WEAVE_IMMUNITY, apply, applyEquipmentAttack, applyGunInput,
  applyGunLoot, applyMobility, attackDirection, equipmentSkillTable, gunReach, gunSeedFields,
  pelletOffset, projectileKind, rotateVec, seedGun, tick, tickGun, tryNormalAttack, tryStartReload,
  wantsFire, weaponPassiveDamageMul, type GunHero,
} from "@/lib/hub/match-gun";

const DT = 1 / 60;

function hero(id: string, over: Partial<GunHero> = {}): GunHero {
  const eq = makeEquipment(id);
  return {
    slot: 0, x: 4000, y: 2400, hp: eq.maxHp, maxHp: eq.maxHp, alive: true,
    stunTime: 0, launchTime: 0, rootTime: 0, facingX: 1, facingY: 0, aimX: 1, aimY: 0,
    ...gunSeedFields(eq), ...over, equipment: over.equipment ?? eq,
  };
}

describe("발사 모드·펠릿·스플래시·관통", () => {
  it("auto 는 홀드, semi/bolt/gl/lever 는 에지", () => {
    expect(wantsFire("auto", true, false)).toBe(true);
    expect(wantsFire("semi", true, false)).toBe(false);
    expect(wantsFire("semi", true, true)).toBe(true);
    expect(wantsFire("bolt", false, true)).toBe(true);
    expect(wantsFire("gl", true, false)).toBe(false);
    expect(wantsFire("lever", true, true)).toBe(true);
  });

  it("scatter 5펠릿 부채꼴, rail tracer+pierce3, mortar splash120", () => {
    const scatter = tryNormalAttack(hero("scatter"), { x: 1, y: 0 });
    expect(scatter.fired).toBe(true);
    expect(scatter.projectiles).toHaveLength(5);
    const offsets = [0, 1, 2, 3, 4].map((i) => pelletOffset(i, 5, 0.12));
    expect(offsets).toEqual([-0.24, -0.12, 0, 0.12, 0.24]);
    scatter.projectiles.forEach((p, i) => {
      const dir = rotateVec(1, 0, offsets[i] ?? 0);
      expect(p.vx).toBeCloseTo(dir.x * 800, 8);
      expect(p.vy).toBeCloseTo(dir.y * 800, 8);
      expect(p.kind).toBe("pellet");
      expect(p.radius).toBe(6 * RADIUS_FIRE_MUL);
      expect(p.pierce).toBe(0);
    });
    const rail = tryNormalAttack(hero("rail"), { x: 1, y: 0 });
    expect(rail.projectiles).toHaveLength(1);
    expect(rail.projectiles[0]?.kind).toBe("tracer");
    expect(rail.projectiles[0]?.pierce).toBe(3);
    expect(projectileKind("rail", "bolt")).toBe("tracer");
    const mortar = tryNormalAttack(hero("mortar"), { x: 1, y: 0 });
    expect(mortar.projectiles).toHaveLength(1);
    expect(mortar.projectiles[0]?.kind).toBe("shell");
    expect(mortar.projectiles[0]?.splash).toBe(MORTAR_SPLASH);
    expect(mortar.projectiles[0]?.radius).toBe(Math.max(9 * RADIUS_FIRE_MUL, MORTAR_RADIUS_MIN));
    expect(mortar.projectiles[0]?.pierce).toBe(0);
  });

  it("bomb mag_size>0 이라 burst 게이트는 건너뛰고 탄만 6발", () => {
    const h = hero("bomb");
    expect(h.equipment.burstShots).toBe(2);
    expect(h.equipment.magSize).toBe(2);
    const r = tryNormalAttack(h, { x: 1, y: 0 });
    expect(r.projectiles).toHaveLength(6);
    expect(h.mag).toBe(1);
    expect(h.fireCd).toBe(0.22);
  });

  it("burst_shots>0 이고 mag_size=0 이면 버스트 소진 후 reload_time 간격", () => {
    const h = hero("burst");
    h.equipment = { ...h.equipment, burstShots: 2, magSize: 0 };
    h.burstLeft = 2;
    h.mag = 5;
    tryNormalAttack(h, { x: 1, y: 0 });
    expect(h.burstLeft).toBe(1);
    expect(h.fireCd).toBe(h.equipment.interval);
    tryNormalAttack(h, { x: 1, y: 0 });
    expect(h.burstLeft).toBe(2);
    expect(h.fireCd).toBe(h.equipment.reloadTime);
  });
});

describe("재장전·틱·시드", () => {
  it("탄 바닥이면 try_start_reload, stun/launch 는 재장전 취소", () => {
    const h = hero("burst", { mag: 0 });
    const r = tryNormalAttack(h, { x: 1, y: 0 });
    expect(r.fired).toBe(false);
    expect(r.startedReload).toBe(true);
    expect(h.reloadLeft).toBe(Math.max(RELOAD_MIN, 1.15));
    h.stunTime = 1;
    tickGun(h, DT);
    expect(h.reloadLeft).toBe(0);
    expect(seedGun).toBe(gunSeedFields);
    expect(tick).toBe(tickGun);
    expect(apply).toBe(applyGunInput);
  });

  it("발사 후 mag 0 이면 fire_cd 와 reload 동시, 스프레이 유휴 회복", () => {
    const h = hero("rail", { mag: 1 });
    const r = tryNormalAttack(h, { x: 1, y: 0 });
    expect(h.mag).toBe(0);
    expect(r.startedReload).toBe(true);
    expect(h.fireCd).toBe(1.22);
    expect(h.reloadLeft).toBe(2.40);
    expect(h.muzzleTime).toBe(4 * MUZZLE_FRAME);
    h.sprayIndex = 4;
    h.sprayIdle = 0.2;
    tickGun(h, 0.1);
    expect(h.sprayIndex).toBeCloseTo(4 - 0.1 * 6.0, 8);
  });
});

describe("무기 패시브", () => {
  it("brawler 3번째 샷 헤비: 데미지x2 반경x2.5 킥x2.7+(0,-7)", () => {
    const h = hero("brawler");
    tryNormalAttack(h, { x: 1, y: 0 });
    expect(h.brawlerShot).toBe(1);
    expect(h.heavyShot).toBe(false);
    tryNormalAttack(hero("brawler", { brawlerShot: 1, fireCd: 0 }), { x: 1, y: 0 });
    const third = hero("brawler", { brawlerShot: 2 });
    const r = tryNormalAttack(third, { x: 1, y: 0 });
    expect(third.heavyShot).toBe(true);
    expect(r.projectiles[0]?.damage).toBeCloseTo(46.8 * BRAWLER_HEAVY_DMG, 10);
    expect(r.projectiles[0]?.radius).toBeCloseTo(5 * RADIUS_FIRE_MUL * BRAWLER_HEAVY_RADIUS, 10);
    expect(r.projectiles[0]?.heavy).toBe(true);
    expect(third.sprayIndex).toBe(3);
    expect(r.mouseKick.y).toBeCloseTo(sprayYHeavy(), 8);
  });

  it("COMEBACK/rail/spear 거리 패시브는 1.12 배율, elif 이라 중첩 없음", () => {
    expect(weaponPassiveDamageMul("brawler", 88, 176, 0)).toBe(PASSIVE_MUL);
    expect(weaponPassiveDamageMul("brawler", 89, 176, 0)).toBe(1);
    expect(weaponPassiveDamageMul("rail", 100, 141, RAIL_PASSIVE_DIST)).toBe(PASSIVE_MUL);
    expect(weaponPassiveDamageMul("rail", 100, 141, RAIL_PASSIVE_DIST - 1)).toBe(1);
    expect(weaponPassiveDamageMul("spear", 100, 204, SPEAR_PASSIVE_DIST)).toBe(PASSIVE_MUL);
    expect(weaponPassiveDamageMul("burst", 1, 137, 9999)).toBe(1);
  });
});

function sprayYHeavy(): number {
  return -18 * BRAWLER_KICK_MUL + BRAWLER_KICK_Y;
}

describe("우클릭 스킬 테이블·모빌리티·루트", () => {
  it("try_equipment_attack 은 no-op, 스킬 이름 공란 cooldown 99", () => {
    for (const d of ["scatter", "rail", "shield"] as const) {
      const t = equipmentSkillTable(d);
      expect(t.skillName).toBe("");
      expect(t.implemented).toBe(false);
      expect(t.cooldown).toBe(99.0);
    }
    const h = hero("burst");
    applyEquipmentAttack(h, { x: 1, y: 0 });
    expect(h.mag).toBe(18);
  });

  it("모빌리티: leech +8, breaker guard 0.80, blade evade 0.48, shield brace 1.20", () => {
    const leech = hero("leech", { hp: 10 });
    applyMobility(leech, { x: 1, y: 0 }, []);
    expect(leech.hp).toBe(10 + LEECH_HEAL);
    expect(leech.mobilityCd).toBe(5.0);
    const breaker = hero("breaker");
    applyMobility(breaker, { x: 1, y: 0 }, []);
    expect(breaker.guardTime).toBe(BREAKER_GUARD);
    const blade = hero("blade");
    applyMobility(blade, { x: 1, y: 0 }, []);
    expect(blade.evadeTime).toBe(BLADE_EVADE);
    const brawler = hero("brawler");
    applyMobility(brawler, { x: 1, y: 0 }, []);
    expect(brawler.comboImmunity).toBe(WEAVE_IMMUNITY);
    const shield = hero("shield");
    applyMobility(shield, { x: 1, y: 0 }, []);
    expect(shield.guardTime).toBe(BRACE_GUARD);
  });

  it("mortar BLAST HOP 은 120px 안 적에게 2/0.12/72", () => {
    const mortar = hero("mortar", { slot: 0, x: 4000, y: 2400 });
    const near = hero("burst", { slot: 1, x: 4000 + 50, y: 2400 });
    const far = hero("burst", { slot: 2, x: 4000 + 200, y: 2400 });
    const r = applyMobility(mortar, { x: 0, y: 1 }, [], [mortar, near, far]);
    expect(r.hits).toHaveLength(1);
    expect(r.hits[0].targetSlot).toBe(1);
    expect(r.hits[0].damage).toBe(BLAST_HOP_DAMAGE);
    expect(r.hits[0].knockback).toBe(BLAST_HOP_KB);
  });

  it("gun loot: gun-semi 체인 진행, full 허용, item 모드 거부, brawler 정지", () => {
    const h = hero("rail");
    expect(applyGunLoot(h, "item")).toBe(false);
    expect(applyGunLoot(h, "gun-semi")).toBe(true);
    expect(h.equipment.id).toBe("burst");
    expect(h.mag).toBe(18);
    expect(h.burstLeft).toBe(BURST_LEFT_DEFAULT);
    const last = hero("brawler");
    expect(applyGunLoot(last, "full")).toBe(false);
    const unknown = hero("burst");
    unknown.equipment = { ...unknown.equipment, id: "mystery" };
    expect(applyGunLoot(unknown, "full")).toBe(true);
    expect(unknown.equipment.id).toBe("rail");
  });

  it("applyGunInput: 모빌리티가 발사를 막고, auto 홀드로 발사", () => {
    const h = hero("burst");
    const idle = applyGunInput(h, {
      primary: true, primaryPressed: false, reload: false, mobility: false,
      moveX: 0, moveY: 0, equipmentPressed: true,
    }, []);
    expect(idle.used).toBe(true);
    expect(idle.kind).toBe("fire");
    expect(idle.projectiles).toHaveLength(1);
    const semi = hero("brawler");
    const held = applyGunInput(semi, {
      primary: true, primaryPressed: false, reload: false, mobility: false,
      moveX: 0, moveY: 0, equipmentPressed: false,
    }, []);
    expect(held.used).toBe(false);
    const dash = hero("burst");
    const mob = applyGunInput(dash, {
      primary: true, primaryPressed: true, reload: false, mobility: true,
      moveX: 1, moveY: 0, equipmentPressed: false,
    }, []);
    expect(mob.kind).toBe("mobility");
    expect(dash.fireCd).toBe(0);
  });
});

describe("유틸", () => {
  it("attackDirection 제로벡터는 RIGHT, gunReach 는 0.92", () => {
    expect(attackDirection(0, 0)).toEqual({ x: 1, y: 0 });
    const h = hero("burst");
    expect(gunReach(h)).toBeCloseTo(1000 * 0.44 * 0.92, 10);
    expect(tryStartReload(hero("burst"))).toBe(false);
  });
});
