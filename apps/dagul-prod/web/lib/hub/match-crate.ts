/**
 * 파괴 가능 크레이트 + 크레이트 오브 — 원본 crate_pickup.gd 의 결정론 포팅.
 * RNG·시계 없음: 링 배치(반경 탐색 포함)·오브 자석·버프 수치 전부 원본 그대로.
 * 히어로는 모듈 로컬 구조적 타입(CrateHero) — 통합 때 SimHero 로 합류한다.
 */
import {
  ARENA_CENTER,
  ARENA_MARGIN,
  ARENA_SIZE,
  HERO_RADIUS,
  SPAWN_RADIUS,
  pointInCover,
  type CoverRect,
} from "./match-covers.js";
import { HEALTH_PICKUP_MAGNET_RADIUS, HEALTH_PICKUP_MAGNET_SPEED } from "./match-loot.js";

export const CRATE_RADIUS = 28;
export const CRATE_MAX_HP = 48;
export const CRATE_ORB_RADIUS = 16;
/** 오브 생성 후 자석 비활성 시간(초) — CRATE_ORB_ARM. */
export const CRATE_ORB_ARM = 0.25;
/** 빨간 오브 데미지 버프 지속시간(초) — 통합측이 dmg_orb_time>0 이면 피해 x1.25. */
export const CRATE_ORB_DMG_TIME = 12;
/** 빨간 오브 데미지 배율 — damage_system.gd 소비측 수치의 SSOT. */
export const CRATE_ORB_DMG_MUL = 1.25;
/** 파란 오브 궁극기 충전 비율 — ULTIMATE_MAX(100) * 0.34 = +34. */
export const CRATE_ORB_ULT_RATIO = 0.34;
export const CRATE_RING_A_SCALE = 0.82;
export const CRATE_RING_B_SCALE = 0.52;
export const CRATE_RING_C_SCALE = 0.3;
/** game_world.gd ULTIMATE_MAX — 궁극기 게이지 상한. */
const ULTIMATE_MAX = 100;
/** 오브 습득 판정 거리 — HERO_RADIUS(20) + CRATE_ORB_RADIUS(16) = 36. */
const ORB_COLLECT_DIST = HERO_RADIUS + CRATE_ORB_RADIUS;

function sortedHeroes(heroes: Iterable<CrateHero>): CrateHero[] {
  return [...heroes].sort((a, b) => a.slot - b.slot);
}
/** CPU 크레이트 탐색 상한 — best_crate(crate_pickup.gd:137). */
const BEST_CRATE_DIST = 480;
/** CPU 오브 탐색 상한 — best_crate_orb(crate_pickup.gd:151). */
const BEST_ORB_DIST = 420;
const TAU = Math.PI * 2;

export type SimCrate = {
  id: number;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  alive: boolean;
  ring: number;
  orbRed: boolean;
};

export type SimCrateOrb = {
  x: number;
  y: number;
  homeX: number;
  homeY: number;
  red: boolean;
  arm: number;
  magnetSlot: number;
  active: boolean;
};

/** 오브 효과 대상 히어로 — 통합 때 SimHero 로 합류하는 구조적 타입. */
export type CrateHero = {
  slot: number;
  x: number;
  y: number;
  alive: boolean;
  eliminated: boolean;
  /** 빨간 오브 잔여 시간 — 0 으로 감소, >0 이면 피해 x CRATE_ORB_DMG_MUL. */
  dmgOrbTime: number;
  ultimateCharge: number;
};

export function crateHeroSeedFields(): Pick<CrateHero, "dmgOrbTime" | "ultimateCharge"> {
  return { dmgOrbTime: 0, ultimateCharge: 0 };
}

/** clamp_arena_point(pos, CRATE_RADIUS) — 크레이트 반경 기준 아레나 클램프. */
function clampCratePoint(x: number, y: number): { x: number; y: number } {
  const lo = ARENA_MARGIN + CRATE_RADIUS;
  return {
    x: Math.min(ARENA_SIZE.x - lo, Math.max(lo, x)),
    y: Math.min(ARENA_SIZE.y - lo, Math.max(lo, y)),
  };
}

function ringPos(
  n: number,
  count: number,
  rot: number,
  radiusX: number,
  radiusY: number,
  scale: number,
): { x: number; y: number } {
  const ang = -Math.PI * 0.5 + rot + (TAU * n) / count;
  return clampCratePoint(
    ARENA_CENTER.x + Math.cos(ang) * radiusX * scale,
    ARENA_CENTER.y + Math.sin(ang) * radiusY * scale,
  );
}

/** 반경 배율 후보 — 1.0+0.028i(16개) 다음 1.0-0.028i(11개), 원본 순서 그대로. */
function scaleCandidates(): number[] {
  const scales: number[] = [];
  for (let i = 0; i < 16; i += 1) {scales.push(1 + i * 0.028);}
  for (let i = 1; i < 12; i += 1) {scales.push(1 - i * 0.028);}
  return scales;
}

