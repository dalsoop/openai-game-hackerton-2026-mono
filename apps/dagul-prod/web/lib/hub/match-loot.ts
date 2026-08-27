/**
 * 회복 픽업·메드킷 — 원본 crate_pickup.gd + active_item.gd 의 full 모드 결정론 포팅.
 * 아이템 풀(roll/습득/use)은 match-item.ts (active_item.gd ITEM_POOL_MODE).
 */
import { ARENA_TILE_SCALE, HERO_RADIUS, SOURCE_ARENA_SIZE } from "./match-covers.js";
import { makeEquipment } from "./match-equipment.js";
import { applyGunLoot, type GunHero } from "./match-gun.js";
import {
  collectItemPickup, isItemPoolMode, isNoLootMode, rollPickupKind, tryUseActiveItem,
  tryUseHeldItem as tryHeldPoolItem,
  type ItemEvent, type ItemHero, type ItemPickup, type ItemWorld,
} from "./match-item.js";
import type { EffectStore } from "./match-effects.js";
import type { MatchRng } from "./match-rng.js";

export {
  SPRING_AIR, SPRING_LIFT, SPRING_EVADE, SPRING_BOOST, SLIDE_DURATION, SLIDE_ACCEL, SLIDE_FRICTION,
  PULL_DURATION, PULL_RADIUS, PULL_LAUNCH, POCKET_DURATION, POCKET_RADIUS, DECOY_DAMAGE, DECOY_KNOCK,
  ITEM_POOL_MODE, NO_LOOT_MODES, ITEM_DROP_IGNORE, steerSlide, tryUseHeldItem, tryUseActiveItem,
  rollPickupKind, collectItemPickup, updateItemPulses, heroInOwnPocket, explodeDecoy,
  spawnDroppedPickup, isItemPoolMode, isNoLootMode,
} from "./match-item.js";

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
/** 습득 판정 거리 — HERO_RADIUS(20) + HEALTH_PICKUP_RADIUS(27) = 47. */
const COLLECT_DIST = HERO_RADIUS + HEALTH_PICKUP_RADIUS;

/** 원본 2800x1700 아레나의 회복 픽업 4지점 — game_world.gd SOURCE_HEALTH_PICKUP_POINTS. */
const SOURCE_HEALTH_PICKUP_POINTS = [
  { x: 1400, y: 430 },
  { x: 1400, y: 1270 },
  { x: 760, y: 850 },
  { x: 2040, y: 850 },
] as const;

export type LootPickup = ItemPickup;

export type LootHero = {
  slot: number;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  alive: boolean;
  eliminated: boolean;
  downed?: boolean;
  medkits: number;
  useHeld: boolean;
  heldItem: string;
  pullTime: number;
  pocketTime: number;
  launchTime?: number;
  facingX?: number;
  facingY?: number;
  vx?: number;
  vy?: number;
};

export type SlideHero = ItemHero;

export type LootTickOpts = {
  rng?: MatchRng;
  tick?: number;
  events?: ItemEvent[];
  effects?: EffectStore;
};

/** SimHero 생성 시 픽업/메드킷 초기 필드 묶음. */
export function lootSeedFields(): Pick<LootHero, "medkits" | "useHeld" | "heldItem" | "pullTime" | "pocketTime"> {
  return { medkits: 0, useHeld: false, heldItem: "", pullTime: 0, pocketTime: 0 };
}

function blankPickup(id: number, x: number, y: number): LootPickup {
  return {
    id, x, y, homeX: x, homeY: y, magnetSlot: -1, active: true, respawn: 0,
    kind: "item", itemKind: "medkit", disguise: "medkit", ephemeral: false,
    ignoreSlot: -1, ignoreTime: 0,
  };
}

