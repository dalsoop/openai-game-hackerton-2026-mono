import { describe, expect, it } from "vitest";
import {
  TOWER_ASSIST_RATIO, TOWER_ASSIST_WINDOW_TICKS, TOWER_DAMAGE, TOWER_INTERVAL,
  TOWER_KILLER_ROULETTE, TOWER_MAX_HP, TOWER_RADIUS, TOWER_RANGE, TOWER_SPAWN_TIME,
  hurtTower, packMidTowerSnap, resetMidTower, seedMidTower, tickMidTower, updateMidTower,
} from "@/lib/hub/match-tower";
import type { SimMidTower, TowerHero, TowerHooks, TowerShell, TowerZone } from "@/lib/hub/match-tower";
import { ARENA_CENTER, HERO_RADIUS } from "@/lib/hub/match-covers";

/** 중앙 바운티 타워 — 원본 mid_tower.gd 수치 그대로의 회귀. */

const DT = 1 / 60;

function hero(slot: number, over: Partial<TowerHero> = {}): TowerHero {
  return { slot, x: ARENA_CENTER.x + 400, y: ARENA_CENTER.y, alive: true, eliminated: false, ...over };
}

function heroMap(...list: TowerHero[]): Map<number, TowerHero> {
  return new Map(list.map((h) => [h.slot, h]));
}

type Collected = {
  shells: TowerShell[];
  zones: TowerZone[];
  envDamage: Array<{ slot: number; damage: number }>;
  pushes: Array<{ slot: number; pushX: number; pushY: number }>;
};

function collector(): { hooks: TowerHooks; got: Collected } {
  const got: Collected = { shells: [], zones: [], envDamage: [], pushes: [] };
  const hooks: TowerHooks = {
    damageHeroEnvironment: (slot, damage) => got.envDamage.push({ slot, damage }),
    pushHero: (slot, pushX, pushY) => got.pushes.push({ slot, pushX, pushY }),
    spawnShell: (shell) => got.shells.push(shell),
    spawnZone: (zone) => got.zones.push(zone),
  };
  return { hooks, got };
}

describe("타워 스폰", () => {
  it("reset — 스폰 전 상태: alive/spawned false, hp 2400, 아레나 중앙", () => {
    const t = resetMidTower();
    expect(t.spawned).toBe(false);
    expect(t.alive).toBe(false);
    expect(t.hp).toBe(TOWER_MAX_HP);
    expect(t.maxHp).toBe(2400);
    expect(t.x).toBe(ARENA_CENTER.x);
    expect(t.y).toBe(ARENA_CENTER.y);
    expect(t.pattern).toBe(0);
    expect(t.lastHit).toBe(-1);
    expect(seedMidTower().hp).toBe(t.hp);
    expect(tickMidTower).toBe(updateMidTower);
  });

  it("match_time 75초 전에는 스폰하지 않는다", () => {
    const t = resetMidTower();
    const { hooks } = collector();
    updateMidTower(t, heroMap(hero(0)), true, TOWER_SPAWN_TIME - 0.01, hooks, DT);
    expect(t.spawned).toBe(false);
    expect(t.alive).toBe(false);
  });

  it("75초에 스폰 — alive, hp 2400, 첫 발사 대기 1.2초, 그 틱은 발사 없음", () => {
    const t = resetMidTower();
    const { hooks, got } = collector();
    updateMidTower(t, heroMap(hero(0)), true, TOWER_SPAWN_TIME, hooks, DT);
    expect(t.spawned).toBe(true);
    expect(t.alive).toBe(true);
    expect(t.hp).toBe(TOWER_MAX_HP);
    expect(t.fireCd).toBeCloseTo(1.2, 9);
    expect(got.shells).toHaveLength(0);
    expect(TOWER_SPAWN_TIME).toBe(75);
  });

  it("playing 아니면 스폰·발사 모두 정지", () => {
    const t = resetMidTower();
    const { hooks } = collector();
    updateMidTower(t, heroMap(hero(0)), false, 120, hooks, DT);
    expect(t.spawned).toBe(false);
  });
});

