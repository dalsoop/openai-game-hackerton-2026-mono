import { describe, expect, it } from "vitest";
import {
  CRATE_MAX_HP, CRATE_ORB_ARM, CRATE_ORB_DMG_MUL, CRATE_ORB_DMG_TIME, CRATE_ORB_ULT_RATIO,
  CRATE_RADIUS, bestCrate, bestCrateOrb, collectCrateOrb, crateSeedFields, damageCratesAt, hurtCrate,
  packCrateOrbsSnap, packCratesSnap, spawnBreakableCrates, spawnCrateOrb, tickDmgOrbTime, updateCrateOrbs,
} from "@/lib/hub/match-crate";
import type { CrateHero, SimCrate, SimCrateOrb } from "@/lib/hub/match-crate";
import {
  ARENA_CENTER, ARENA_MARGIN, ARENA_SIZE, SPAWN_RADIUS, buildTiledCovers, pointInCover,
} from "@/lib/hub/match-covers";

/** 크레이트+오브 — 원본 crate_pickup.gd 수치 그대로의 회귀. */

const DT = 1 / 60;
const COVERS = buildTiledCovers();

function hero(slot: number, over: Partial<CrateHero> = {}): CrateHero {
  return {
    slot, x: ARENA_CENTER.x, y: ARENA_CENTER.y, alive: true, eliminated: false,
    dmgOrbTime: 0, ultimateCharge: 0, ...over,
  };
}

function heroMap(...list: CrateHero[]): Map<number, CrateHero> {
  return new Map(list.map((h) => [h.slot, h]));
}

describe("크레이트 링 배치", () => {
  it("링 3개 = 8 + 8 + 4 = 20개, id 순차, hp 48", () => {
    const crates = spawnBreakableCrates(COVERS);
    expect(crates).toHaveLength(20);
    expect(crates.filter((c) => c.ring === 0)).toHaveLength(8);
    expect(crates.filter((c) => c.ring === 1)).toHaveLength(8);
    expect(crates.filter((c) => c.ring === 2)).toHaveLength(4);
    crates.forEach((c, i) => {
      expect(c.id).toBe(i);
      expect(c.alive).toBe(true);
      expect(c.hp).toBe(CRATE_MAX_HP);
      expect(c.maxHp).toBe(CRATE_MAX_HP);
    });
  });

  it("빨강/파랑 교대 — 링 A·C 는 red_first, 링 B 는 blue_first (10 vs 10)", () => {
    const crates = spawnBreakableCrates(COVERS);
    // 링 A (id 0-7): 짝수 n 빨강
    for (let n = 0; n < 8; n += 1) {expect(crates[n].orbRed).toBe(n % 2 === 0);}
    // 링 B (id 8-15): 홀수 n 빨강
    for (let n = 0; n < 8; n += 1) {expect(crates[8 + n].orbRed).toBe(n % 2 === 1);}
    // 링 C (id 16-19): 짝수 n 빨강
    for (let n = 0; n < 4; n += 1) {expect(crates[16 + n].orbRed).toBe(n % 2 === 0);}
    expect(crates.filter((c) => c.orbRed)).toHaveLength(10);
  });

  it("전 크레이트가 커버 밖·아레나 마진 안 (반경 탐색 결과)", () => {
    const crates = spawnBreakableCrates(COVERS);
    for (const c of crates) {
      expect(pointInCover(c.x, c.y, COVERS, CRATE_RADIUS)).toBe(false);
      expect(c.x).toBeGreaterThanOrEqual(ARENA_MARGIN + CRATE_RADIUS);
      expect(c.x).toBeLessThanOrEqual(ARENA_SIZE.x - ARENA_MARGIN - CRATE_RADIUS);
      expect(c.y).toBeGreaterThanOrEqual(ARENA_MARGIN + CRATE_RADIUS);
      expect(c.y).toBeLessThanOrEqual(ARENA_SIZE.y - ARENA_MARGIN - CRATE_RADIUS);
    }
  });

  it("링 A 첫 크레이트는 12시 방향 — 중심 위쪽 y = 2380 - 1940*0.82*scale", () => {
    const crates = spawnBreakableCrates(COVERS);
    expect(crates[0].x).toBeCloseTo(ARENA_CENTER.x, 6);
    expect(crates[0].y).toBeLessThan(ARENA_CENTER.y);
    const dy = ARENA_CENTER.y - crates[0].y;
    const scale = dy / (SPAWN_RADIUS.y * 0.82);
    // 반경 배율 후보는 1.0±0.028k — 탐색 결과가 후보 범위 안이어야 한다
    expect(scale).toBeGreaterThanOrEqual(1 - 11 * 0.028 - 1e-9);
    expect(scale).toBeLessThanOrEqual(1 + 15 * 0.028 + 1e-9);
  });

  it("배치는 결정론 — 두 번 만들면 완전히 같다", () => {
    expect(spawnBreakableCrates(COVERS)).toEqual(spawnBreakableCrates(COVERS));
  });
});

