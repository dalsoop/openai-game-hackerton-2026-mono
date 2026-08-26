/**
 * 회복 픽업·메드킷 — 원본 crate_pickup.gd + active_item.gd 의 full 모드 결정론 포팅.
 * RNG·시계 없음: full 모드 픽업은 단일 종류(메드킷 적재/즉시 회복)라 난수가 필요 없다.
 * (roll_pickup_kind 류 아이템 풀은 ITEM_POOL_MODE("item") 전용 — 이식 범위 밖.)
 */
import { ARENA_TILE_SCALE, HERO_RADIUS, SOURCE_ARENA_SIZE } from "./match-covers.js";
import { applyGunLoot, type GunHero } from "./match-gun.js";

export const HEALTH_PICKUP_RADIUS = 27;
export const HEALTH_PICKUP_RESPAWN = 16;
export const HEALTH_PICKUP_HEAL_RATIO = 0.30;
export const HEALTH_PICKUP_MAGNET_RADIUS = 217;
export const HEALTH_PICKUP_MAGNET_SPEED = 760;
export const HEALTH_PICKUP_RETURN_SPEED = 280;
/** 자석 유지 반경 배율 — pickup_target_valid(crate_pickup.gd)의 MAGNET_RADIUS * 1.65. */
export const MAGNET_KEEP_MULT = 1.65;
export const MEDKIT_MAX = 3;
export const MEDKIT_HEAL_RATIO = 0.30;
/** 사용 가능 최소 결손 — try_use_medkit(active_item.gd): hp < max_hp - 0.5. */
const MEDKIT_MIN_MISSING = 0.5;
/** active_item.gd 9-15 · game_world.gd 86-92. */
export const SPRING_AIR = 0.45;
export const SPRING_LIFT = 36.0;
export const SPRING_EVADE = 0.22;
export const SPRING_BOOST = 220.0;
export const SLIDE_DURATION = 2.2;
export const SLIDE_ACCEL = 520.0;
export const SLIDE_FRICTION = 180.0;
/** 습득 판정 거리 — HERO_RADIUS(20) + HEALTH_PICKUP_RADIUS(27) = 47. */
const COLLECT_DIST = HERO_RADIUS + HEALTH_PICKUP_RADIUS;

/** 원본 2800x1700 아레나의 회복 픽업 4지점 — game_world.gd SOURCE_HEALTH_PICKUP_POINTS. */
const SOURCE_HEALTH_PICKUP_POINTS = [
  { x: 1400, y: 430 },
  { x: 1400, y: 1270 },
  { x: 760, y: 850 },
  { x: 2040, y: 850 },
] as const;

export type LootPickup = {
  id: number;
  x: number;
  y: number;
  homeX: number;
  homeY: number;
  magnetSlot: number;
  active: boolean;
  respawn: number;
  /** item=메드킷/회복, gun=총 루팅 드랍(try_gun_loot). */
  kind: "item" | "gun";
  ephemeral: boolean;
};

export type LootHero = {
  slot: number;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  alive: boolean;
  eliminated: boolean;
  medkits: number;
  useHeld: boolean;
  heldItem: string;
};

export type SlideHero = {
  vx: number;
  vy: number;
  vel: { x: number; y: number };
  facingX: number;
  facingY: number;
  slideTime: number;
  springTime: number;
  evadeTime: number;
  hopTime: number;
  hopMax: number;
  hopHeight: number;
  heldItem: string;
};

/** SimHero 생성 시 픽업/메드킷 초기 필드 묶음. */
export function lootSeedFields(): Pick<LootHero, "medkits" | "useHeld" | "heldItem"> {
  return { medkits: 0, useHeld: false, heldItem: "" };
}

function appendTilePickups(pickups: LootPickup[], tileX: number, tileY: number): void {
  const originX = tileX * SOURCE_ARENA_SIZE.x * ARENA_TILE_SCALE;
  const originY = tileY * SOURCE_ARENA_SIZE.y * ARENA_TILE_SCALE;
  for (const src of SOURCE_HEALTH_PICKUP_POINTS) {
    const x = originX + src.x * ARENA_TILE_SCALE;
    const y = originY + src.y * ARENA_TILE_SCALE;
    pickups.push({
      id: pickups.length, x, y, homeX: x, homeY: y, magnetSlot: -1, active: true, respawn: 0,
      kind: "item", ephemeral: false,
    });
  }
}

/** 2x2 타일 x 소스 4지점 = 16개 픽업 — 커버와 같은 tiled_points 전개(결정론). */
export function buildHealthPickups(): LootPickup[] {
  const pickups: LootPickup[] = [];
  for (const tileX of [0, 1]) {
    for (const tileY of [0, 1]) {
      appendTilePickups(pickups, tileX, tileY);
    }
  }
  return pickups;
}

/** 자석 대상 유효성 — pickup_target_valid: alive · not eliminated · 거리 이내. */
function targetValid(hero: LootHero | undefined, pickup: LootPickup, maxDist: number): boolean {
  if (!hero || !hero.alive || hero.eliminated) {return false;}
  return Math.hypot(hero.x - pickup.x, hero.y - pickup.y) <= maxDist;
}

