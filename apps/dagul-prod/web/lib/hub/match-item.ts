/**
 * 필드 아이템 풀 — active_item.gd (roll_pickup_kind · collect_item_pickup · try_use_active_item).
 * 수치 창작 금지. ITEM_POOL_MODE("item") + spring/slide(W6).
 */
import { ARENA_MARGIN, ARENA_SIZE } from "./match-covers.js";
import { addEffect, type EffectStore } from "./match-effects.js";
import { enterDown, type LifeHero } from "./match-life.js";
import { LAUNCH_SPEED_BASE, LAUNCH_SPEED_KB_MUL } from "./match-launch.js";
import type { MatchRng } from "./match-rng.js";

export const ITEM_POOL_MODE = "item";
/** game_world.gd:84 */
export const NO_LOOT_MODES: readonly string[] = ["gun-semi", "gun-auto"];
/** active_item.gd:9-24 */
export const SPRING_AIR = 0.45;
export const SPRING_LIFT = 36.0;
export const SPRING_EVADE = 0.22;
export const SPRING_BOOST = 220.0;
export const SLIDE_DURATION = 2.2;
export const SLIDE_ACCEL = 520.0;
export const SLIDE_FRICTION = 180.0;
export const PULL_DURATION = 0.55;
export const PULL_RADIUS = 300.0;
export const PULL_LAUNCH = 380.0;
export const PULL_PICKUP_SPEED = 520.0;
export const PULL_LAUNCH_TIME = 0.20;
export const DECOY_DAMAGE = 18.0;
export const DECOY_KNOCK = 90.0;
export const DECOY_LAUNCH_TIME = 0.28;
export const POCKET_DURATION = 5.0;
export const POCKET_RADIUS = 150.0;
export const ITEM_DROP_IGNORE = 0.45;
export const ITEM_DROP_BACK = 36.0;
export const WEIGHT_FLOOR = 0.35;
export const MEDKIT_HEAL_RATIO = 0.30;
export const MEDKIT_MIN_MISSING = 0.5;
const PICKUP_R = 27;
const PICKUP_RESPAWN = 16;
const DECOY_FACES = ["medkit", "spring", "slide", "pull", "pocket"] as const;
const KIND_COLOR: Record<string, string> = {
  spring: "#ffe066", slide: "#70e7ff", pull: "#b78cff", pocket: "#f4e2ff",
};

export type PoolItemKind = "medkit" | "spring" | "slide" | "pull" | "pocket" | "decoy";
export {
  packItemField, packItemStack, unpackItemStack, unpackMedkits, ITEM_WIRE_CASES,
  type ItemStack,
} from "./match-item-wire.js";
export type ItemEvent = { tick: number; type: string; actor: number; target: number; data: Record<string, unknown> };
export type ItemPickup = {
  id: number; x: number; y: number; homeX: number; homeY: number; magnetSlot: number;
  active: boolean; respawn: number; kind: "item" | "gun"; itemKind: string; disguise: string;
  ephemeral: boolean; ignoreSlot: number; ignoreTime: number;
};
export type ItemHero = {
  slot: number; x: number; y: number; vx: number; vy: number; vel: { x: number; y: number };
  facingX: number; facingY: number; hp: number; maxHp: number; alive: boolean; eliminated: boolean;
  downed?: boolean; heldItem: string; slideTime: number; springTime: number; pullTime: number;
  pocketTime: number; evadeTime: number; hopTime: number; hopMax: number; hopHeight: number;
  launchTime: number; launchVel: { x: number; y: number }; launchOwner?: number;
  spawnProtect?: number; weight?: number; turtle?: boolean;
};
export type ItemWorld = {
  mode: string; tick: number; dt: number; heroes: ReadonlyMap<number, ItemHero>;
  pickups: ItemPickup[]; events?: ItemEvent[]; effects?: EffectStore;
};
export type SlideBody = { vx: number; vy: number; vel: { x: number; y: number } };

export function isItemPoolMode(mode: string): boolean { return mode === ITEM_POOL_MODE; }
export function isNoLootMode(mode: string): boolean {
  return (NO_LOOT_MODES as readonly string[]).includes(mode);
}

