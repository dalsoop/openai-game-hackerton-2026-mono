/* eslint-disable max-lines -- 무기별 발동·이펙트가 한 파일 */
/**
 * 우클릭 장비 스킬 차지 — game_world.gd _begin/_continue/_release/_try_equipment_attack.
 * 수치·분기는 원조 원본 1603-1717행. RNG·시계 없음.
 */
import { clampArena, resolveCoverMotion, type CoverRect } from "./match-covers.js";
import { addEffect, type EffectStore } from "./match-effects.js";
import { attackDirection, pelletOffset, rotateVec } from "./match-gun-geom.js";
import type { Equipment, Vec2 } from "./match-equipment.js";

export const CHARGE_MAX = 1.15;
export const CHARGE_MOVE_MUL = 0.62;
export const CHARGE_POWER_MIN = 0.65;
export const CHARGE_POWER_MAX = 1.25;
export const CHARGE_REACH_MIN = 0.80;
export const CHARGE_REACH_MAX = 1.18;
export const CHARGE_RADIUS_MIN = 0.84;
export const CHARGE_RADIUS_MAX = 1.22;
export const CANCEL_FIRE_CD = 0.04;
export const SKILL_MUZZLE = 28.0;

export type SkillHero = {
  slot: number; x: number; y: number; alive: boolean;
  equipment: Equipment; equipmentCd: number;
  launchTime: number; hitstunTime: number; stunTime: number; comboCaptureTime: number;
  chargingSkill: boolean; chargeTime: number; chargeDirX: number; chargeDirY: number;
  attackLockTime: number; fireCd: number; evadeTime: number; guardTime: number;
  superArmorTime: number; superArmorStrength: number;
  facingX: number; facingY: number; action?: string;
};

export type SkillProjectile = {
  owner: number; x: number; y: number; vx: number; vy: number; damage: number; radius: number;
  ttl: number; splash: number; pierce: number; knockback: number; kind: string;
  source: "equipment"; heavy: boolean; leech: boolean; ccTime: number; homing: number;
};

export type SkillZoneSpec = {
  x: number; y: number; radius: number; owner: number; delay: number; damage: number;
  ccTime: number; knockback: number; leech: boolean; effectKind: string; label: string;
  controlKind: "slow" | "root" | "stun";
};

export type SkillMineSpec = {
  x: number; y: number; damage: number; blastRadius: number;
  armTime: number; lifetime: number; fuseTime: number;
};

export type SkillWallSpec = {
  x: number; y: number; facingX: number; facingY: number;
  halfLength: number; lifetime: number; speed: number; damage: number; knockback: number;
};

export type SkillAttackResult = {
  fired: boolean; projectiles: SkillProjectile[]; zones: SkillZoneSpec[];
  mine: SkillMineSpec | null; wall: SkillWallSpec | null;
};

export function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

export function emptySkillResult(): SkillAttackResult {
  return { fired: false, projectiles: [], zones: [], mine: null, wall: null };
}

export function cancelSkillCharge(h: SkillHero): void {
  h.chargingSkill = false;
  h.chargeTime = 0;
}

export function tickSkillChargeGuard(h: SkillHero): void {
  if (!h.chargingSkill) {return;}
  if (!h.alive || h.launchTime > 0 || h.hitstunTime > 0 || h.stunTime > 0) {
    cancelSkillCharge(h);
  }
}

function cancelAttackRecovery(h: SkillHero): void {
  h.attackLockTime = 0;
  h.fireCd = Math.min(h.fireCd, CANCEL_FIRE_CD);
}

export function beginSkillCharge(h: SkillHero, direction: Vec2): boolean {
  if (!h.alive || h.chargingSkill || h.equipmentCd > 0) {return false;}
  if (h.launchTime > 0 || h.hitstunTime > 0 || h.comboCaptureTime > 0 || h.stunTime > 0) {return false;}
  cancelAttackRecovery(h);
  const dir = attackDirection(direction.x, direction.y);
  h.chargingSkill = true;
  h.chargeTime = 0;
  h.chargeDirX = dir.x;
  h.chargeDirY = dir.y;
  h.action = "CHARGING_SKILL";
  return true;
}

export function continueSkillCharge(h: SkillHero, dt: number, direction: Vec2): void {
  if (!h.chargingSkill) {return;}
  if (!h.alive || h.launchTime > 0 || h.hitstunTime > 0 || h.stunTime > 0) {
    cancelSkillCharge(h);
    return;
  }
  h.chargeTime = Math.min(CHARGE_MAX, h.chargeTime + dt);
  const dir = attackDirection(direction.x, direction.y);
  h.chargeDirX = dir.x;
  h.chargeDirY = dir.y;
}