describe("크레이트 피해·파괴 → 오브 생성", () => {
  it("부분 피해는 hp 만 줄고 오브 없음", () => {
    const crates = spawnBreakableCrates(COVERS);
    const orbs: SimCrateOrb[] = [];
    expect(hurtCrate(crates, orbs, 0, 20)).toBe(false);
    expect(crates[0].hp).toBe(28);
    expect(crates[0].alive).toBe(true);
    expect(orbs).toHaveLength(0);
  });

  it("48 피해로 파괴 — 오브 색은 orbRed, arm 0.25, 제자리 생성", () => {
    const crates = spawnBreakableCrates(COVERS);
    const orbs: SimCrateOrb[] = [];
    expect(hurtCrate(crates, orbs, 0, CRATE_MAX_HP)).toBe(true);
    expect(crates[0].alive).toBe(false);
    expect(crates[0].hp).toBe(0);
    expect(orbs).toHaveLength(1);
    expect(orbs[0].red).toBe(crates[0].orbRed);
    expect(orbs[0].arm).toBe(CRATE_ORB_ARM);
    expect(orbs[0].x).toBeCloseTo(crates[0].x);
    expect(orbs[0].y).toBeCloseTo(crates[0].y);
    expect(orbs[0].active).toBe(true);
    expect(orbs[0].magnetSlot).toBe(-1);
  });

  it("죽은 크레이트·0 이하 피해는 무시 (오브 중복 생성 없음)", () => {
    const crates = spawnBreakableCrates(COVERS);
    const orbs: SimCrateOrb[] = [];
    hurtCrate(crates, orbs, 0, CRATE_MAX_HP);
    expect(hurtCrate(crates, orbs, 0, 10)).toBe(false);
    expect(hurtCrate(crates, orbs, 1, 0)).toBe(false);
    expect(hurtCrate(crates, orbs, -1, 10)).toBe(false);
    expect(orbs).toHaveLength(1);
    expect(crates[1].hp).toBe(CRATE_MAX_HP);
  });

  it("스플래시 — 반경 + CRATE_RADIUS 이내만 피해", () => {
    const crates: SimCrate[] = [
      { id: 0, x: 1000, y: 1000, hp: 48, maxHp: 48, alive: true, ring: 0, orbRed: true },
      { id: 1, x: 1000 + 100 + CRATE_RADIUS - 1, y: 1000, hp: 48, maxHp: 48, alive: true, ring: 0, orbRed: false },
      { id: 2, x: 1000 + 100 + CRATE_RADIUS + 1, y: 1000, hp: 48, maxHp: 48, alive: true, ring: 0, orbRed: false },
    ];
    const orbs: SimCrateOrb[] = [];
    damageCratesAt(crates, orbs, 1000, 1000, 100, 30);
    expect(crates[0].hp).toBe(18);
    expect(crates[1].hp).toBe(18);
    expect(crates[2].hp).toBe(48);
  });
});