/** active_item.gd:140-160 */
export function rollPickupKind(pickup: ItemPickup, rng: MatchRng): void {
  const roll = rng.rangef(0.0, 1.0);
  let kind: PoolItemKind = "decoy";
  if (roll < 0.30) {kind = "medkit";}
  else if (roll < 0.48) {kind = "spring";}
  else if (roll < 0.66) {kind = "slide";}
  else if (roll < 0.80) {kind = "pull";}
  else if (roll < 0.90) {kind = "pocket";}
  pickup.itemKind = kind;
  pickup.disguise = kind === "decoy"
    ? (DECOY_FACES[rng.rangei(0, DECOY_FACES.length - 1)] ?? "medkit")
    : kind;
}

function emit(w: ItemWorld | undefined, type: string, actor: number, target: number, data: Record<string, unknown>): void {
  w?.events?.push({ tick: w.tick, type, actor, target, data });
}
function fx(w: ItemWorld | undefined, kind: string, x: number, y: number, radius: number, duration: number, color: string, label: string, dx = 1, dy = 0): void {
  addEffect(w?.effects, { kind, x, y, radius, duration, color, label, dx, dy });
}
function clampPickup(x: number, y: number): { x: number; y: number } {
  return {
    x: Math.min(ARENA_SIZE.x - ARENA_MARGIN - PICKUP_R, Math.max(ARENA_MARGIN + PICKUP_R, x)),
    y: Math.min(ARENA_SIZE.y - ARENA_MARGIN - PICKUP_R, Math.max(ARENA_MARGIN + PICKUP_R, y)),
  };
}
function deactivateItem(p: ItemPickup): void {
  p.active = false;
  p.respawn = p.ephemeral ? 99999.0 : PICKUP_RESPAWN;
  p.magnetSlot = -1;
  p.x = p.homeX;
  p.y = p.homeY;
}

/** active_item.gd:162-192 */
export function spawnDroppedPickup(pickups: ItemPickup[], x: number, y: number, kind: string, ignoreSlot = -1): void {
  if (kind === "" || kind === "decoy") {return;}
  const pos = clampPickup(x, y);
  const ignoreTime = ignoreSlot >= 0 ? ITEM_DROP_IGNORE : 0;
  const old = pickups.find((row) => row.ephemeral && !row.active);
  const slot = old ?? {
    id: pickups.length, kind: "item" as const, ephemeral: true,
    x: 0, y: 0, homeX: 0, homeY: 0, magnetSlot: -1, active: false, respawn: 0,
    itemKind: "", disguise: "", ignoreSlot: -1, ignoreTime: 0,
  };
  if (!old) {pickups.push(slot);}
  slot.x = pos.x; slot.y = pos.y; slot.homeX = pos.x; slot.homeY = pos.y;
  slot.itemKind = kind; slot.disguise = kind; slot.kind = "item";
  slot.active = true; slot.respawn = 0; slot.magnetSlot = -1;
  slot.ignoreSlot = ignoreSlot; slot.ignoreTime = ignoreTime;
}

function facingOrVel(h: ItemHero): { x: number; y: number } {
  const spd = Math.hypot(h.vx, h.vy);
  if (spd * spd > 0.1) {return { x: h.vx / spd, y: h.vy / spd };}
  const flen = Math.hypot(h.facingX, h.facingY);
  if (flen * flen > 0.1) {return { x: h.facingX / flen, y: h.facingY / flen };}
  return { x: 0, y: 0 };
}
function applySpringUse(h: ItemHero): void {
  h.heldItem = "";
  h.hopTime = SPRING_AIR; h.hopMax = SPRING_AIR; h.hopHeight = SPRING_LIFT;
  h.evadeTime = Math.max(h.evadeTime, SPRING_EVADE); h.springTime = SPRING_AIR;
  const dir = facingOrVel(h);
  if (dir.x * dir.x + dir.y * dir.y <= 0.1) {return;}
  h.vx += dir.x * SPRING_BOOST; h.vy += dir.y * SPRING_BOOST;
  h.vel = { x: h.vx, y: h.vy };
}
function applySlideUse(h: ItemHero): void { h.heldItem = ""; h.slideTime = SLIDE_DURATION; }
function isSlideHero(hero: object): hero is ItemHero {
  const h = hero as Partial<ItemHero>;
  return typeof h.slideTime === "number" && typeof h.vx === "number";
}