function ringBlocked(
  count: number,
  radiusX: number,
  radiusY: number,
  rot: number,
  scale: number,
  covers: readonly CoverRect[],
): boolean {
  for (let n = 0; n < count; n += 1) {
    const pos = ringPos(n, count, rot, radiusX, radiusY, scale);
    if (pointInCover(pos.x, pos.y, covers, CRATE_RADIUS)) {return true;}
  }
  return false;
}

function findRadialScale(
  count: number,
  radiusX: number,
  radiusY: number,
  rot: number,
  covers: readonly CoverRect[],
): number {
  for (const scale of scaleCandidates()) {
    if (!ringBlocked(count, radiusX, radiusY, rot, scale, covers)) {return scale;}
  }
  return 1;
}

function placeCrateRing(
  crates: SimCrate[],
  count: number,
  radiusX: number,
  radiusY: number,
  rot: number,
  ringId: number,
  redFirst: boolean,
  covers: readonly CoverRect[],
): void {
  const radialScale = findRadialScale(count, radiusX, radiusY, rot, covers);
  for (let n = 0; n < count; n += 1) {
    const pos = ringPos(n, count, rot, radiusX, radiusY, radialScale);
    const isRed = redFirst ? n % 2 === 0 : n % 2 === 1;
    crates.push({
      id: crates.length,
      x: pos.x,
      y: pos.y,
      hp: CRATE_MAX_HP,
      maxHp: CRATE_MAX_HP,
      alive: true,
      ring: ringId,
      orbRed: isRed,
    });
  }
}

/** 링 3개(8+8+4=20개) — spawn_breakable_crates(crate_pickup.gd:9-13) 그대로. */
export function spawnBreakableCrates(covers: readonly CoverRect[]): SimCrate[] {
  const crates: SimCrate[] = [];
  const rx = SPAWN_RADIUS.x;
  const ry = SPAWN_RADIUS.y;
  placeCrateRing(crates, 8, rx * CRATE_RING_A_SCALE, ry * CRATE_RING_A_SCALE, 0, 0, true, covers);
  placeCrateRing(crates, 8, rx * CRATE_RING_B_SCALE, ry * CRATE_RING_B_SCALE, Math.PI * 0.125, 1, false, covers);
  placeCrateRing(crates, 4, rx * CRATE_RING_C_SCALE, ry * CRATE_RING_C_SCALE, Math.PI * 0.25, 2, true, covers);
  return crates;
}

export const seedBreakableCrates = spawnBreakableCrates;

export function spawnCrateOrb(x: number, y: number, red: boolean): SimCrateOrb {
  return { x, y, homeX: x, homeY: y, red, arm: CRATE_ORB_ARM, magnetSlot: -1, active: true };
}

/** 크레이트 피해 — hurt_crate. 파괴 시 오브를 orbs 에 넣고 true 를 돌려준다. */
export function hurtCrate(
  crates: readonly SimCrate[],
  orbs: SimCrateOrb[],
  index: number,
  damage: number,
): boolean {
  if (index < 0 || index >= crates.length) {return false;}
  const crate = crates[index];
  if (!crate.alive || damage <= 0) {return false;}
  crate.hp -= damage;
  if (crate.hp > 0) {return false;}
  crate.hp = 0;
  crate.alive = false;
  orbs.push(spawnCrateOrb(crate.x, crate.y, crate.orbRed));
  return true;
}

/** 스플래시 크레이트 피해 — damage_crates_at: 반경 + CRATE_RADIUS 이내 전부. */
export function damageCratesAt(
  crates: readonly SimCrate[],
  orbs: SimCrateOrb[],
  centerX: number,
  centerY: number,
  radius: number,
  damage: number,
): void {
  for (let i = 0; i < crates.length; i += 1) {
    if (!crates[i].alive) {continue;}
    if (Math.hypot(centerX - crates[i].x, centerY - crates[i].y) <= radius + CRATE_RADIUS) {
      hurtCrate(crates, orbs, i, damage);
    }
  }
}

/** 최근접 자석 대상 — nearest_orb_target(반경 HEALTH_PICKUP_MAGNET_RADIUS). 없으면 -1. */
function nearestOrbTarget(orb: SimCrateOrb, heroes: ReadonlyMap<number, CrateHero>): number {
  let best = -1;
  let bestDist = HEALTH_PICKUP_MAGNET_RADIUS;
  for (const hero of sortedHeroes(heroes.values())) {
    if (!hero.alive || hero.eliminated) {continue;}
    const dist = Math.hypot(hero.x - orb.x, hero.y - orb.y);
    if (dist >= bestDist) {continue;}
    bestDist = dist;
    best = hero.slot;
  }
  return best;
}

/** 자석 대상 확정 — 기존 슬롯이 죽었으면 재탐색(거리 조건은 재탐색 때만, 원본과 동일). */
function orbTarget(orb: SimCrateOrb, heroes: ReadonlyMap<number, CrateHero>): CrateHero | undefined {
  const held = heroes.get(orb.magnetSlot);
  if (held && held.alive && !held.eliminated) {return held;}
  orb.magnetSlot = nearestOrbTarget(orb, heroes);
  return heroes.get(orb.magnetSlot);
}

