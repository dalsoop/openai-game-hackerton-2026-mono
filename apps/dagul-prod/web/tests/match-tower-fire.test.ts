import { describe, expect, it } from "vitest";
import {
  TOWER_DAMAGE, TOWER_INTERVAL, TOWER_RADIUS, applyTowerFire, firePattern,
  type TowerFireState, type TowerHooks, type TowerShell, type TowerZone,
} from "@/lib/hub/match-tower-fire";
import { seedMidTower } from "@/lib/hub/match-tower";
import { ARENA_CENTER } from "@/lib/hub/match-covers";

function collector(): { hooks: TowerHooks; shells: TowerShell[]; zones: TowerZone[] } {
  const shells: TowerShell[] = [];
  const zones: TowerZone[] = [];
  return {
    shells, zones,
    hooks: {
      damageHeroEnvironment: () => undefined,
      pushHero: () => undefined,
      spawnShell: (s) => shells.push(s),
      spawnZone: (z) => zones.push(z),
    },
  };
}

function towerState(): TowerFireState {
  return { x: ARENA_CENTER.x, y: ARENA_CENTER.y, fireCd: 0, pattern: 0, boing: 0 };
}

describe("타워 발사 패턴 (mid_tower.gd ring/fan/carpet)", () => {
  it("상수 — radius 86, interval 1.85, damage 22", () => {
    expect(TOWER_RADIUS).toBe(86);
    expect(TOWER_INTERVAL).toBe(1.85);
    expect(TOWER_DAMAGE).toBe(22);
  });

  it("pattern 0 — 링 10발 speed 620 splash 46 ttl 1.15, fireCd 1.85, boing 0.22", () => {
    const t = towerState();
    const { hooks, shells } = collector();
    applyTowerFire(t, t.x + 100, t.y, hooks);
    expect(firePattern).toBe(applyTowerFire);
    expect(shells).toHaveLength(10);
    for (const s of shells) {
      expect(s.damage).toBe(22);
      expect(Math.hypot(s.vx, s.vy)).toBeCloseTo(620, 6);
      expect(s.splash).toBe(46);
      expect(s.ttl).toBe(1.15);
      expect(s.radius).toBe(11);
      expect(s.knockback).toBe(22);
      expect(s.owner).toBe(-1);
      expect(s.source).toBe("tower");
      expect(Math.hypot(s.x - t.x, s.y - t.y)).toBeCloseTo(TOWER_RADIUS + 10, 6);
    }
    expect(t.fireCd).toBe(TOWER_INTERVAL);
    expect(t.boing).toBe(0.22);
    expect(t.pattern).toBe(1);
  });

  it("pattern 1 — 부채꼴 7발 speed 860 splash 58 ttl 0.95 dmg 26, fireCd 1.85*0.82", () => {
    const t = towerState();
    t.pattern = 1;
    const { hooks, shells } = collector();
    firePattern(t, t.x + 400, t.y, hooks);
    expect(shells).toHaveLength(7);
    for (const s of shells) {
      expect(s.damage).toBe(TOWER_DAMAGE + 4);
      expect(Math.hypot(s.vx, s.vy)).toBeCloseTo(860, 6);
      expect(s.splash).toBe(58);
      expect(s.ttl).toBe(0.95);
    }
    expect(t.fireCd).toBeCloseTo(TOWER_INTERVAL * 0.82, 9);
    expect(t.pattern).toBe(2);
  });

  it("pattern 2 — 카펫 장판 6 + 부채꼴 3, delay 0.42+i*0.08, dmg 30, knock 26, fireCd 1.85*1.15", () => {
    const t = towerState();
    t.pattern = 2;
    const { hooks, shells, zones } = collector();
    firePattern(t, t.x, t.y + 400, hooks);
    expect(zones).toHaveLength(6);
    zones.forEach((z, i) => {
      expect(z.damage).toBe(TOWER_DAMAGE + 8);
      expect(z.radius).toBe(78);
      expect(z.delay).toBeCloseTo(0.42 + i * 0.08, 9);
      expect(z.knockback).toBe(26);
      expect(z.label).toBe("BOOM");
      expect(z.kind).toBe("tower");
    });
    expect(shells).toHaveLength(3);
    expect(t.fireCd).toBeCloseTo(TOWER_INTERVAL * 1.15, 9);
    expect(t.pattern % 3).toBe(0);
  });

  it("seedMidTower — 스폰 전 fire_cd 0.8", () => {
    const t = seedMidTower();
    expect(t.fireCd).toBeCloseTo(0.8, 9);
    expect(t.hp).toBe(2400);
    expect(t.x).toBe(ARENA_CENTER.x);
  });
});
