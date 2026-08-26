/* eslint-disable max-lines -- cpu_behavior.gd think 분기(회복·오브·타워·크레이트) */
/**
 * CPU think/apply/fleet — match-cpu.ts 의 틱 루프.
 */
import { MatchRng } from "./match-rng.js";
import {
  CPU_AIM_ERROR_RAD, CPU_CRATE_CHANCE, CPU_CRATE_FIGHT_CAP, CPU_CRATE_NEAR,
  CPU_MOBILITY_CHANCE, CPU_MOVE_SCALE_MAX, CPU_MOVE_SCALE_MIN,
  CPU_ORB_CHANCE, CPU_ORB_FIGHT_CAP, CPU_TARGET_HOLD_JITTER_SEC, CPU_TARGET_HOLD_MIN_SEC,
  CPU_TARGET_RANGE, CPU_THINK_JITTER_SEC, CPU_THINK_MIN_SEC, CPU_TOWER_CHANCE,
  CPU_TOWER_FIGHT_CAP, CPU_ULTIMATE_CHANCE, CPU_ULTIMATE_READY, applyCpuMove,
  asCpuWorld, bestHealthPickup, chooseCpuTarget, cpuActionSpeed, cpuAimPoint, cpuCcLockScale,
  cpuDirTo, cpuFind, cpuHypot2, cpuNormalReach, cpuOrthogonal, cpuPreferredRange,
  cpuSeedFields, cpuTargetValid, cpuWantCrateFire, cpuWantMedkit, cpuWantTowerFire,
  hazardEscapeVector, nearestAlive, nearestOrb,
  type CpuBody, type CpuFields, type CpuMark, type CpuMatchInput,
  type CpuOrb, type CpuWorld, type CpuZone,
} from "./match-cpu.js";

/** game_world.gd:600 — 사거리 안·시야 확보·쿨 0 이면 4.5% 로 스킬 차지 시작. */
export const CPU_EQUIP_CHANCE = 0.045;
export const CPU_CHARGE_MIN = 0.34;
export const CPU_CHARGE_MAX = 1.15;

export type CpuDriveInput = CpuMatchInput & {
  firePressed: boolean;
  equipment: boolean;
  equipmentPressed: boolean;
  equipmentReleased: boolean;
};

type CpuSkillBody = CpuBody & {
  equipmentCd?: number;
  chargingSkill?: boolean;
  chargeTime?: number;
};

const CPU_FIXED_DT = 1 / 60;
const DEFAULT_PREFERRED_RANGE = CPU_TARGET_RANGE;

function posmod(n: number, m: number): number {
  return ((n % m) + m) % m;
}

function bySlot(heroes: Iterable<CpuBody>): CpuBody[] {
  return [...heroes].sort((a, b) => a.slot - b.slot);
}

function fightWish(
  hero: CpuBody,
  prey: CpuBody,
  world?: CpuWorld,
): { x: number; y: number; action: string } {
  const to = cpuDirTo(hero.x, hero.y, prey.x, prey.y);
  const dist = Math.hypot(prey.x - hero.x, prey.y - hero.y);
  const orth = cpuOrthogonal(to.x, to.y);
  const sign = hero.slot % 2 === 0 ? -1 : 1;
  const strafe = { x: orth.x * sign, y: orth.y * sign };
  const preferred = cpuPreferredRange(hero);
  if (world?.lineBlocked?.(hero.x, hero.y, prey.x, prey.y)) {
    const n = applyCpuMove(to.x * 0.35 + strafe.x, to.y * 0.35 + strafe.y, 1);
    return { x: n.mx, y: n.my, action: "FLANK" };
  }
  if (dist < preferred * 0.72) {
    const n = applyCpuMove(strafe.x * 0.75 - to.x * 0.25, strafe.y * 0.75 - to.y * 0.25, 1);
    return { x: n.mx, y: n.my, action: "DISENGAGE" };
  }
  if (dist <= preferred * 1.15) {
    const n = applyCpuMove(strafe.x * 0.88 + to.x * 0.12, strafe.y * 0.88 + to.y * 0.12, 1);
    return { x: n.mx, y: n.my, action: "HOLD_RANGE" };
  }
  const n = applyCpuMove(to.x + strafe.x * 0.20, to.y + strafe.y * 0.20, 1);
  return { x: n.mx, y: n.my, action: "CLOSE_RANGE" };
}

