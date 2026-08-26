/* eslint-disable max-lines -- 일반공격·재장전·모빌리티 포팅이 한 파일 */
/**
 * 일반공격·재장전·모빌리티·루트 — damage_system.gd try_normal_attack
 * + active_item.gd try_mobility / try_equipment_attack / try_gun_loot.
 */
import { clampArena, resolveCoverMotion, type CoverRect } from "./match-covers.js";
import {
  GUN_LOOT_MODES, equipmentReach, fxForEquipment, makeEquipment, muzzleWorldPos,
  nextGunLootId, sprayKick, sprayRecoverRate,
  type Equipment, type FireMode, type Vec2,
} from "./match-equipment.js";
import {
  applySkillInput, cancelSkillCharge, tickSkillChargeGuard,
  type SkillAttackResult, type SkillMineSpec, type SkillWallSpec, type SkillZoneSpec,
} from "./match-skill.js";

export { applyEquipmentAttack } from "./match-skill.js";

export { familyOf, feelForEquipment, fxForEquipment, gunMountPos, gunWorldScale, muzzleWorldPos, sprayKick, sprayRecoverRate, sprayStep, visualForEquipment } from "./match-equipment.js";

export const RADIUS_FIRE_MUL = 3.0;
export const RELOAD_MIN = 0.20;
export const MUZZLE_FRAME = 0.055;
export const ATTACK_LOCK_CAP = 0.12;
export const ATTACK_LOCK_RATIO = 0.45;
export const RATE_FLOOR = 0.35;
export const SPRAY_IDLE_GATE = 0.14;
export const BRAWLER_HEAVY_EVERY = 3;
export const BRAWLER_HEAVY_DMG = 2.0;
export const BRAWLER_HEAVY_RADIUS = 2.5;
export const BRAWLER_KICK_MUL = 2.7;
export const BRAWLER_KICK_Y = -7.0;
export const MORTAR_SPLASH = 120.0;
export const MORTAR_RADIUS_MIN = 12.0;
export const PASSIVE_MUL = 1.12;
export const BRAWLER_HP_RATIO = 0.5;
export const RAIL_PASSIVE_DIST = 430.0;
export const SPEAR_PASSIVE_DIST = 280.0;
export const MOBILITY_EVADE = 0.20;
export const CANCEL_FIRE_CD = 0.04;
export const LEECH_HEAL = 8.0;
export const BLAST_HOP_RADIUS = 120.0;
export const BLAST_HOP_DAMAGE = 2.0;
export const BLAST_HOP_CC = 0.12;
export const BLAST_HOP_KB = 72.0;
export const BREAKER_GUARD = 0.80;
export const BLADE_EVADE = 0.48;
export const WEAVE_IMMUNITY = 0.95;
export const BRACE_GUARD = 1.20;
export const COMBO_MOBILITY_IMMUNITY = 0.72;
export const COMBO_BREAK_IMMUNITY = 0.52;
export const HOP_LIFT_DEFAULT = 19.0;
export const HOP_AIR = 0.30;
export const BURST_LEFT_DEFAULT = 2;
export const RELOAD_FLASH_DONE = 0.55;

const NAMED_MOBILITY = new Set([
  "scatter", "rail", "mortar", "leech", "breaker", "burst", "blade", "brawler", "bomb", "spear", "chain",
]);