/** active_item.gd spring/slide. 픽업 풀 없이도 heldItem 만으로 발동(W6). */
export function tryUseHeldItem(hero: object): boolean {
  if (!isSlideHero(hero) || !hero.alive || hero.eliminated) {return false;}
  if (hero.heldItem === "spring") {applySpringUse(hero); return true;}
  if (hero.heldItem === "slide") {applySlideUse(hero); return true;}
  return false;
}

function moveToward(x: number, y: number, tx: number, ty: number, delta: number): { x: number; y: number } {
  const dx = tx - x; const dy = ty - y; const len = Math.hypot(dx, dy);
  if (len <= delta || len === 0) {return { x: tx, y: ty };}
  return { x: x + (dx / len) * delta, y: y + (dy / len) * delta };
}

/** active_item.gd:247-259 */
export function steerSlide(h: SlideBody, wishX: number, wishY: number, maxSpeed: number, dt: number): void {
  let vx = h.vx; let vy = h.vy;
  const wishLen = Math.hypot(wishX, wishY);
  if (wishLen * wishLen > 0.04) {
    vx += (wishX / wishLen) * SLIDE_ACCEL * dt;
    vy += (wishY / wishLen) * SLIDE_ACCEL * dt;
    const spd = Math.hypot(vx, vy); const cap = Math.max(40.0, maxSpeed * 1.15);
    if (spd > cap) {vx = (vx / spd) * cap; vy = (vy / spd) * cap;}
  } else {
    const next = moveToward(vx, vy, 0, 0, SLIDE_FRICTION * dt);
    vx = next.x; vy = next.y;
  }
  h.vx = vx; h.vy = vy; h.vel = { x: vx, y: vy };
}

/** active_item.gd:261-269 */
export function pullTargetToward(target: ItemHero, userX: number, userY: number): void {
  const dx = userX - target.x; const dy = userY - target.y; const len = Math.hypot(dx, dy);
  if (len * len < 0.01) {return;}
  target.launchVel = { x: (dx / len) * PULL_LAUNCH, y: (dy / len) * PULL_LAUNCH };
  target.launchTime = Math.max(target.launchTime, PULL_LAUNCH_TIME);
  target.vx = 0; target.vy = 0; target.vel = { x: 0, y: 0 };
}

/** active_item.gd:271-290 */
export function applyPullPulse(user: ItemHero, world: ItemWorld, dt: number): void {
  for (const target of world.heroes.values()) {
    if (target.slot === user.slot || !target.alive || target.eliminated) {continue;}
    if (Math.hypot(target.x - user.x, target.y - user.y) > PULL_RADIUS) {continue;}
    pullTargetToward(target, user.x, user.y);
  }
  for (const pickup of world.pickups) {
    if (!pickup.active || Math.hypot(pickup.x - user.x, pickup.y - user.y) > PULL_RADIUS) {continue;}
    const next = moveToward(pickup.x, pickup.y, user.x, user.y, PULL_PICKUP_SPEED * dt);
    pickup.x = next.x; pickup.y = next.y;
  }
}

/** active_item.gd:292-299 */
export function updateItemPulses(world: ItemWorld, dt: number): void {
  if (world.mode !== ITEM_POOL_MODE) {return;}
  for (const h of world.heroes.values()) {
    if (!h.alive || h.eliminated || h.pullTime <= 0) {continue;}
    applyPullPulse(h, world, dt);
  }
}

/** active_item.gd:301-307 — 원본 거리검사는 자기 위치라 pocket_time>0 이면 참. */
export function heroInOwnPocket(hero: Pick<ItemHero, "pocketTime">): boolean {
  return hero.pocketTime > 0;
}

function decoyPush(h: ItemHero, ox: number, oy: number): { x: number; y: number } {
  const dx = h.x - ox; const dy = h.y - oy; const len = Math.hypot(dx, dy);
  if (len * len >= 0.1) {return { x: dx / len, y: dy / len };}
  const flen = Math.hypot(h.facingX, h.facingY) || 1;
  return { x: h.facingX / flen, y: h.facingY / flen };
}