function ultWantByAnimal(animal: number, dist: number, hpRatio: number): boolean {
  if (animal === 3) {return dist < 640 || hpRatio < 0.42;}
  if (animal === 5) {return hpRatio < 0.55 || dist < 220;}
  if (animal === 7) {return dist < 380 || hpRatio < 0.50;}
  if (animal === 10) {return dist > 80 && dist < 520;}
  const ranges = [520, 300, 340, 420, 420, 420, 210, 420, 480, 360, 420, 300];
  return dist < (ranges[animal] ?? 420);
}

export function cpuWantUltimate(hero: CpuBody, prey: CpuBody | null): boolean {
  if (!hero.alive || hero.downed || hero.eliminated) {return false;}
  if ((hero.stunTime ?? 0) > 0 || hero.burrowed) {return false;}
  const animal = posmod(hero.animal ?? hero.slot, 12);
  const dist = prey ? Math.hypot(prey.x - hero.x, prey.y - hero.y) : 99999;
  const hpRatio = hero.maxHp > 1 ? hero.hp / hero.maxHp : 1;
  if (!prey && animal !== 5 && animal !== 7) {return false;}
  return ultWantByAnimal(animal, dist, hpRatio);
}

export function cpuWantMobility(hero: CpuBody, prey: CpuBody, action: string): boolean {
  if (action === "SEEK_HEAL") {return false;}
  if ((hero.mobilityCd ?? 0) > 0 || (hero.launchTime ?? 0) > 0) {return false;}
  const preferred = hero.preferredRange ?? DEFAULT_PREFERRED_RANGE;
  const dist = Math.hypot(prey.x - hero.x, prey.y - hero.y);
  return dist > preferred * 1.35 || dist < preferred * 0.48;
}

export function cpuWantFire(
  hero: CpuBody,
  prey: CpuBody,
  world?: CpuWorld,
): boolean {
  const dist = Math.hypot(prey.x - hero.x, prey.y - hero.y);
  if (dist >= cpuNormalReach(hero)) {return false;}
  if (world?.lineBlocked?.(hero.x, hero.y, prey.x, prey.y)) {return false;}
  return true;
}

export type CpuMind = CpuFields & {
  mx: number;
  my: number;
  aimX: number;
  aimY: number;
  ready: boolean;
  fireHeld: boolean;
  equipmentHeld: boolean;
  cpuChargeTarget: number;
};

/** 방 시드 직후 CPU 두뇌 — think 는 원본 슬롯 오프셋. */
export function seedCpu(slot: number, x = 0, y = 0): CpuMind {
  return {
    ...cpuSeedFields(slot),
    mx: 0,
    my: 0,
    aimX: x + 1,
    aimY: y,
    ready: false,
    fireHeld: false,
    equipmentHeld: false,
    cpuChargeTarget: CPU_CHARGE_MIN,
  };
}

function setMove(mind: CpuMind, x: number, y: number, scale: number, action: string): void {
  const move = applyCpuMove(x, y, scale);
  mind.mx = move.mx;
  mind.my = move.my;
  mind.action = action;
  mind.ready = true;
}

function aimAt(
  mind: CpuMind, hero: CpuBody, tx: number, ty: number, rng?: MatchRng,
): void {
  const err = rng ? rng.rangef(-CPU_AIM_ERROR_RAD, CPU_AIM_ERROR_RAD) : 0;
  const dummy = { x: tx, y: ty, slot: -1, alive: true, hp: 1, maxHp: 1 } as CpuBody;
  const aim = cpuAimPoint(hero, dummy, err);
  mind.aimX = aim.x;
  mind.aimY = aim.y;
}

function blockedSteer(
  hero: CpuBody, tx: number, ty: number, to: { x: number; y: number },
  blend: number, world?: CpuWorld,
): { x: number; y: number } {
  if (!world?.lineBlocked?.(hero.x, hero.y, tx, ty)) {return to;}
  const orth = cpuOrthogonal(to.x, to.y);
  const n = applyCpuMove(to.x * blend + orth.x, to.y * blend + orth.y, 1);
  return { x: n.mx, y: n.my };
}

function lockWish(hero: CpuBody, prey: CpuBody, mind: CpuMind, rng: MatchRng, world?: CpuWorld): void {
  const wish = fightWish(hero, prey, world);
  const scale = cpuActionSpeed(hero) * rng.rangef(CPU_MOVE_SCALE_MIN, CPU_MOVE_SCALE_MAX);
  setMove(mind, wish.x, wish.y, scale, wish.action);
  const err = rng.rangef(-CPU_AIM_ERROR_RAD, CPU_AIM_ERROR_RAD);
  const aim = cpuAimPoint(hero, prey, err);
  mind.aimX = aim.x;
  mind.aimY = aim.y;
}