export type EquipmentSkillTable = { skillName: string; skillDesc: string; cooldown: number; implemented: boolean };
export type GunHero = {
  slot: number; x: number; y: number; hp: number; maxHp: number; alive: boolean; turtle: boolean;
  stunTime: number; launchTime: number; rootTime: number; facingX: number; facingY: number;
  aimX: number; aimY: number; equipment: Equipment; mag: number; reloadLeft: number; fireCd: number;
  burstLeft: number; brawlerShot: number; sprayIndex: number; sprayIdle: number; heavyShot: boolean;
  equipmentCd: number; mobilityCd: number; muzzleTime: number; muzzleRow: number; muzzleScale: number;
  attackLockTime: number; reloadFlash: number; hopTime: number; hopMax: number; hopHeight: number;
  evadeTime: number; guardTime: number; comboImmunity: number; comboHits: number; comboTime: number;
  comboDamage: number; comboOwner: number; comboCaptureTime: number; hitstunTime: number;
  chargingSkill: boolean; chargeTime: number; chargeDirX: number; chargeDirY: number;
  superArmorTime: number; superArmorStrength: number; equipmentHeld: boolean;
  rouletteRate: number; rouletteRange: number;
};
export type GunProjectile = {
  owner: number; x: number; y: number; vx: number; vy: number; damage: number; radius: number;
  ttl: number; splash: number; pierce: number; knockback: number; kind: string;
  source: "normal" | "equipment";
  heavy: boolean; leech: boolean; ccTime: number; homing?: number;
};
export type MobilityHit = {
  targetSlot: number; damage: number; source: "mobility"; ccTime: number; knockback: number;
  originX: number; originY: number; label: string; effectKind: string;
};
export type GunFireResult = { fired: boolean; startedReload: boolean; projectiles: GunProjectile[]; mouseKick: Vec2 };
export type GunInput = {
  primary: boolean; primaryPressed: boolean; reload: boolean; mobility: boolean;
  moveX: number; moveY: number; equipment?: boolean; equipmentPressed?: boolean;
  equipmentReleased?: boolean; dt?: number;
};
export type GunApplyResult = {
  kind: "idle" | "fire" | "mobility" | "reload" | "skill";
  projectiles: GunProjectile[];
  hits: MobilityHit[];
  used: boolean;
  zones: SkillZoneSpec[];
  mine: SkillMineSpec | null;
  wall: SkillWallSpec | null;
};

const ZERO: Vec2 = { x: 0, y: 0 };
const IDLE_FIRE: GunFireResult = { fired: false, startedReload: false, projectiles: [], mouseKick: ZERO };
const IDLE_APPLY: GunApplyResult = {
  kind: "idle", projectiles: [], hits: [], used: false, zones: [], mine: null, wall: null,
};

export function hopLift(h: Pick<GunHero, "hopTime" | "hopMax" | "hopHeight">): number {
  if (h.hopTime <= 0) {return 0;}
  const hopMax = Math.max(0.001, h.hopMax);
  return h.hopHeight * Math.sin(Math.PI * Math.min(1, Math.max(0, 1.0 - h.hopTime / hopMax)));
}
export function attackDirection(x: number, y: number): Vec2 {
  const len = Math.hypot(x, y);
  if (len === 0) {return { x: 1, y: 0 };}
  return { x: x / len, y: y / len };
}
export function rotateVec(x: number, y: number, angle: number): Vec2 {
  const c = Math.cos(angle);
  const s = Math.sin(angle);
  return { x: x * c - y * s, y: x * s + y * c };
}
export function pelletOffset(index: number, count: number, spread: number): number {
  if (count <= 1) {return 0;}
  return (index - (count - 1) * 0.5) * spread;
}
export function projectileKind(equipmentId: string, kind: string): string {
  if (equipmentId === "rail") {return "tracer";}
  if (kind === "pellet" || kind === "bolt" || kind === "shell") {return kind;}
  return "bolt";
}
export function wantsFire(mode: FireMode, primary: boolean, primaryPressed: boolean): boolean {
  if (mode === "auto") {return primary;}
  return primaryPressed;
}
export function weaponPassiveDamageMul(id: string, hp: number, maxHp: number, dist: number): number {
  if (id === "brawler" && hp <= maxHp * BRAWLER_HP_RATIO) {return PASSIVE_MUL;}
  if (id === "rail" && dist >= RAIL_PASSIVE_DIST) {return PASSIVE_MUL;}
  if (id === "spear" && dist >= SPEAR_PASSIVE_DIST) {return PASSIVE_MUL;}
  return 1;
}
export function equipmentSkillTable(id: string): EquipmentSkillTable {
  const eq = makeEquipment(id);
  return { skillName: eq.skillName, skillDesc: eq.skillDesc, cooldown: eq.cooldown, implemented: true };
}
export function gunSeedFields(equipment: Equipment): Omit<GunHero, "slot" | "x" | "y" | "hp" | "maxHp" | "alive" | "stunTime" | "launchTime" | "rootTime" | "facingX" | "facingY" | "aimX" | "aimY"> {
  return {
    equipment, mag: equipment.magSize, reloadLeft: 0, fireCd: 0, burstLeft: BURST_LEFT_DEFAULT, brawlerShot: 0,
    sprayIndex: 0, sprayIdle: 0, heavyShot: false, equipmentCd: 0, mobilityCd: 0, muzzleTime: 0, muzzleRow: 0,
    muzzleScale: 1, attackLockTime: 0, reloadFlash: 0, hopTime: 0, hopMax: HOP_AIR, hopHeight: HOP_LIFT_DEFAULT,
    evadeTime: 0, guardTime: 0, comboImmunity: 0, comboHits: 0, comboTime: 0, comboDamage: 0, comboOwner: -1,
    comboCaptureTime: 0, hitstunTime: 0, chargingSkill: false, chargeTime: 0,
    chargeDirX: 1, chargeDirY: 0, superArmorTime: 0, superArmorStrength: 0, equipmentHeld: false,
    turtle: false, rouletteRate: 0, rouletteRange: 0,
  };
}