export function releaseSkillCharge(
  h: SkillHero, direction: Vec2, covers: readonly CoverRect[] = [], store?: EffectStore,
): SkillAttackResult {
  if (!h.chargingSkill) {return emptySkillResult();}
  const chargeRatio = Math.min(1, Math.max(0, h.chargeTime / CHARGE_MAX));
  const lenSq = direction.x * direction.x + direction.y * direction.y;
  const chargeDir = lenSq > 0.1
    ? attackDirection(direction.x, direction.y)
    : attackDirection(h.chargeDirX, h.chargeDirY);
  cancelSkillCharge(h);
  return applyEquipmentAttack(h, chargeDir, chargeRatio, covers, store);
}

export function applySkillInput(
  h: SkillHero, held: boolean, pressed: boolean, released: boolean,
  dt: number, direction: Vec2, covers: readonly CoverRect[] = [], store?: EffectStore,
): SkillAttackResult {
  if (pressed || (held && !h.chargingSkill)) {beginSkillCharge(h, direction);}
  if (held && h.chargingSkill) {continueSkillCharge(h, dt, direction);}
  if (released) {return releaseSkillCharge(h, direction, covers, store);}
  return emptySkillResult();
}

type SkillCtx = {
  h: SkillHero; dir: Vec2; charge: number; power: number; reach: number; radius: number;
  covers: readonly CoverRect[]; out: SkillAttackResult;
};

function dash(h: SkillHero, dir: Vec2, dist: number, covers: readonly CoverRect[]): void {
  const moved = resolveCoverMotion(h.x, h.y, dir.x * dist, dir.y * dist, covers);
  const next = clampArena(moved.x, moved.y);
  h.x = next.x;
  h.y = next.y;
}

function spawnBolt(
  ctx: SkillCtx, dir: Vec2, radius: number, splash: number, pierce: number,
  cc: number, kb: number, kind: string, homing: number,
): void {
  const n = attackDirection(dir.x, dir.y);
  const eq = ctx.h.equipment;
  ctx.out.projectiles.push({
    owner: ctx.h.slot, x: ctx.h.x + n.x * SKILL_MUZZLE, y: ctx.h.y + n.y * SKILL_MUZZLE,
    vx: n.x * eq.skillSpeed, vy: n.y * eq.skillSpeed,
    damage: eq.skillDamage * ctx.power, radius, ttl: eq.skillRange * ctx.reach,
    splash, pierce, knockback: kb, kind, source: "equipment", heavy: false, leech: false,
    ccTime: cc, homing,
  });
}

function addZone(
  ctx: SkillCtx, x: number, y: number, radius: number, delay: number, cc: number,
  kb: number, label: string, leech: boolean, effectKind: string, controlKind: SkillZoneSpec["controlKind"] = "slow",
): void {
  ctx.out.zones.push({
    x, y, radius, owner: ctx.h.slot, delay, damage: ctx.h.equipment.skillDamage * ctx.power,
    ccTime: cc, knockback: kb, leech, effectKind, label, controlKind,
  });
}

function skillScatter(ctx: SkillCtx): void {
  dash(ctx.h, { x: -ctx.dir.x, y: -ctx.dir.y }, lerp(65.0, 120.0, ctx.charge), ctx.covers);
  const count = 3 + Math.round(ctx.charge * 4.0);
  for (let i = 0; i < count; i += 1) {
    const rot = rotateVec(ctx.dir.x, ctx.dir.y, pelletOffset(i, count, 0.085));
    spawnBolt(ctx, rot, 7.0, 0, 0, 0, 28.0 + 34.0 * ctx.charge, "pellet", 0);
  }
}

function skillRail(ctx: SkillCtx): void {
  const n = attackDirection(ctx.dir.x, ctx.dir.y);
  const eq = ctx.h.equipment;
  const speed = eq.skillSpeed * ctx.reach;
  ctx.out.projectiles.push({
    owner: ctx.h.slot, x: ctx.h.x + n.x * SKILL_MUZZLE, y: ctx.h.y + n.y * SKILL_MUZZLE,
    vx: n.x * speed, vy: n.y * speed, damage: eq.skillDamage * ctx.power, radius: 7.0,
    ttl: eq.skillRange * ctx.reach, splash: 0, pierce: 1 + Math.round(ctx.charge * 3.0),
    knockback: 90.0 + 70.0 * ctx.charge, kind: "beam", source: "equipment", heavy: false,
    leech: false, ccTime: 0.55 + 0.65 * ctx.charge, homing: 0,
  });
}