/** 오브 습득 — 빨강은 12초 피해 버프, 파랑은 궁극기 +ULTIMATE_MAX*0.34 (상한 100). */
export function collectCrateOrb(hero: CrateHero, orb: SimCrateOrb): void {
  orb.active = false;
  if (orb.red) {
    hero.dmgOrbTime = CRATE_ORB_DMG_TIME;
    return;
  }
  hero.ultimateCharge = Math.min(ULTIMATE_MAX, hero.ultimateCharge + ULTIMATE_MAX * CRATE_ORB_ULT_RATIO);
}

/** 오브 1개 틱 — arm 소진 후 자석 끌림·습득. 유지하면 true. */
function tickOrb(orb: SimCrateOrb, heroes: ReadonlyMap<number, CrateHero>, dt: number): boolean {
  orb.arm = Math.max(0, orb.arm - dt);
  if (orb.arm > 0) {return true;}
  const target = orbTarget(orb, heroes);
  if (!target) {return true;}
  const step = HEALTH_PICKUP_MAGNET_SPEED * dt;
  const dist = Math.hypot(target.x - orb.x, target.y - orb.y);
  if (dist > step && dist > 0) {
    orb.x += ((target.x - orb.x) / dist) * step;
    orb.y += ((target.y - orb.y) / dist) * step;
  } else {
    orb.x = target.x;
    orb.y = target.y;
  }
  if (Math.hypot(target.x - orb.x, target.y - orb.y) > ORB_COLLECT_DIST) {return true;}
  collectCrateOrb(target, orb);
  return false;
}

/** 매 틱 오브 갱신 — update_crate_orbs: 습득·비활성 오브는 배열에서 제거된다. */
export function updateCrateOrbs(
  orbs: SimCrateOrb[],
  heroes: ReadonlyMap<number, CrateHero>,
  dt: number,
): void {
  for (let i = orbs.length - 1; i >= 0; i -= 1) {
    if (!orbs[i].active || !tickOrb(orbs[i], heroes, dt)) {orbs.splice(i, 1);}
  }
}

/** match_lifecycle.gd:102 — dmg_orb_time 자연 감소. */
export function tickDmgOrbTime(heroes: Iterable<CrateHero>, dt: number): void {
  for (const hero of heroes) {hero.dmgOrbTime = Math.max(0, hero.dmgOrbTime - dt);}
}

/** CPU 표적용 최근접 생존 크레이트(480 이내) 인덱스 — best_crate. 없으면 -1. */
export function bestCrate(x: number, y: number, crates: readonly SimCrate[]): number {
  let best = -1;
  let bestDist = BEST_CRATE_DIST;
  for (let i = 0; i < crates.length; i += 1) {
    if (!crates[i].alive) {continue;}
    const dist = Math.hypot(x - crates[i].x, y - crates[i].y);
    if (dist >= bestDist) {continue;}
    bestDist = dist;
    best = i;
  }
  return best;
}

/** CPU 표적용 최근접 활성 오브(420 이내, arm 소진) 인덱스 — best_crate_orb. 없으면 -1. */
export function bestCrateOrb(x: number, y: number, orbs: readonly SimCrateOrb[]): number {
  let best = -1;
  let bestDist = BEST_ORB_DIST;
  for (let i = 0; i < orbs.length; i += 1) {
    if (!orbs[i].active || orbs[i].arm > 0) {continue;}
    const dist = Math.hypot(x - orbs[i].x, y - orbs[i].y);
    if (dist >= bestDist) {continue;}
    bestDist = dist;
    best = i;
  }
  return best;
}

/** 스냅 crates 배열 — _snap_crates(network_host.gd): 죽은 크레이트 포함 전체. */
export function packCratesSnap(crates: readonly SimCrate[]): Array<Record<string, unknown>> {
  return crates.map((c) => ({ id: c.id, x: c.x, y: c.y, hp: c.hp, max_hp: c.maxHp, alive: c.alive }));
}

/** 스냅 crate_orbs 배열 — _snap_orbs: Godot parse_crate_orbs 필드 x·y·red·active. */
export function packCrateOrbsSnap(orbs: readonly SimCrateOrb[]): Array<Record<string, unknown>> {
  return orbs.map((o) => ({ x: o.x, y: o.y, red: o.red, active: o.active }));
}

export const packCrates = packCratesSnap;
export const packCrateOrbs = packCrateOrbsSnap;
export const seedCrates = spawnBreakableCrates;
export const tickCrateOrbs = updateCrateOrbs;
export const applyCrateDamage = hurtCrate;
export const crateSeedFields = crateHeroSeedFields;
export const tickCrateOrbBuffs = tickDmgOrbTime;
export const seed = spawnBreakableCrates;
export const tick = updateCrateOrbs;
export const apply = hurtCrate;
export const pack = packCratesSnap;