function tickReload(h: GunHero, dt: number): void {
  if (!h.alive || h.stunTime > 0 || h.launchTime > 0) {h.reloadLeft = 0; return;}
  if (h.reloadLeft <= 0) {return;}
  h.reloadLeft = Math.max(0, h.reloadLeft - dt);
  if (h.reloadLeft > 0) {return;}
  h.mag = h.equipment.magSize;
  h.reloadFlash = RELOAD_FLASH_DONE;
}
export function tickGun(h: GunHero, dt: number): void {
  h.fireCd = Math.max(0, h.fireCd - dt);
  h.sprayIdle += dt;
  if (h.sprayIdle > SPRAY_IDLE_GATE) {
    h.sprayIndex = Math.max(0, h.sprayIndex - dt * sprayRecoverRate(h.equipment.id));
  }
  h.equipmentCd = Math.max(0, h.equipmentCd - dt);
  h.mobilityCd = Math.max(0, h.mobilityCd - dt);
  h.muzzleTime = Math.max(0, h.muzzleTime - dt);
  h.attackLockTime = Math.max(0, h.attackLockTime - dt);
  h.reloadFlash = Math.max(0, h.reloadFlash - dt);
  tickSkillChargeGuard(h);
  tickReload(h, dt);
}
export function tryStartReload(h: GunHero): boolean {
  if (!h.alive || h.reloadLeft > 0 || h.stunTime > 0 || h.launchTime > 0) {return false;}
  if (h.mag >= h.equipment.magSize) {return false;}
  h.reloadLeft = Math.max(RELOAD_MIN, h.equipment.reloadTime);
  h.reloadFlash = 0;
  h.sprayIndex = 0;
  h.sprayIdle = 1;
  return true;
}

function stampFire(h: GunHero): void {
  const fx = fxForEquipment(h.equipment.id);
  h.muzzleRow = fx.row;
  h.muzzleTime = Math.max(1, fx.frames) * MUZZLE_FRAME;
  h.muzzleScale = fx.scale;
}
function applyBrawlerShot(h: GunHero, damage: number, radius: number): { damage: number; radius: number; heavy: boolean } {
  if (h.equipment.id !== "brawler") {return { damage, radius, heavy: false };}
  h.brawlerShot += 1;
  if (h.brawlerShot % BRAWLER_HEAVY_EVERY !== 0) {return { damage, radius, heavy: false };}
  return { damage: damage * BRAWLER_HEAVY_DMG, radius: radius * BRAWLER_HEAVY_RADIUS, heavy: true };
}
function consumeBurstInterval(h: GunHero, interval: number): number {
  if (h.equipment.burstShots <= 0 || h.equipment.magSize > 0) {return interval;}
  h.burstLeft -= 1;
  if (h.burstLeft > 0) {return interval;}
  h.burstLeft = h.equipment.burstShots;
  return h.equipment.reloadTime;
}
function finishShot(h: GunHero, interval: number): boolean {
  h.fireCd = interval;
  h.attackLockTime = Math.min(ATTACK_LOCK_CAP, interval * ATTACK_LOCK_RATIO);
  stampFire(h);
  if (h.mag > 0) {return false;}
  tryStartReload(h);
  return true;
}
function lookAim(h: GunHero): Vec2 {
  if (h.aimX * h.aimX + h.aimY * h.aimY > 0.0001) {return { x: h.aimX, y: h.aimY };}
  return { x: h.facingX, y: h.facingY };
}
function spawnShot(
  h: GunHero, dir: Vec2, damage: number, radius: number, ttl: number,
  splash: number, pierce: number, kind: string, heavy: boolean,
): GunProjectile {
  const look = lookAim(h);
  const muzzle = muzzleWorldPos(h.x, h.y - hopLift(h), look.x, look.y, h.equipment.id);
  const eq = h.equipment;
  return {
    owner: h.slot, x: muzzle.x, y: muzzle.y, vx: dir.x * eq.speed, vy: dir.y * eq.speed,
    damage, radius, ttl, splash, pierce, knockback: eq.knockback, kind, source: "normal",
    heavy, leech: eq.leech, ccTime: eq.cc,
  };
}
function spawnVolley(h: GunHero, dir: Vec2, damage: number, radius: number, ttl: number, heavy: boolean): GunProjectile[] {
  const eq = h.equipment;
  if (eq.id === "mortar") {
    const splash = eq.splash > 1.0 ? eq.splash : MORTAR_SPLASH;
    return [spawnShot(h, dir, damage, Math.max(radius, MORTAR_RADIUS_MIN), ttl, splash, 0, "shell", heavy)];
  }
  const count = Math.max(1, eq.projectiles);
  const kind = projectileKind(eq.id, eq.kind);
  const shots: GunProjectile[] = [];
  for (let i = 0; i < count; i += 1) {
    shots.push(spawnShot(h, rotateVec(dir.x, dir.y, pelletOffset(i, count, eq.spread)), damage, radius, ttl, eq.splash, eq.pierce, kind, heavy));
  }
  return shots;
}