function skillMortar(ctx: SkillCtx): void {
  addZone(
    ctx, ctx.h.x + ctx.dir.x * 430.0 * ctx.reach, ctx.h.y + ctx.dir.y * 430.0 * ctx.reach,
    120.0 * ctx.radius, lerp(0.90, 0.62, ctx.charge), 0.80 + 0.70 * ctx.charge,
    95.0 + 80.0 * ctx.charge, "SKYFALL", false, "explosion",
  );
}

function skillLeech(ctx: SkillCtx): void {
  addZone(
    ctx, ctx.h.x + ctx.dir.x * 190.0 * ctx.reach, ctx.h.y + ctx.dir.y * 190.0 * ctx.reach,
    68.0 * ctx.radius, 0.05, 0.45 + 0.45 * ctx.charge, -105.0 - 80.0 * ctx.charge,
    "BLOOD HARPOON", true, "drain",
  );
}

function skillBreaker(ctx: SkillCtx): void {
  ctx.h.superArmorTime = Math.max(ctx.h.superArmorTime, 0.38 + 0.30 * ctx.charge);
  ctx.h.superArmorStrength = Math.max(ctx.h.superArmorStrength, 0.58);
  dash(ctx.h, ctx.dir, 175.0 * ctx.reach, ctx.covers);
  addZone(
    ctx, ctx.h.x, ctx.h.y, 112.0 * ctx.radius, 0.08, 0.85 + 0.75 * ctx.charge,
    125.0 + 100.0 * ctx.charge, "CRASH ENTRY", false, "shockwave",
  );
}

function skillBurst(ctx: SkillCtx): void {
  const count = 2 + Math.round(ctx.charge * 4.0);
  for (let i = 0; i < count; i += 1) {
    const rot = rotateVec(ctx.dir.x, ctx.dir.y, pelletOffset(i, count, 0.055));
    spawnBolt(ctx, rot, 8.0, 18.0 + 16.0 * ctx.charge, 0, 0, 28.0 + 30.0 * ctx.charge, "seeker", 2.4 + 2.0 * ctx.charge);
  }
}

function skillBlade(ctx: SkillCtx): void {
  ctx.h.evadeTime = Math.max(ctx.h.evadeTime, 0.24 + 0.20 * ctx.charge);
  dash(ctx.h, ctx.dir, 190.0 * ctx.reach, ctx.covers);
  addZone(
    ctx, ctx.h.x, ctx.h.y, 92.0 * ctx.radius, 0.03, 0.22 + 0.28 * ctx.charge,
    78.0 + 70.0 * ctx.charge, "CROSS STEP", false, "slashwave",
  );
}

function skillBrawler(ctx: SkillCtx): void {
  dash(ctx.h, ctx.dir, 130.0 * ctx.reach, ctx.covers);
  addZone(
    ctx, ctx.h.x, ctx.h.y, 88.0 * ctx.radius, 0.02, 0.38 + 0.42 * ctx.charge,
    65.0 + 75.0 * ctx.charge, "LIVER SHOT", false, "fist_burst",
  );
}

function skillBomb(ctx: SkillCtx): void {
  ctx.out.mine = {
    x: ctx.h.x + ctx.dir.x * 320.0 * ctx.reach,
    y: ctx.h.y + ctx.dir.y * 320.0 * ctx.reach,
    damage: ctx.h.equipment.skillDamage * ctx.power,
    blastRadius: 118.0 * ctx.radius,
    armTime: lerp(0.72, 0.52, ctx.charge),
    lifetime: 8.0,
    fuseTime: 0.38,
  };
}

function skillSpear(ctx: SkillCtx): void {
  dash(ctx.h, ctx.dir, 150.0 * ctx.reach, ctx.covers);
  addZone(
    ctx,
    ctx.h.x + ctx.dir.x * 120.0 * ctx.reach,
    ctx.h.y + ctx.dir.y * 120.0 * ctx.reach,
    58.0 * ctx.radius, 0.03, 0.38 + 0.42 * ctx.charge, 95.0 + 85.0 * ctx.charge,
    "VAULT IMPALE", false, "spear_line",
  );
}

function skillChain(ctx: SkillCtx): void {
  addZone(
    ctx, ctx.h.x + ctx.dir.x * 175.0 * ctx.reach, ctx.h.y + ctx.dir.y * 175.0 * ctx.reach,
    76.0 * ctx.radius, 0.18, 0.75 + 0.80 * ctx.charge, -105.0 - 75.0 * ctx.charge,
    "CHAIN LOCK", false, "chain_arc", "root",
  );
}