function dodgeHazard(hero: CpuBody, mind: CpuMind, bodies: CpuBody[], world?: CpuWorld): void {
  const escape = hazardEscapeVector(hero, world, bodies);
  if (cpuHypot2(escape.x, escape.y) <= 0.1) {return;}
  setMove(mind, escape.x, escape.y, cpuCcLockScale(hero), "DODGE_WARNING");
}

function seekHeal(
  mind: CpuMind, hero: CpuBody, prey: CpuBody | undefined, rng: MatchRng, world?: CpuWorld,
): boolean {
  const idx = bestHealthPickup(hero, world);
  if (idx < 0 || !world?.pickups) {return false;}
  const p = world.pickups[idx];
  const to = cpuDirTo(hero.x, hero.y, p.x, p.y);
  const sign = hero.slot % 2 === 0 ? -1 : 1;
  const orth = cpuOrthogonal(to.x, to.y);
  let move = to;
  if (world.lineBlocked?.(hero.x, hero.y, p.x, p.y)) {
    const n = applyCpuMove(to.x * 0.38 + orth.x * sign, to.y * 0.38 + orth.y * sign, 1);
    move = { x: n.mx, y: n.my };
  }
  setMove(mind, move.x, move.y, cpuCcLockScale(hero), "SEEK_HEAL");
  mind.crateTarget = -1;
  if (prey) {aimAt(mind, hero, prey.x, prey.y, rng);}
  return true;
}

function seekOrb(
  mind: CpuMind, hero: CpuBody, fight: number, rng: MatchRng, world?: CpuWorld,
): boolean {
  const orbs: readonly CpuOrb[] = world?.crateOrbs ?? [];
  const idx = nearestOrb(hero.x, hero.y, orbs);
  if (idx < 0) {return false;}
  const orb = orbs[idx];
  const dist = Math.hypot(hero.x - orb.x, hero.y - orb.y);
  if (dist >= Math.min(fight, CPU_ORB_FIGHT_CAP) || !rng.chance(CPU_ORB_CHANCE)) {return false;}
  const to = cpuDirTo(hero.x, hero.y, orb.x, orb.y);
  const move = blockedSteer(hero, orb.x, orb.y, to, 0.40, world);
  setMove(mind, move.x, move.y, 1, "SEEK_ORB");
  mind.crateTarget = -1;
  return true;
}

function seekTower(
  mind: CpuMind, hero: CpuBody, fight: number, rng: MatchRng, world?: CpuWorld,
): boolean {
  const tower = world?.midTower;
  if (!tower?.alive) {return false;}
  const dist = Math.hypot(hero.x - tower.x, hero.y - tower.y);
  if (dist >= Math.min(fight, CPU_TOWER_FIGHT_CAP) || !rng.chance(CPU_TOWER_CHANCE)) {return false;}
  const to = cpuDirTo(hero.x, hero.y, tower.x, tower.y);
  mind.aimX = hero.x + to.x;
  mind.aimY = hero.y + to.y;
  let move = to;
  if (dist < cpuPreferredRange(hero) * 0.62) {move = cpuOrthogonal(to.x, to.y);}
  setMove(mind, move.x, move.y, 1, "SEEK_TOWER");
  mind.crateTarget = -1;
  return true;
}

function seekCrate(
  mind: CpuMind, hero: CpuBody, fight: number, rng: MatchRng, world?: CpuWorld,
): boolean {
  const crates: readonly CpuMark[] = world?.crates ?? [];
  const idx = nearestAlive(hero.x, hero.y, crates, CPU_CRATE_NEAR);
  if (idx < 0) {return false;}
  const crate = crates[idx];
  const dist = Math.hypot(hero.x - crate.x, hero.y - crate.y);
  if (dist >= Math.min(fight, CPU_CRATE_FIGHT_CAP) || !rng.chance(CPU_CRATE_CHANCE)) {return false;}
  const to = cpuDirTo(hero.x, hero.y, crate.x, crate.y);
  mind.crateTarget = idx;
  mind.aimX = hero.x + to.x;
  mind.aimY = hero.y + to.y;
  let move = blockedSteer(hero, crate.x, crate.y, to, 0.36, world);
  if (move === to && dist < cpuPreferredRange(hero) * 0.55) {move = cpuOrthogonal(to.x, to.y);}
  setMove(mind, move.x, move.y, 1, "SEEK_CRATE");
  return true;
}