export function tryNormalAttack(h: GunHero, direction: Vec2): GunFireResult {
  if (!h.alive || h.fireCd > 0 || h.launchTime > 0 || h.stunTime > 0 || h.turtle) {return IDLE_FIRE;}
  if (h.reloadLeft > 0) {return IDLE_FIRE;}
  if (h.mag <= 0) {return { ...IDLE_FIRE, startedReload: tryStartReload(h) };}
  const dir = attackDirection(direction.x, direction.y);
  h.facingX = dir.x; h.facingY = dir.y; h.aimX = dir.x; h.aimY = dir.y;
  const eq = h.equipment;
  const tuned = applyBrawlerShot(h, eq.damage, eq.radius * RADIUS_FIRE_MUL);
  const sprayI = Math.floor(h.sprayIndex);
  let kick = sprayKick(eq.id, sprayI);
  h.sprayIndex = sprayI + 1;
  h.sprayIdle = 0;
  h.heavyShot = tuned.heavy;
  if (tuned.heavy) {
    kick = { x: kick.x * BRAWLER_KICK_MUL, y: kick.y * BRAWLER_KICK_MUL + BRAWLER_KICK_Y };
    h.sprayIndex = sprayI + 3;
  }
  const ttl = eq.range * (1.0 + h.rouletteRange);
  const projectiles = spawnVolley(h, dir, tuned.damage, tuned.radius, ttl, tuned.heavy);
  const interval = consumeBurstInterval(h, eq.interval * Math.max(RATE_FLOOR, 1.0 - h.rouletteRate));
  h.mag = Math.max(0, h.mag - 1);
  return { fired: true, startedReload: finishShot(h, interval), projectiles, mouseKick: kick };
}

function isBlastTarget(h: GunHero, t: GunHero, ox: number, oy: number): boolean {
  if (t.slot === h.slot || !t.alive) {return false;}
  return Math.hypot(t.x - ox, t.y - oy) <= BLAST_HOP_RADIUS;
}
function mortarHits(h: GunHero, ox: number, oy: number, others: readonly GunHero[]): MobilityHit[] {
  const hits: MobilityHit[] = [];
  for (const t of others) {
    if (!isBlastTarget(h, t, ox, oy)) {continue;}
    hits.push({
      targetSlot: t.slot, damage: BLAST_HOP_DAMAGE, source: "mobility", ccTime: BLAST_HOP_CC,
      knockback: BLAST_HOP_KB, originX: ox, originY: oy, label: "BLAST HOP", effectKind: "explosion",
    });
  }
  return hits;
}
function applyMobilityPerk(h: GunHero, id: string, ox: number, oy: number, others: readonly GunHero[]): MobilityHit[] {
  if (id === "leech") {h.hp = Math.min(h.maxHp, h.hp + LEECH_HEAL); return [];}
  if (id === "breaker") {h.guardTime = BREAKER_GUARD; return [];}
  if (id === "blade") {h.evadeTime = BLADE_EVADE; return [];}
  if (id === "brawler") {h.comboImmunity = WEAVE_IMMUNITY; return [];}
  if (id === "mortar") {return mortarHits(h, ox, oy, others);}
  if (!NAMED_MOBILITY.has(id)) {h.guardTime = BRACE_GUARD;}
  return [];
}