describe("타워 발사 주기·패턴 (1.85초 간격, 3패턴 순환)", () => {
  function runUntilFire(
    t: SimMidTower,
    heroes: Map<number, TowerHero>,
    got: Collected,
    hooks: TowerHooks,
    maxTicks: number,
  ): number {
    const before = got.shells.length + got.zones.length;
    for (let i = 1; i <= maxTicks; i += 1) {
      updateMidTower(t, heroes, true, 100, hooks, DT);
      if (got.shells.length + got.zones.length > before) {return i;}
    }
    return -1;
  }

  it("스폰 1.2초 후 첫 발사 — 링샷 10발, 데미지 22, 다음 대기 1.85초", () => {
    const t = resetMidTower();
    const heroes = heroMap(hero(0));
    const { hooks, got } = collector();
    updateMidTower(t, heroes, true, TOWER_SPAWN_TIME, hooks, DT);
    const ticks = runUntilFire(t, heroes, got, hooks, 200);
    // 1.2초 = 72틱 (부동소수 오차 ±1틱)
    expect(Math.abs(ticks - 72)).toBeLessThanOrEqual(1);
    expect(got.shells).toHaveLength(10);
    for (const s of got.shells) {
      expect(s.damage).toBe(TOWER_DAMAGE);
      expect(s.owner).toBe(-1);
      expect(s.kind).toBe("shell");
      expect(s.source).toBe("tower");
      expect(Math.hypot(s.vx, s.vy)).toBeCloseTo(620, 6);
      expect(s.splash).toBe(46);
      expect(s.ttl).toBe(1.15);
    }
    expect(t.pattern).toBe(1);
    expect(t.fireCd).toBeCloseTo(TOWER_INTERVAL, 9);
    expect(TOWER_INTERVAL).toBe(1.85);
  });

  it("2번째 발사 — 1.85초(111틱) 뒤 부채꼴 7발 데미지 26, 대기 1.85*0.82", () => {
    const t = resetMidTower();
    const heroes = heroMap(hero(0));
    const { hooks, got } = collector();
    updateMidTower(t, heroes, true, TOWER_SPAWN_TIME, hooks, DT);
    runUntilFire(t, heroes, got, hooks, 200);
    got.shells.length = 0;
    const ticks = runUntilFire(t, heroes, got, hooks, 300);
    expect(Math.abs(ticks - Math.round(TOWER_INTERVAL * 60))).toBeLessThanOrEqual(1);
    expect(got.shells).toHaveLength(7);
    for (const s of got.shells) {
      expect(s.damage).toBe(TOWER_DAMAGE + 4);
      expect(Math.hypot(s.vx, s.vy)).toBeCloseTo(860, 6);
      expect(s.splash).toBe(58);
      expect(s.ttl).toBe(0.95);
    }
    expect(t.pattern).toBe(2);
    expect(t.fireCd).toBeCloseTo(TOWER_INTERVAL * 0.82, 9);
  });

  it("3번째 발사 — 카펫: 장판 6개(BOOM 30딜) + 부채꼴 3발, 대기 1.85*1.15, 패턴 0 복귀", () => {
    const t = resetMidTower();
    const heroes = heroMap(hero(0));
    const { hooks, got } = collector();
    updateMidTower(t, heroes, true, TOWER_SPAWN_TIME, hooks, DT);
    runUntilFire(t, heroes, got, hooks, 200);
    runUntilFire(t, heroes, got, hooks, 300);
    got.shells.length = 0;
    const ticks = runUntilFire(t, heroes, got, hooks, 300);
    expect(Math.abs(ticks - Math.round(TOWER_INTERVAL * 0.82 * 60))).toBeLessThanOrEqual(1);
    expect(got.zones).toHaveLength(6);
    got.zones.forEach((z, i) => {
      expect(z.damage).toBe(TOWER_DAMAGE + 8);
      expect(z.radius).toBe(78);
      expect(z.delay).toBeCloseTo(0.42 + i * 0.08, 9);
      expect(z.knockback).toBe(26);
      expect(z.kind).toBe("tower");
    });
    expect(got.shells).toHaveLength(3);
    expect(t.fireCd).toBeCloseTo(TOWER_INTERVAL * 1.15, 9);
    expect(t.pattern % 3).toBe(0);
  });

  it("사거리 820 밖 히어로만 있으면 발사하지 않는다", () => {
    const t = resetMidTower();
    const heroes = heroMap(hero(0, { x: ARENA_CENTER.x + TOWER_RANGE + 5 }));
    const { hooks, got } = collector();
    updateMidTower(t, heroes, true, TOWER_SPAWN_TIME, hooks, DT);
    for (let i = 0; i < 240; i += 1) {updateMidTower(t, heroes, true, 100, hooks, DT);}
    expect(got.shells).toHaveLength(0);
    expect(got.zones).toHaveLength(0);
  });
});