function applySeek(
  mind: CpuMind, hero: CpuBody, prey: CpuBody | undefined, rng: MatchRng, world?: CpuWorld,
): void {
  const fight = prey ? Math.hypot(hero.x - prey.x, hero.y - prey.y) : 99999;
  if (seekHeal(mind, hero, prey, rng, world)) {return;}
  if (seekOrb(mind, hero, fight, rng, world)) {return;}
  if (seekTower(mind, hero, fight, rng, world)) {return;}
  if (seekCrate(mind, hero, fight, rng, world)) {return;}
  if (prey) {
    lockWish(hero, prey, mind, rng, world);
    return;
  }
  mind.action = "HARASS";
  mind.ready = false;
}

function refreshThink(
  mind: CpuMind, hero: CpuBody, bodies: CpuBody[], rng: MatchRng, world?: CpuWorld,
): void {
  mind.think = CPU_THINK_MIN_SEC + rng.rangef(0, CPU_THINK_JITTER_SEC);
  const oldTarget = mind.target;
  const chosen = chooseCpuTarget(hero.slot, bodies, rng);
  const held = cpuFind(bodies, oldTarget);
  if (mind.targetHold <= 0 || oldTarget < 0 || !cpuTargetValid(held)) {
    mind.target = chosen;
    mind.targetHold = CPU_TARGET_HOLD_MIN_SEC + rng.rangef(0, CPU_TARGET_HOLD_JITTER_SEC);
  }
  const prey = cpuFind(bodies, mind.target);
  applySeek(mind, hero, cpuTargetValid(prey) ? prey : undefined, rng, world);
  dodgeHazard(hero, mind, bodies, world);
}

function idleUse(mind: CpuMind, use: boolean): CpuDriveInput {
  mind.fireHeld = false;
  mind.equipmentHeld = false;
  return {
    mx: mind.mx, my: mind.my, aimX: mind.aimX, aimY: mind.aimY,
    fire: false, ultimate: false, mobility: false, use,
    firePressed: false, equipment: false, equipmentPressed: false, equipmentReleased: false,
  };
}

export function tickCpu(
  mind: CpuMind,
  hero: CpuBody,
  heroes: Iterable<CpuBody>,
  rng: MatchRng,
  dt: number,
  world?: CpuWorld,
): CpuDriveInput | null {
  if (!hero.alive || hero.eliminated || hero.downed) {return null;}
  if ((hero.stunTime ?? 0) > 0) {return null;}
  const bodies = bySlot(heroes).map((h) => (
    h.slot === hero.slot ? { ...h, target: mind.target, recentAttacker: mind.recentAttacker } : h
  ));
  const use = cpuWantMedkit(hero, rng, world);
  mind.think -= dt;
  mind.targetHold = Math.max(0, mind.targetHold - dt);
  if (mind.think <= 0) {refreshThink(mind, hero, bodies, rng, world);}
  const cmd = applyCpu(mind, hero, bodies, rng, world);
  if (cmd) {return { ...cmd, use };}
  if (use) {return idleUse(mind, true);}
  return null;
}

function objectFireAim(
  mind: CpuMind, hero: CpuBody, world: CpuWorld | undefined,
): { fire: boolean; aimX: number; aimY: number } {
  const tower = world?.midTower;
  if (cpuWantTowerFire(hero, mind.action, tower) && tower) {
    return { fire: true, aimX: tower.x, aimY: tower.y };
  }
  const crate = world?.crates?.[mind.crateTarget];
  if (cpuWantCrateFire(hero, mind.action, crate, world) && crate) {
    return { fire: true, aimX: crate.x, aimY: crate.y };
  }
  return { fire: false, aimX: mind.aimX, aimY: mind.aimY };
}

export function cpuWantEquipment(
  hero: CpuSkillBody, prey: CpuBody, world?: CpuWorld,
): boolean {
  if ((hero.equipmentCd ?? 0) > 0) {return false;}
  const dist = Math.hypot(prey.x - hero.x, prey.y - hero.y);
  if (dist >= cpuNormalReach(hero)) {return false;}
  if (world?.lineBlocked?.(hero.x, hero.y, prey.x, prey.y)) {return false;}
  return true;
}

function stampFireEdge(mind: CpuMind, fire: boolean): boolean {
  const pressed = fire && !mind.fireHeld;
  mind.fireHeld = fire;
  return pressed;
}