/** active_item.gd:194-220 */
export function explodeDecoy(hero: ItemHero, originX: number, originY: number, world?: ItemWorld): void {
  if (!hero.alive || (hero.spawnProtect ?? 0) > 0) {return;}
  if (hero.evadeTime > 0) {
    hero.evadeTime = 0;
    fx(world, "afterimage", hero.x, hero.y, 105, 0.38, "#b9f3ff", "EVADE");
    emit(world, "attack_evaded", -1, hero.slot, { source: "decoy" });
    return;
  }
  hero.hp -= DECOY_DAMAGE;
  const push = decoyPush(hero, originX, originY);
  const speed = (LAUNCH_SPEED_BASE + DECOY_KNOCK * LAUNCH_SPEED_KB_MUL) / Math.max(WEIGHT_FLOOR, hero.weight ?? 1);
  hero.launchVel = { x: push.x * speed, y: push.y * speed };
  hero.launchTime = DECOY_LAUNCH_TIME;
  hero.vx = 0; hero.vy = 0; hero.vel = { x: 0, y: 0 }; hero.launchOwner = -1;
  fx(world, "explosion", originX, originY, 78, 0.40, "#ff665a", "DECOY");
  emit(world, "decoy_exploded", -1, hero.slot, { damage: DECOY_DAMAGE });
  if (hero.hp > 0 || hero.downed) {return;}
  enterDown(hero as unknown as LifeHero);
}

/** active_item.gd:222-245 */
export function collectItemPickup(hero: ItemHero, pickup: ItemPickup, world: ItemWorld): void {
  const kind = pickup.itemKind || "medkit";
  if (kind === "decoy") {explodeDecoy(hero, pickup.x, pickup.y, world); deactivateItem(pickup); return;}
  const oldItem = hero.heldItem;
  if (oldItem !== "") {
    spawnDroppedPickup(world.pickups, hero.x - hero.facingX * ITEM_DROP_BACK, hero.y - hero.facingY * ITEM_DROP_BACK, oldItem, hero.slot);
  }
  hero.heldItem = kind;
  deactivateItem(pickup);
  fx(world, "heal_pickup", hero.x, hero.y, 64, 0.38, KIND_COLOR[kind] ?? "#6ef3a5", kind.toUpperCase());
  emit(world, "item_collected", hero.slot, -1, { kind, dropped: oldItem });
}

function consumeHeld(h: ItemHero, world: ItemWorld, kind: "pull" | "pocket"): void {
  h.heldItem = "";
  if (kind === "pull") {
    h.pullTime = PULL_DURATION;
    applyPullPulse(h, world, world.dt);
    fx(world, "chain_vortex", h.x, h.y, PULL_RADIUS, 0.55, "#b78cff", "PULL");
  } else {
    h.pocketTime = POCKET_DURATION;
    fx(world, "guard", h.x, h.y, POCKET_RADIUS, 0.45, "#f4e2ff", "POCKET");
  }
  emit(world, "item_used", h.slot, -1, { kind });
}

/** active_item.gd:309-367 */
export function tryUseActiveItem(hero: ItemHero, world: ItemWorld): boolean {
  if (world.mode !== ITEM_POOL_MODE || !hero.alive || hero.eliminated || hero.turtle) {return false;}
  const kind = hero.heldItem;
  if (kind === "") {return false;}
  if (kind === "medkit") {
    if (hero.hp >= hero.maxHp - MEDKIT_MIN_MISSING) {return false;}
    hero.heldItem = "";
    const amount = hero.maxHp * MEDKIT_HEAL_RATIO;
    hero.hp = Math.min(hero.maxHp, hero.hp + amount);
    fx(world, "heal_pickup", hero.x, hero.y, 72, 0.45, "#6ef3a5", "MEDKIT");
    emit(world, "medkit_used", hero.slot, -1, { amount, left: 0 });
    return true;
  }
  if (kind === "spring") {
    const dir = facingOrVel(hero);
    applySpringUse(hero);
    fx(world, "speed_streak", hero.x, hero.y, 90, 0.34, "#ffe066", "SPRING", dir.x, dir.y);
    emit(world, "item_used", hero.slot, -1, { kind: "spring" });
    return true;
  }
  if (kind === "slide") {
    applySlideUse(hero);
    fx(world, "speed_streak", hero.x, hero.y, 70, 0.28, "#70e7ff", "SLIDE");
    emit(world, "item_used", hero.slot, -1, { kind: "slide" });
    return true;
  }
  if (kind === "pull" || kind === "pocket") {consumeHeld(hero, world, kind); return true;}
  return false;
}