/** 최근접 자석 대상 — nearest_pickup_target(반경 MAGNET_RADIUS). 없으면 -1. */
function nearestTarget(heroes: ReadonlyMap<number, LootHero>, pickup: LootPickup): number {
  let best = -1;
  let bestDist = Infinity;
  for (const hero of heroes.values()) {
    if (!hero.alive || hero.eliminated) {continue;}
    const dist = Math.hypot(hero.x - pickup.x, hero.y - pickup.y);
    if (dist > HEALTH_PICKUP_MAGNET_RADIUS || dist >= bestDist) {continue;}
    best = hero.slot;
    bestDist = dist;
  }
  return best;
}

function movePickupToward(pickup: LootPickup, tx: number, ty: number, delta: number): void {
  const dx = tx - pickup.x;
  const dy = ty - pickup.y;
  const dist = Math.hypot(dx, dy);
  if (dist <= delta || dist === 0) {
    pickup.x = tx;
    pickup.y = ty;
    return;
  }
  pickup.x += (dx / dist) * delta;
  pickup.y += (dy / dist) * delta;
}

/**
 * 습득 — crate_pickup.gd:196-215 full 모드 분기.
 * 메드킷 슬롯이 비면 적재(carried+1), 가득이면 즉시 회복(max_hp*0.30, 결손과 min).
 */
function deactivatePickup(pickup: LootPickup): void {
  pickup.active = false;
  pickup.respawn = pickup.ephemeral ? Number.POSITIVE_INFINITY : HEALTH_PICKUP_RESPAWN;
  pickup.magnetSlot = -1;
  pickup.x = pickup.homeX;
  pickup.y = pickup.homeY;
}

function hasGunLootFields(hero: LootHero): hero is LootHero & GunHero {
  return "equipment" in hero;
}

/** active_item.gd try_gun_loot — 모드가 GUN_LOOT_MODES 일 때 체인 다음 총으로 교체. */
export function tryCollectGunLoot(hero: GunHero, mode: string): boolean {
  return applyGunLoot(hero, mode);
}

/** 크레이트/킬 자리의 총 드랍. ephemeral 이라 습득 후 재생성하지 않는다. */
export function spawnGunLootPickup(pickups: LootPickup[], x: number, y: number): LootPickup {
  const pickup: LootPickup = {
    id: pickups.length, x, y, homeX: x, homeY: y, magnetSlot: -1, active: true, respawn: 0,
    kind: "gun", ephemeral: true,
  };
  pickups.push(pickup);
  return pickup;
}

function collectPickup(hero: LootHero, pickup: LootPickup, mode: string): void {
  if (pickup.kind === "gun") {
    if (hasGunLootFields(hero)) {tryCollectGunLoot(hero, mode);}
    deactivatePickup(pickup);
    return;
  }
  if (hero.medkits < MEDKIT_MAX) {hero.medkits += 1;}
  else {hero.hp = Math.min(hero.maxHp, hero.hp + hero.maxHp * HEALTH_PICKUP_HEAL_RATIO);}
  deactivatePickup(pickup);
}

/** 리스폰 — 정규 픽업은 respawn 소진 시 home 에서 재활성(4a). */
function tickInactivePickup(pickup: LootPickup, dt: number): void {
  if (pickup.ephemeral) {return;}
  pickup.respawn = Math.max(0, pickup.respawn - dt);
  if (pickup.respawn > 0) {return;}
  pickup.active = true;
  pickup.x = pickup.homeX;
  pickup.y = pickup.homeY;
  pickup.magnetSlot = -1;
}

/** 활성 픽업 1개 틱 — 자석 재탐색 → 끌림/습득 또는 home 복귀(4c). */
function tickActivePickup(
  pickup: LootPickup,
  heroes: ReadonlyMap<number, LootHero>,
  dt: number,
  mode: string,
): void {
  const keepDist = HEALTH_PICKUP_MAGNET_RADIUS * MAGNET_KEEP_MULT;
  if (!targetValid(heroes.get(pickup.magnetSlot), pickup, keepDist)) {
    pickup.magnetSlot = nearestTarget(heroes, pickup);
  }
  const target = heroes.get(pickup.magnetSlot);
  if (!target) {
    movePickupToward(pickup, pickup.homeX, pickup.homeY, HEALTH_PICKUP_RETURN_SPEED * dt);
    return;
  }
  movePickupToward(pickup, target.x, target.y, HEALTH_PICKUP_MAGNET_SPEED * dt);
  if (Math.hypot(target.x - pickup.x, target.y - pickup.y) <= COLLECT_DIST) {
    collectPickup(target, pickup, mode);
  }
}

/** 매 틱 픽업 상태전이 — update_health_pickups(crate_pickup.gd:164-218) full 모드분. */
export function updateHealthPickups(
  pickups: readonly LootPickup[],
  heroes: ReadonlyMap<number, LootHero>,
  dt: number,
  mode = "classic",
): void {
  for (const pickup of pickups) {
    if (pickup.active) {tickActivePickup(pickup, heroes, dt, mode);}
    else {tickInactivePickup(pickup, dt);}
  }
}