function stampEquipment(
  mind: CpuMind, hero: CpuSkillBody, wantStart: boolean, rng: MatchRng,
): { held: boolean; pressed: boolean; released: boolean } {
  if (hero.chargingSkill) {
    const done = (hero.chargeTime ?? 0) >= mind.cpuChargeTarget;
    mind.equipmentHeld = !done;
    return { held: !done, pressed: false, released: done };
  }
  if (wantStart) {
    mind.cpuChargeTarget = rng.rangef(CPU_CHARGE_MIN, CPU_CHARGE_MAX);
    mind.equipmentHeld = true;
    return { held: true, pressed: true, released: false };
  }
  mind.equipmentHeld = false;
  return { held: false, pressed: false, released: false };
}

function wantUltimate(hero: CpuBody, prey: CpuBody | null, rng: MatchRng): boolean {
  if ((hero.ultimateCharge ?? 0) < CPU_ULTIMATE_READY || hero.turtle) {return false;}
  return cpuWantUltimate(hero, prey) && rng.chance(CPU_ULTIMATE_CHANCE);
}

function preyCombat(
  mind: CpuMind, hero: CpuBody, prey: CpuBody, rng: MatchRng, world?: CpuWorld,
): { fire: boolean; mobility: boolean; wantEquip: boolean } {
  return {
    mobility: cpuWantMobility(hero, prey, mind.action) && rng.chance(CPU_MOBILITY_CHANCE),
    fire: cpuWantFire(hero, prey, world) && (hero.fireCd ?? 0) <= 0,
    wantEquip: cpuWantEquipment(hero, prey, world) && rng.chance(CPU_EQUIP_CHANCE),
  };
}

/** 매 틱 버튼 — 직전 think 의 이동/조준 위에 fire/ultimate/mobility/equipment. */
export function applyCpu(
  mind: CpuMind,
  hero: CpuBody,
  heroes: Iterable<CpuBody>,
  rng: MatchRng,
  world?: CpuWorld,
): CpuDriveInput | null {
  if (!mind.ready) {return null;}
  const prey = cpuFind(bySlot(heroes), mind.target);
  const validPrey = cpuTargetValid(prey) ? prey : null;
  const combat = validPrey
    ? preyCombat(mind, hero, validPrey, rng, world)
    : { fire: false, mobility: false, wantEquip: false };
  let fire = combat.fire;
  let aimX = mind.aimX;
  let aimY = mind.aimY;
  if (!fire) {
    const obj = objectFireAim(mind, hero, world);
    fire = obj.fire;
    aimX = obj.aimX;
    aimY = obj.aimY;
  }
  const skillHero = hero as CpuSkillBody;
  if (skillHero.chargingSkill) {fire = false;}
  const firePressed = stampFireEdge(mind, fire);
  const eq = stampEquipment(mind, skillHero, combat.wantEquip, rng);
  return {
    mx: mind.mx, my: mind.my, aimX, aimY, fire,
    ultimate: wantUltimate(hero, validPrey, rng),
    mobility: combat.mobility, use: false,
    firePressed, equipment: eq.held, equipmentPressed: eq.pressed, equipmentReleased: eq.released,
  };
}

/** 방별 CPU 두뇌 — MatchSim 이 시드로 하나 만들어 매 틱 command() 를 부른다. */
export class CpuFleet {
  private readonly rng: MatchRng;
  private readonly minds = new Map<number, CpuMind>();

  constructor(seed?: number) {
    this.rng = new MatchRng(seed);
  }

  /** 이번 틱의 CPU 입력. 표적이 없으면 null. think 사이에는 직전 이동을 유지한다. */
  command(
    hero: CpuBody, heroes: Iterable<CpuBody>, _tick: number, zoneOrWorld?: CpuZone | CpuWorld,
  ): CpuDriveInput | null {
    let mind = this.minds.get(hero.slot);
    if (!mind) {
      mind = seedCpu(hero.slot, hero.x, hero.y);
      mind.think = 0;
      this.minds.set(hero.slot, mind);
    }
    mind.recentAttacker = hero.recentAttacker ?? mind.recentAttacker;
    const bodies = [...heroes].map((h) => {
      const other = this.minds.get(h.slot);
      return other ? { ...h, target: other.target } : h;
    });
    return tickCpu(mind, hero, bodies, this.rng, CPU_FIXED_DT, asCpuWorld(zoneOrWorld));
  }
}
export const seed = seedCpu;
export const tick = tickCpu;
export const apply = applyCpu;