function appendTilePickups(pickups: LootPickup[], tileX: number, tileY: number): void {
  const originX = tileX * SOURCE_ARENA_SIZE.x * ARENA_TILE_SCALE;
  const originY = tileY * SOURCE_ARENA_SIZE.y * ARENA_TILE_SCALE;
  for (const src of SOURCE_HEALTH_PICKUP_POINTS) {
    pickups.push(blankPickup(pickups.length, originX + src.x * ARENA_TILE_SCALE, originY + src.y * ARENA_TILE_SCALE));
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

function disableLoot(pickups: LootPickup[]): void {
  for (const p of pickups) {
    p.active = false;
    p.respawn = 99999.0;
  }
}

/** game_world.gd:240-248 — item 모드는 roll_pickup_kind, NO_LOOT_MODES 는 헬스 픽업 비활성. */
export function seedHealthPickups(mode: string, rng: MatchRng): LootPickup[] {
  const pickups = buildHealthPickups();
  if (isItemPoolMode(mode)) {
    for (const p of pickups) {rollPickupKind(p, rng);}
  }
  if (isNoLootMode(mode)) {disableLoot(pickups);}
  return pickups;
}

/** 자석 대상 유효성 — pickup_target_valid: alive · not eliminated · 거리 이내. */
function targetValid(hero: LootHero | undefined, pickup: LootPickup, maxDist: number): boolean {
  if (!hero || !hero.alive || hero.eliminated) {return false;}
  if ((hero.launchTime ?? 0) > 0) {return false;}
  if (pickup.ignoreSlot === hero.slot && pickup.ignoreTime > 0) {return false;}
  return Math.hypot(hero.x - pickup.x, hero.y - pickup.y) <= maxDist;
}

/** 최근접 자석 대상 — nearest_pickup_target(반경 MAGNET_RADIUS). 없으면 -1. */
function nearestTarget(heroes: ReadonlyMap<number, LootHero>, pickup: LootPickup): number {
  let best = -1;
  let bestDist = Infinity;
  for (const hero of heroes.values()) {
    if (!targetValid(hero, pickup, HEALTH_PICKUP_MAGNET_RADIUS)) {continue;}
    const dist = Math.hypot(hero.x - pickup.x, hero.y - pickup.y);
    if (dist >= bestDist) {continue;}
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

/** 크레이트/킬 자리의 총 드랍. ephemeral 이라 습득 후 재생성하지 않는다. gunId 가 있으면 라벨 n 에 쓴다. */
export function spawnGunLootPickup(pickups: LootPickup[], x: number, y: number, gunId = ""): LootPickup {
  const pickup: LootPickup = {
    id: pickups.length, x, y, homeX: x, homeY: y, magnetSlot: -1, active: true, respawn: 0,
    kind: "gun", itemKind: gunId, disguise: "", ephemeral: true, ignoreSlot: -1, ignoreTime: 0,
  };
  pickups.push(pickup);
  return pickup;
}

function asItemHero(hero: LootHero): ItemHero {
  return hero as LootHero & ItemHero;
}

function asItemWorld(
  mode: string, heroes: ReadonlyMap<number, LootHero>, pickups: readonly LootPickup[], opts?: LootTickOpts,
): ItemWorld {
  return {
    mode, tick: opts?.tick ?? 0, dt: 1 / 60,
    heroes: heroes as unknown as ReadonlyMap<number, ItemHero>,
    pickups: pickups as ItemPickup[],
    events: opts?.events, effects: opts?.effects,
  };
}

function collectPickup(
  hero: LootHero, pickup: LootPickup, mode: string,
  heroes: ReadonlyMap<number, LootHero>, pickups: readonly LootPickup[], opts?: LootTickOpts,
): void {
  if (pickup.kind === "gun") {
    if (hasGunLootFields(hero)) {tryCollectGunLoot(hero, mode);}
    deactivatePickup(pickup);
    return;
  }
  if (isItemPoolMode(mode)) {
    collectItemPickup(asItemHero(hero), pickup, asItemWorld(mode, heroes, pickups, opts));
    return;
  }
  if (hero.medkits < MEDKIT_MAX) {hero.medkits += 1;}
  else {hero.hp = Math.min(hero.maxHp, hero.hp + hero.maxHp * HEALTH_PICKUP_HEAL_RATIO);}
  deactivatePickup(pickup);
}

/** 리스폰 — 정규 픽업은 respawn 소진 시 home 에서 재활성(4a). */
function tickInactivePickup(pickup: LootPickup, dt: number, mode: string, rng?: MatchRng): void {
  if (pickup.ephemeral) {return;}
  pickup.respawn = Math.max(0, pickup.respawn - dt);
  if (pickup.respawn > 0) {return;}
  pickup.active = true;
  pickup.x = pickup.homeX;
  pickup.y = pickup.homeY;
  pickup.magnetSlot = -1;
  pickup.ignoreSlot = -1;
  pickup.ignoreTime = 0;
  if (isItemPoolMode(mode) && rng) {rollPickupKind(pickup, rng);}
}

/** 활성 픽업 1개 틱 — 자석 재탐색 → 끌림/습득 또는 home 복귀(4c). */
function tickActivePickup(
  pickup: LootPickup,
  heroes: ReadonlyMap<number, LootHero>,
  dt: number,
  mode: string,
  pickups: readonly LootPickup[],
  opts?: LootTickOpts,
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
    collectPickup(target, pickup, mode, heroes, pickups, opts);
  }
}

/** 매 틱 픽업 상태전이 — update_health_pickups(crate_pickup.gd:164-218) full 모드분. */
export function updateHealthPickups(
  pickups: readonly LootPickup[],
  heroes: ReadonlyMap<number, LootHero>,
  dt: number,
  mode = "classic",
  opts?: LootTickOpts,
): void {
  for (const pickup of pickups) {
    pickup.ignoreTime = Math.max(0, pickup.ignoreTime - dt);
    if (pickup.active) {tickActivePickup(pickup, heroes, dt, mode, pickups, opts);}
    else {tickInactivePickup(pickup, dt, mode, opts?.rng);}
  }
}

/** 메드킷 사용 — try_use_medkit(active_item.gd:369-384). 성공 시 true. */
export function tryUseMedkit(hero: LootHero): boolean {
  if (!hero.alive || hero.eliminated || hero.downed || hero.medkits <= 0) {return false;}
  if (hero.hp >= hero.maxHp - MEDKIT_MIN_MISSING) {return false;}
  hero.medkits -= 1;
  hero.hp = Math.min(hero.maxHp, hero.hp + hero.maxHp * MEDKIT_HEAL_RATIO);
  return true;
}

/** use 입력 에지 검출 — 허브는 마지막 입력을 매 틱 재적용하므로 홀드 연속 사용을 막는다. */
export function handleUseInput(hero: LootHero, wantUse: boolean, world?: ItemWorld): void {
  if (hero.downed) {
    hero.useHeld = wantUse;
    return;
  }
  if (wantUse && !hero.useHeld) {
    if (world && isItemPoolMode(world.mode)) {tryUseActiveItem(asItemHero(hero), world);}
    else if (!tryHeldPoolItem(hero)) {tryUseMedkit(hero);}
  }
  hero.useHeld = wantUse;
}

function lootGunLabel(p: LootPickup): string {
  if (p.kind !== "gun" || p.itemKind === "") {return "";}
  return makeEquipment(p.itemKind).name;
}

/** 스냅 loot 배열 — _snap_loot(network_host.gd): active 만, Godot parse_loot 필드 id·kind·x·y·n. */
export function packLootSnap(pickups: readonly LootPickup[]): Array<Record<string, unknown>> {
  const out: Array<Record<string, unknown>> = [];
  for (const p of pickups) {
    if (!p.active) {continue;}
    const gun = p.kind === "gun";
    const row: Record<string, unknown> = {
      id: String(p.id), kind: gun ? "gun" : "item", x: p.x, y: p.y, n: lootGunLabel(p),
    };
    if (!gun && p.itemKind !== "") {row.itemKind = p.itemKind;}
    if (!gun && p.disguise !== "") {row.disguise = p.disguise;}
    out.push(row);
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