/** 메드킷 사용 — try_use_medkit(active_item.gd:369-384). 성공 시 true. */
export function tryUseMedkit(hero: LootHero): boolean {
  if (!hero.alive || hero.eliminated || hero.medkits <= 0) {return false;}
  if (hero.hp >= hero.maxHp - MEDKIT_MIN_MISSING) {return false;}
  hero.medkits -= 1;
  hero.hp = Math.min(hero.maxHp, hero.hp + hero.maxHp * MEDKIT_HEAL_RATIO);
  return true;
}

function moveToward(vx: number, vy: number, tx: number, ty: number, delta: number): { x: number; y: number } {
  const dx = tx - vx;
  const dy = ty - vy;
  const len = Math.hypot(dx, dy);
  if (len <= delta || len === 0) {return { x: tx, y: ty };}
  return { x: vx + (dx / len) * delta, y: vy + (dy / len) * delta };
}

/** active_item.gd steer_slide:247-259. */
export function steerSlide(h: SlideHero, wishX: number, wishY: number, maxSpeed: number, dt: number): void {
  let vx = h.vx;
  let vy = h.vy;
  const wishLen = Math.hypot(wishX, wishY);
  if (wishLen * wishLen > 0.04) {
    vx += (wishX / wishLen) * SLIDE_ACCEL * dt;
    vy += (wishY / wishLen) * SLIDE_ACCEL * dt;
    const spd = Math.hypot(vx, vy);
    const cap = Math.max(40.0, maxSpeed * 1.15);
    if (spd > cap) {
      vx = (vx / spd) * cap;
      vy = (vy / spd) * cap;
    }
  } else {
    const next = moveToward(vx, vy, 0, 0, SLIDE_FRICTION * dt);
    vx = next.x;
    vy = next.y;
  }
  h.vx = vx;
  h.vy = vy;
  h.vel = { x: vx, y: vy };
}

function facingOrVel(h: SlideHero): { x: number; y: number } {
  const spd = Math.hypot(h.vx, h.vy);
  if (spd * spd > 0.1) {return { x: h.vx / spd, y: h.vy / spd };}
  const flen = Math.hypot(h.facingX, h.facingY);
  if (flen * flen > 0.1) {return { x: h.facingX / flen, y: h.facingY / flen };}
  return { x: 0, y: 0 };
}

function applySpringUse(h: SlideHero): void {
  h.heldItem = "";
  h.hopTime = SPRING_AIR;
  h.hopMax = SPRING_AIR;
  h.hopHeight = SPRING_LIFT;
  h.evadeTime = Math.max(h.evadeTime, SPRING_EVADE);
  h.springTime = SPRING_AIR;
  const dir = facingOrVel(h);
  if (dir.x * dir.x + dir.y * dir.y > 0.1) {
    h.vx += dir.x * SPRING_BOOST;
    h.vy += dir.y * SPRING_BOOST;
    h.vel = { x: h.vx, y: h.vy };
  }
}

function applySlideUse(h: SlideHero): void {
  h.heldItem = "";
  h.slideTime = SLIDE_DURATION;
}

function isSlideHero(hero: LootHero): hero is LootHero & SlideHero {
  return typeof (hero as LootHero & Partial<SlideHero>).slideTime === "number"
    && typeof (hero as LootHero & Partial<SlideHero>).vx === "number";
}

/** active_item.gd try_use_active_item spring/slide. 픽업 풀에 spring/slide 가 없으면 호출측이 heldItem 을 넣는다. */
export function tryUseHeldItem(hero: LootHero): boolean {
  if (!hero.alive || hero.eliminated) {return false;}
  if (!isSlideHero(hero)) {return false;}
  if (hero.heldItem === "spring") {applySpringUse(hero); return true;}
  if (hero.heldItem === "slide") {applySlideUse(hero); return true;}
  return false;
}

/** use 입력 에지 검출 — 허브는 마지막 입력을 매 틱 재적용하므로 홀드 연속 사용을 막는다. */
export function handleUseInput(hero: LootHero, wantUse: boolean): void {
  if (wantUse && !hero.useHeld) {
    if (!tryUseHeldItem(hero)) {tryUseMedkit(hero);}
  }
  hero.useHeld = wantUse;
}

/** 스냅 loot 배열 — _snap_loot(network_host.gd): active 만, Godot parse_loot 필드 id·kind·x·y·n. */
export function packLootSnap(pickups: readonly LootPickup[]): Array<Record<string, unknown>> {
  const out: Array<Record<string, unknown>> = [];
  for (const p of pickups) {
    if (!p.active) {continue;}
    out.push({ id: String(p.id), kind: p.kind === "gun" ? "gun" : "item", x: p.x, y: p.y, n: "" });
  }
  return out;
}

/** P_ITEM 스냅 필드 — snap_contract.gd:110 ("medkit" if medkits > 0 else ""). */
export function packItemField(medkits: number): string {
  return medkits > 0 ? "medkit" : "";
}
export const seed = buildHealthPickups;
export const tick = updateHealthPickups;
export const apply = handleUseInput;