function skillShield(ctx: SkillCtx): void {
  ctx.h.guardTime = 0.42 + 0.48 * ctx.charge;
  ctx.out.wall = {
    x: ctx.h.x + ctx.dir.x * (84.0 + 20.0 * ctx.charge),
    y: ctx.h.y + ctx.dir.y * (84.0 + 20.0 * ctx.charge),
    facingX: ctx.dir.x, facingY: ctx.dir.y,
    halfLength: lerp(96.0, 142.0, ctx.charge),
    lifetime: lerp(0.92, 1.24, ctx.charge),
    speed: lerp(520.0, 720.0, ctx.charge),
    damage: lerp(10.0, 16.0, ctx.charge),
    knockback: lerp(185.0, 255.0, ctx.charge),
  };
}

const SKILL_FN: Readonly<Partial<Record<string, (ctx: SkillCtx) => void>>> = {
  scatter: skillScatter, rail: skillRail, mortar: skillMortar, leech: skillLeech,
  breaker: skillBreaker, burst: skillBurst, blade: skillBlade, brawler: skillBrawler,
  bomb: skillBomb, spear: skillSpear, chain: skillChain, shield: skillShield,
};

/** game_world.gd:1648-1700 add_effect 수치 그대로. */
function emitSkillReleaseFx(
  store: EffectStore | undefined, h: SkillHero, dir: Vec2, charge: number,
): void {
  addEffect(store, {
    kind: "charge_release", x: h.x, y: h.y,
    radius: 54.0 + charge * 28.0, duration: 0.22, color: "#dff8ff", dx: dir.x, dy: dir.y,
  });
  const id = h.equipment.id;
  if (id === "scatter") {
    addEffect(store, {
      kind: "cast", x: h.x, y: h.y, radius: 92.0 + 34.0 * charge, duration: 0.26,
      color: "#ffb45c", dx: dir.x, dy: dir.y,
    });
    return;
  }
  if (id === "rail") {
    addEffect(store, {
      kind: "line", x: h.x, y: h.y, radius: 620.0 + 220.0 * charge, duration: 0.30,
      color: "#71e7ff", dx: dir.x, dy: dir.y,
    });
    return;
  }
  if (id === "leech") {
    addEffect(store, {
      kind: "line", x: h.x, y: h.y, radius: 360.0 + 240.0 * charge, duration: 0.24,
      color: "#dc72ff", dx: dir.x, dy: dir.y,
    });
    return;
  }
  if (id === "burst") {
    addEffect(store, {
      kind: "cast", x: h.x, y: h.y, radius: 78.0 + 24.0 * charge, duration: 0.26,
      color: "#ff5da2", dx: dir.x, dy: dir.y,
    });
    return;
  }
  if (id === "spear") {
    addEffect(store, {
      kind: "spear_line", x: h.x, y: h.y, radius: 440.0 + 230.0 * charge, duration: 0.26,
      color: "#ffe27a", dx: dir.x, dy: dir.y,
    });
    return;
  }
  if (id === "chain") {
    addEffect(store, {
      kind: "chain_arc", x: h.x, y: h.y, radius: 390.0 + 250.0 * charge, duration: 0.28,
      color: "#b78cff", dx: dir.x, dy: dir.y,
    });
  }
}

/** game_world.gd:1638-1717 _try_equipment_attack. */
export function applyEquipmentAttack(
  h: SkillHero, direction: Vec2, chargeRatio = 1, covers: readonly CoverRect[] = [],
  store?: EffectStore,
): SkillAttackResult {
  if (!h.alive || h.equipmentCd > 0 || h.launchTime > 0 || h.hitstunTime > 0 || h.stunTime > 0) {
    return emptySkillResult();
  }
  const charge = Math.min(1, Math.max(0, chargeRatio));
  const dir = attackDirection(direction.x, direction.y);
  const out = emptySkillResult();
  out.fired = true;
  h.action = "CHARGED_SKILL";
  emitSkillReleaseFx(store, h, dir, charge);
  const fn = SKILL_FN[h.equipment.id];
  if (fn) {
    fn({
      h, dir, charge, covers, out,
      power: lerp(CHARGE_POWER_MIN, CHARGE_POWER_MAX, charge),
      reach: lerp(CHARGE_REACH_MIN, CHARGE_REACH_MAX, charge),
      radius: lerp(CHARGE_RADIUS_MIN, CHARGE_RADIUS_MAX, charge),
    });
  }
  h.equipmentCd = h.equipment.cooldown;
  return out;
}

export const seed = emptySkillResult;
export const tick = tickSkillChargeGuard;
export const apply = applySkillInput;