describe("근접 크러시 (tower_point_blank)", () => {
  it("도달 86+20+26 이내면 환경피해 22*0.85, 밀치기 34, 재사용 0.32초", () => {
    const t = resetMidTower();
    const reach = TOWER_RADIUS + HERO_RADIUS + 26;
    const heroes = heroMap(hero(0, { x: ARENA_CENTER.x + reach - 1 }));
    const { hooks, got } = collector();
    updateMidTower(t, heroes, true, TOWER_SPAWN_TIME, hooks, DT);
    updateMidTower(t, heroes, true, 100, hooks, DT);
    expect(got.envDamage).toEqual([{ slot: 0, damage: TOWER_DAMAGE * 0.85 }]);
    expect(got.pushes).toHaveLength(1);
    expect(Math.hypot(got.pushes[0].pushX, got.pushes[0].pushY)).toBeCloseTo(34, 6);
    expect(t.crushCd).toBeCloseTo(0.32, 9);
    // 재사용 대기 동안 추가 크러시 없음
    updateMidTower(t, heroes, true, 100, hooks, DT);
    expect(got.envDamage).toHaveLength(1);
  });

  it("도달 밖이면 크러시 없음", () => {
    const t = resetMidTower();
    const reach = TOWER_RADIUS + HERO_RADIUS + 26;
    const heroes = heroMap(hero(0, { x: ARENA_CENTER.x + reach + 2 }));
    const { hooks, got } = collector();
    updateMidTower(t, heroes, true, TOWER_SPAWN_TIME, hooks, DT);
    updateMidTower(t, heroes, true, 100, hooks, DT);
    expect(got.envDamage).toHaveLength(0);
  });
});

describe("타워 피해·파괴 보상 (hurt_tower)", () => {
  function spawned(): SimMidTower {
    const t = resetMidTower();
    const { hooks } = collector();
    updateMidTower(t, heroMap(hero(0)), true, TOWER_SPAWN_TIME, hooks, DT);
    return t;
  }

  it("스폰 전·0 이하 피해는 무시", () => {
    const t = resetMidTower();
    expect(hurtTower(t, 0, 100, 10, heroMap(hero(0)))).toBeNull();
    expect(t.hp).toBe(TOWER_MAX_HP);
    const t2 = spawned();
    expect(hurtTower(t2, 0, 0, 10, heroMap(hero(0)))).toBeNull();
  });

  it("피해 누적 — hp 감소, last_hit·hits 기록", () => {
    const t = spawned();
    expect(hurtTower(t, 2, 500, 100, heroMap(hero(2)))).toBeNull();
    expect(t.hp).toBe(TOWER_MAX_HP - 500);
    expect(t.lastHit).toBe(2);
    expect(t.hits.get(2)).toEqual({ dmg: 500, tick: 100 });
  });

  it("파괴 — 막타 killer, 432(=2400*0.18)+ 피해 8초 창 내 생존자만 어시스트", () => {
    const t = spawned();
    const heroes = heroMap(hero(0), hero(1), hero(2), hero(3, { alive: false }), hero(4));
    const need = Math.max(28, TOWER_MAX_HP * TOWER_ASSIST_RATIO);
    expect(need).toBe(432);
    hurtTower(t, 4, need, 90, heroes); // 8초 창 밖으로 밀려날 것
    hurtTower(t, 1, need, 200, heroes); // 어시스트 자격
    hurtTower(t, 2, need - 50, 200, heroes); // 피해 부족
    hurtTower(t, 3, need, 200, heroes); // 죽은 히어로
    const lastTick = 90 + TOWER_ASSIST_WINDOW_TICKS + 10; // slot4 기록만 창 밖
    const down = hurtTower(t, 0, TOWER_MAX_HP, lastTick, heroes);
    expect(down).not.toBeNull();
    expect(t.alive).toBe(false);
    expect(t.hp).toBe(0);
    expect(down?.killer).toBe(0);
    expect(down?.assists).toEqual([1]);
    expect(TOWER_KILLER_ROULETTE).toBe(3);
    expect(TOWER_ASSIST_WINDOW_TICKS).toBe(480);
  });

  it("막타가 이미 죽었으면 killer -1 (보상 없음)", () => {
    const t = spawned();
    const deadFinisher = heroMap(hero(0, { alive: false }), hero(1));
    hurtTower(t, 1, 432, 100, deadFinisher);
    const down = hurtTower(t, 0, TOWER_MAX_HP, 110, deadFinisher);
    expect(down?.killer).toBe(-1);
    expect(down?.assists).toEqual([1]);
  });
});

describe("스냅 계약 (Godot parse_mid_tower)", () => {
  it("mid_tower — alive·x·y·hp·max_hp·boing", () => {
    const t = resetMidTower();
    t.alive = true;
    t.hp = 1234;
    t.boing = 0.22;
    expect(packMidTowerSnap(t)).toEqual({
      alive: true,
      x: ARENA_CENTER.x,
      y: ARENA_CENTER.y,
      hp: 1234,
      max_hp: 2400,
      boing: 0.22,
    });
  });
});