describe("오브 자석·습득 효과", () => {
  it("arm(0.25초) 동안은 끌리지 않는다", () => {
    const orb = spawnCrateOrb(1000, 1000, true);
    const h = hero(0, { x: 1100, y: 1000 });
    const orbs = [orb];
    for (let i = 0; i < 14; i += 1) {updateCrateOrbs(orbs, heroMap(h), DT);}
    expect(orbs).toHaveLength(1);
    expect(orbs[0].x).toBe(1000);
    expect(h.dmgOrbTime).toBe(0);
  });

  it("arm 소진 후 760px/s 로 끌린다", () => {
    const orb = spawnCrateOrb(1000, 1000, true);
    orb.arm = 0;
    const h = hero(0, { x: 1200, y: 1000 });
    const orbs = [orb];
    updateCrateOrbs(orbs, heroMap(h), DT);
    expect(orbs[0].x).toBeCloseTo(1000 + 760 * DT);
    expect(orbs[0].magnetSlot).toBe(0);
  });

  it("반경 217 밖 히어로는 무시", () => {
    const orb = spawnCrateOrb(1000, 1000, true);
    orb.arm = 0;
    const h = hero(0, { x: 1000 + 250, y: 1000 });
    const orbs = [orb];
    updateCrateOrbs(orbs, heroMap(h), DT);
    expect(orbs[0].x).toBe(1000);
    expect(orbs[0].magnetSlot).toBe(-1);
  });

  it("빨간 오브 — dmg_orb_time 12초 (피해 배율 1.25 는 상수로 공표)", () => {
    const orb = spawnCrateOrb(1000, 1000, true);
    const h = hero(0, { x: 1000, y: 1000 });
    const orbs = [orb];
    for (let i = 0; i < 16; i += 1) {updateCrateOrbs(orbs, heroMap(h), DT);}
    expect(orbs).toHaveLength(0);
    expect(h.dmgOrbTime).toBe(CRATE_ORB_DMG_TIME);
    expect(h.ultimateCharge).toBe(0);
    expect(CRATE_ORB_DMG_TIME).toBe(12);
    expect(CRATE_ORB_DMG_MUL).toBe(1.25);
  });

  it("파란 오브 — 궁극기 +34 (100 * 0.34), 상한 100", () => {
    const h = hero(0);
    collectCrateOrb(h, spawnCrateOrb(0, 0, false));
    expect(h.ultimateCharge).toBeCloseTo(100 * CRATE_ORB_ULT_RATIO);
    expect(h.dmgOrbTime).toBe(0);
    const h2 = hero(1, { ultimateCharge: 90 });
    collectCrateOrb(h2, spawnCrateOrb(0, 0, false));
    expect(h2.ultimateCharge).toBe(100);
    expect(CRATE_ORB_ULT_RATIO).toBe(0.34);
  });

  it("죽은/탈락 히어로에게는 끌리지 않고 대상 재탐색", () => {
    const orb = spawnCrateOrb(1000, 1000, false);
    orb.arm = 0;
    orb.magnetSlot = 0;
    const dead = hero(0, { x: 1010, y: 1000, alive: false });
    const near = hero(1, { x: 1100, y: 1000 });
    const orbs = [orb];
    updateCrateOrbs(orbs, heroMap(dead, near), DT);
    expect(orbs[0].magnetSlot).toBe(1);
  });
});

describe("CPU 표적 탐색", () => {
  it("bestCrate — 480 이내 최근접 생존 크레이트, 밖이면 -1", () => {
    const crates: SimCrate[] = [
      { id: 0, x: 1300, y: 1000, hp: 48, maxHp: 48, alive: true, ring: 0, orbRed: true },
      { id: 1, x: 1100, y: 1000, hp: 0, maxHp: 48, alive: false, ring: 0, orbRed: true },
      { id: 2, x: 1200, y: 1000, hp: 48, maxHp: 48, alive: true, ring: 0, orbRed: true },
    ];
    expect(bestCrate(1000, 1000, crates)).toBe(2);
    expect(bestCrate(5000, 5000, crates)).toBe(-1);
  });

  it("bestCrateOrb — 420 이내, arm 소진 + 활성만", () => {
    const armed = spawnCrateOrb(1050, 1000, true);
    const ready = spawnCrateOrb(1300, 1000, true);
    ready.arm = 0;
    expect(bestCrateOrb(1000, 1000, [armed, ready])).toBe(1);
    expect(bestCrateOrb(3000, 1000, [armed, ready])).toBe(-1);
  });
});

describe("dmg_orb_time 틱", () => {
  it("update_timers 와 같이 초당 1 감소, 하한 0", () => {
    const h = hero(0, { ...crateSeedFields(), dmgOrbTime: 12 });
    tickDmgOrbTime([h], 1);
    expect(h.dmgOrbTime).toBe(11);
    tickDmgOrbTime([h], 20);
    expect(h.dmgOrbTime).toBe(0);
  });
});

describe("스냅 계약 (Godot parse_crates / parse_crate_orbs)", () => {
  it("crates — id·x·y·hp·max_hp·alive, 죽은 크레이트 포함 전체", () => {
    const crates = spawnBreakableCrates(COVERS);
    const orbs: SimCrateOrb[] = [];
    hurtCrate(crates, orbs, 0, CRATE_MAX_HP);
    const snap = packCratesSnap(crates);
    expect(snap).toHaveLength(20);
    expect(snap[0]).toEqual({ id: 0, x: crates[0].x, y: crates[0].y, hp: 0, max_hp: 48, alive: false });
    expect(snap[1]).toEqual({ id: 1, x: crates[1].x, y: crates[1].y, hp: 48, max_hp: 48, alive: true });
  });

  it("crate_orbs — x·y·red·active", () => {
    const snap = packCrateOrbsSnap([spawnCrateOrb(10, 20, true), spawnCrateOrb(30, 40, false)]);
    expect(snap).toEqual([
      { x: 10, y: 20, red: true, active: true },
      { x: 30, y: 40, red: false, active: true },
    ]);
  });
});