export function applyMobility(
  h: GunHero, direction: Vec2, covers: readonly CoverRect[], others: readonly GunHero[] = [],
): { used: boolean; hits: MobilityHit[] } {
  if (!h.alive || h.mobilityCd > 0 || h.launchTime > 0 || h.rootTime > 0 || h.stunTime > 0 || h.turtle) {
    return { used: false, hits: [] };
  }
  if (h.comboCaptureTime > 0) {
    h.comboCaptureTime = 0; h.comboHits = 0; h.comboTime = 0; h.comboDamage = 0;
    h.comboOwner = -1; h.comboImmunity = Math.max(h.comboImmunity, COMBO_BREAK_IMMUNITY);
  }
  h.attackLockTime = 0;
  h.fireCd = Math.min(h.fireCd, CANCEL_FIRE_CD);
  h.chargingSkill = false;
  h.chargeTime = 0;
  const dir = attackDirection(direction.x, direction.y);
  const oldX = h.x;
  const oldY = h.y;
  const moved = resolveCoverMotion(oldX, oldY, dir.x * h.equipment.mobilityDistance, dir.y * h.equipment.mobilityDistance, covers);
  const clamped = clampArena(moved.x, moved.y);
  h.x = clamped.x; h.y = clamped.y;
  h.mobilityCd = h.equipment.mobilityCooldown;
  h.evadeTime = Math.max(h.evadeTime, MOBILITY_EVADE);
  if (h.comboHits > 0) {
    h.comboHits = 0; h.comboTime = 0; h.comboDamage = 0; h.comboOwner = -1;
    h.comboImmunity = COMBO_MOBILITY_IMMUNITY; h.hitstunTime = 0;
  }
  return { used: true, hits: applyMobilityPerk(h, h.equipment.id, oldX, oldY, others) };
}

export function applyGunLoot(h: GunHero, mode: string): boolean {
  if (!h.alive) {return false;}
  if (!(GUN_LOOT_MODES as readonly string[]).includes(mode)) {return false;}
  const nextId = nextGunLootId(h.equipment.id);
  if (nextId === "" || nextId === h.equipment.id) {return false;}
  h.equipment = makeEquipment(nextId);
  h.burstLeft = h.equipment.burstShots > 0 ? h.equipment.burstShots : BURST_LEFT_DEFAULT;
  h.mag = h.equipment.magSize;
  h.reloadLeft = 0;
  h.reloadFlash = 0;
  return true;
}

function skillApply(skill: SkillAttackResult): GunApplyResult {
  return {
    kind: "skill", projectiles: skill.projectiles, hits: [], used: skill.fired,
    zones: skill.zones, mine: skill.mine, wall: skill.wall,
  };
}

export function applyGunInput(
  h: GunHero, input: GunInput, covers: readonly CoverRect[], others: readonly GunHero[] = [],
): GunApplyResult {
  const aim = { x: h.facingX, y: h.facingY };
  if (input.mobility) {
    const lenSq = input.moveX * input.moveX + input.moveY * input.moveY;
    const dir = lenSq > 0.1 ? { x: input.moveX, y: input.moveY } : aim;
    const mob = applyMobility(h, dir, covers, others);
    return { ...IDLE_APPLY, kind: "mobility", hits: mob.hits, used: mob.used };
  }
  if (input.reload) {tryStartReload(h);}
  let fire: GunFireResult | null = null;
  if (wantsFire(h.equipment.fireMode, input.primary, input.primaryPressed)) {
    cancelSkillCharge(h);
    fire = tryNormalAttack(h, aim);
  }
  const dt = (input.dt ?? 0) > 0 ? input.dt ?? 1 / 60 : 1 / 60;
  const held = Boolean(input.equipment) || Boolean(input.equipmentPressed);
  const skill = applySkillInput(
    h, held, Boolean(input.equipmentPressed), Boolean(input.equipmentReleased), dt, aim, covers,
  );
  if (skill.fired) {return skillApply(skill);}
  if (fire?.fired) {
    return { ...IDLE_APPLY, kind: "fire", projectiles: fire.projectiles, used: true };
  }
  if (input.reload) {return { ...IDLE_APPLY, kind: "reload" };}
  return IDLE_APPLY;
}

export function gunReach(h: GunHero): number {
  return equipmentReach(h.equipment, h.rouletteRange);
}

export const seedGun = gunSeedFields;
export const seed = gunSeedFields;
export const tick = tickGun;
export const apply = applyGunInput;
