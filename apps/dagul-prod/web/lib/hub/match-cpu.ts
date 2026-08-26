/**
 * CPU 조종 — 원본 cpu_behavior.gd 의 결정론 포팅.
 * 표적 점수(threat·grudge·target_hold)·교전 밴드·발사/궁극기/모빌리티 요청.
 * 슬롯별 성격 배율은 원본에 없으므로 두지 않는다. 난수는 방 시드 LCG 만 쓴다.
 */
import { ARENA_CENTER, EFFECTIVE_RANGE } from "./match-covers.js";
import { MatchRng } from "./match-rng.js";

/** game_world.gd:270 think 초기값 0.12 + slot*0.025. */
export const CPU_THINK_SEED_BASE = 0.12;
export const CPU_THINK_SEED_SLOT = 0.025;
/** think 리필 — cpu_behavior.gd:54. */
export const CPU_THINK_MIN_SEC = 0.16;
export const CPU_THINK_JITTER_SEC = 0.10;
/** 표적 유지 — cpu_behavior.gd:59 0.42 + [0, 0.30]. */
export const CPU_TARGET_HOLD_MIN_SEC = 0.42;
export const CPU_TARGET_HOLD_JITTER_SEC = 0.30;
/** 조준 각도 오차 — cpu_behavior.gd:143 ±0.085 rad. */
export const CPU_AIM_ERROR_RAD = 0.085;
/** 이동 속도 지터 — cpu_behavior.gd:142. */
export const CPU_MOVE_SCALE_MIN = 0.93;
export const CPU_MOVE_SCALE_MAX = 1.02;
/** 유효 표적 3명 이상이면 이미 2명이 때리는 표적은 스킵 — cpu_behavior.gd:198. */
export const CPU_CROWD_LIMIT = 2;
/** 궁극기 시도 확률 — cpu_behavior.gd:387. */
export const CPU_ULTIMATE_CHANCE = 0.38;
/** 모빌리티 시도 확률 — cpu_behavior.gd:161. */
export const CPU_MOBILITY_CHANCE = 0.025;
/** game_world.gd ULTIMATE_MAX. cpu_try_ultimate 충전 문턱은 MAX-0.5. */
export const CPU_ULTIMATE_MAX = 100;
export const CPU_ULTIMATE_READY = CPU_ULTIMATE_MAX - 0.5;
/** game_world.gd SAFE_ZONE_EDGE_BUFFER — hazard_escape_vector:322. */
export const CPU_SAFE_ZONE_EDGE_BUFFER = 252;
/** 자기장 밖 urgency — cpu_behavior.gd:328. */
export const CPU_ZONE_OUT_URGENCY = 1.85;
/** preferred_range 를 그대로 쓰는 무기 — cpu_behavior.gd:122. */
const FULL_PREFERRED_IDS = new Set(["scatter", "rail", "burst", "mortar", "bomb"]);
/** 표적 점수 가중 — cpu_behavior.gd:202-212. */
export const CPU_SCORE_LEADER = 0.26;
export const CPU_SCORE_FINISH = 0.28;
export const CPU_SCORE_THREAT = 0.13;
export const CPU_SCORE_GRUDGE = 0.11;
export const CPU_SCORE_DOGPILE = 0.10;
export const CPU_SCORE_BOUNTY = 0.06;
export const CPU_SCORE_CROWD = 0.42;
export const CPU_SCORE_RETAIL = 0.18;
export const CPU_SCORE_DIST = 0.15;
export const CPU_SCORE_JITTER = 0.025;
export const CPU_SCORE_DIST_REF = 1260;
/** HOLD 밴드 중심 — 장비 없을 때 burst preferred*1.15 ≈ EFFECTIVE_RANGE*0.65. */
export const CPU_TARGET_RANGE = EFFECTIVE_RANGE * 0.65;
export const CPU_RANGE_SLACK = EFFECTIVE_RANGE * 0.1;
/** 장비가 없을 때 기본 preferred_range — HOLD 하한(×0.72)이 테스트 밴드 안에 남는다. */
const DEFAULT_PREFERRED_RANGE = CPU_TARGET_RANGE;
const DEFAULT_NORMAL_REACH = EFFECTIVE_RANGE * 0.92;
const CPU_FIXED_DT = 1 / 60;
const ZERO = { x: 0, y: 0 };

export type CpuBody = {
  slot: number;
  x: number;
  y: number;
  alive: boolean;
  hp: number;
  maxHp: number;
  eliminated?: boolean;
  downed?: boolean;
  threat?: number;
  bounty?: number;
  recentAttacker?: number;
  target?: number;
  animal?: number;
  ultimateCharge?: number;
  fireCd?: number;
  mobilityCd?: number;
  launchTime?: number;
  preferredRange?: number;
  equipmentId?: string;
  normalReach?: number;
  vx?: number;
  vy?: number;
  turtle?: boolean;
  burrowed?: boolean;
  stunTime?: number;
  ccTime?: number;
  rootTime?: number;
  hitstunTime?: number;
  comboCaptureTime?: number;
  attackLockTime?: number;
  chargingSkill?: boolean;
};

export type CpuFields = {
  target: number;
  targetHold: number;
  think: number;
  action: string;
  recentAttacker: number;
};

export type CpuZone = { radius: number; x?: number; y?: number };

/** 통합측 MatchInput 과 같은 키 — fire/ultimate/mobility 를 요청만 한다. */
export type CpuMatchInput = {
  mx: number;
  my: number;
  aimX: number;
  aimY: number;
  fire: boolean;
  ultimate: boolean;
  mobility: boolean;
};

export type CpuCommand = CpuMatchInput;

export type CpuWorld = {
  zone?: CpuZone;
  lineBlocked?: (ax: number, ay: number, bx: number, by: number) => boolean;
};

function clamp01(n: number): number {
  return Math.min(1, Math.max(0, n));
}

function hypot2(x: number, y: number): number {
  return x * x + y * y;
}

function dirTo(ax: number, ay: number, bx: number, by: number): { x: number; y: number } {
  const dx = bx - ax;
  const dy = by - ay;
  const d = Math.hypot(dx, dy);
  if (d <= 1e-8) {return { x: 0, y: 0 };}
  return { x: dx / d, y: dy / d };
}

/** Godot Vector2.orthogonal → (-y, x). */
function orthogonal(x: number, y: number): { x: number; y: number } {
  return { x: -y, y: x };
}

function normalize(x: number, y: number): { x: number; y: number } {
  const d = Math.hypot(x, y);
  if (d <= 1e-8) {return { x: 0, y: 0 };}
  return { x: x / d, y: y / d };
}

function posmod(n: number, m: number): number {
  return ((n % m) + m) % m;
}

export function cpuTargetValid(hero: CpuBody | undefined): boolean {
  return Boolean(hero) && hero!.alive && !hero!.eliminated;
}

/** SimHero 생성 시 CPU 필드 — game_world.gd:270. */
export function cpuSeedFields(slot: number): CpuFields {
  return {
    target: -1,
    targetHold: 0,
    think: CPU_THINK_SEED_BASE + slot * CPU_THINK_SEED_SLOT,
    action: "HARASS",
    recentAttacker: -1,
  };
}

export function cpuAdvanceWeight(dist: number, rangeMult = 1): number {
  const target = CPU_TARGET_RANGE * rangeMult;
  if (dist > target + CPU_RANGE_SLACK) {return 1;}
  if (dist < target - CPU_RANGE_SLACK) {return -1;}
  return 0;
}

export function cpuPreferredRange(hero: CpuBody): number {
  let preferred = hero.preferredRange ?? DEFAULT_PREFERRED_RANGE;
  const id = hero.equipmentId ?? "burst";
  if (!FULL_PREFERRED_IDS.has(id)) {
    preferred = Math.min(preferred, cpuNormalReach(hero) * 0.62);
  }
  return preferred;
}

export function cpuNormalReach(hero: CpuBody): number {
  return hero.normalReach ?? DEFAULT_NORMAL_REACH;
}

export function cpuActionSpeed(hero: CpuBody): number {
  const ccSpeed = (hero.ccTime ?? 0) > 0 ? 0.42 : 1;
  const hitstunSpeed = (hero.rootTime ?? 0) > 0
    ? 0.35
    : ((hero.hitstunTime ?? 0) > 0 || (hero.comboCaptureTime ?? 0) > 0 ? 0.72 : 1);
  let actionSpeed = (hero.attackLockTime ?? 0) > 0 ? 0.76 : 1;
  if (hero.chargingSkill) {actionSpeed *= 0.62;}
  return ccSpeed * hitstunSpeed * actionSpeed;
}

/** apply_cpu_move — 위시 방향에 속도 배율을 곱해 MatchInput 이동 성분으로 만든다. */
export function applyCpuMove(wishX: number, wishY: number, speedScale: number): { mx: number; my: number } {
  const n = normalize(wishX, wishY);
  return { mx: n.x * speedScale, my: n.y * speedScale };
}

/** 조준점 — 표적 좌표를 히어로 기준 각도 오차만큼 회전(리드 없음). */
export function cpuAimPoint(
  hero: CpuBody,
  prey: CpuBody,
  errorRad: number,
): { x: number; y: number } {
  const dx = prey.x - hero.x;
  const dy = prey.y - hero.y;
  const cos = Math.cos(errorRad);
  const sin = Math.sin(errorRad);
  return {
    x: hero.x + dx * cos - dy * sin,
    y: hero.y + dx * sin + dy * cos,
  };
}

function bySlot(heroes: Iterable<CpuBody>): CpuBody[] {
  return [...heroes].sort((a, b) => a.slot - b.slot);
}

function playerCount(heroes: readonly CpuBody[]): number {
  let maxSlot = -1;
  for (const h of heroes) {
    if (h.slot > maxSlot) {maxSlot = h.slot;}
  }
  return Math.max(maxSlot + 1, heroes.length);
}

/**
 * choose_target — threat·finish·grudge·dogpile·bounty − crowd·retaliation·거리.
 * cpu_behavior.gd:182-216.
 */
export function chooseCpuTarget(slot: number, heroes: Iterable<CpuBody>, rng: MatchRng): number {
  const list = bySlot(heroes);
  const n = playerCount(list);
  const index = new Map<number, CpuBody>();
  for (const h of list) {index.set(h.slot, h);}
  const self = index.get(slot);
  if (!self) {return -1;}
  const attackerCounts = new Array<number>(n).fill(0);
  for (const other of list) {
    const t = other.target ?? -1;
    if (t >= 0 && t < n) {attackerCounts[t] += 1;}
  }
  let validTargetCount = 0;
  for (let candidate = 0; candidate < n; candidate++) {
    if (candidate !== slot && cpuTargetValid(index.get(candidate))) {validTargetCount += 1;}
  }
  let best = -1;
  let bestScore = -999;
  const recent = self.recentAttacker ?? -1;
  for (let target = 0; target < n; target++) {
    if (target === slot || !cpuTargetValid(index.get(target))) {continue;}
    if (validTargetCount >= 3 && attackerCounts[target] >= CPU_CROWD_LIMIT) {continue;}
    const targetH = index.get(target)!;
    const distance = Math.hypot(self.x - targetH.x, self.y - targetH.y);
    const threat = targetH.threat ?? 0;
    const leaderValue = clamp01(threat / 180);
    const finishability = clamp01(
      (targetH.maxHp - targetH.hp) / Math.max(1, targetH.maxHp),
    );
    const dogpile = attackerCounts[target] === 1 ? 1 : 0;
    const crowdPenalty = Math.max(0, attackerCounts[target] - 1) * CPU_SCORE_CROWD;
    const retaliation = clamp01(threat / 150);
    const grudge = recent === target ? 1 : 0;
    let score = CPU_SCORE_LEADER * leaderValue + CPU_SCORE_FINISH * finishability;
    score += CPU_SCORE_THREAT * clamp01(threat / 120);
    score += CPU_SCORE_GRUDGE * grudge + CPU_SCORE_DOGPILE * dogpile
      + CPU_SCORE_BOUNTY * clamp01((targetH.bounty ?? 0) / 80);
    score -= crowdPenalty + CPU_SCORE_RETAIL * retaliation
      + CPU_SCORE_DIST * clamp01(distance / CPU_SCORE_DIST_REF);
    score += rng.rangef(-CPU_SCORE_JITTER, CPU_SCORE_JITTER);
    if (score > bestScore) {
      bestScore = score;
      best = target;
    }
  }
  return best;
}

function fightWish(
  hero: CpuBody,
  prey: CpuBody,
  world?: CpuWorld,
): { x: number; y: number; action: string } {
  const to = dirTo(hero.x, hero.y, prey.x, prey.y);
  const dist = Math.hypot(prey.x - hero.x, prey.y - hero.y);
  const orth = orthogonal(to.x, to.y);
  const sign = hero.slot % 2 === 0 ? -1 : 1;
  const strafe = { x: orth.x * sign, y: orth.y * sign };
  const preferred = cpuPreferredRange(hero);
  if (world?.lineBlocked?.(hero.x, hero.y, prey.x, prey.y)) {
    const n = normalize(to.x * 0.35 + strafe.x, to.y * 0.35 + strafe.y);
    return { ...n, action: "FLANK" };
  }
  if (dist < preferred * 0.72) {
    const n = normalize(strafe.x * 0.75 - to.x * 0.25, strafe.y * 0.75 - to.y * 0.25);
    return { ...n, action: "DISENGAGE" };
  }
  if (dist <= preferred * 1.15) {
    const n = normalize(strafe.x * 0.88 + to.x * 0.12, strafe.y * 0.88 + to.y * 0.12);
    return { ...n, action: "HOLD_RANGE" };
  }
  const n = normalize(to.x + strafe.x * 0.20, to.y + strafe.y * 0.20);
  return { ...n, action: "CLOSE_RANGE" };
}

function zoneEscape(hero: CpuBody, zone?: CpuZone): { x: number; y: number } {
  if (!zone) {return { ...ZERO };}
  const cx = zone.x ?? ARENA_CENTER.x;
  const cy = zone.y ?? ARENA_CENTER.y;
  const zoneDistance = Math.hypot(hero.x - cx, hero.y - cy);
  const retreatRadius = Math.max(40, zone.radius - CPU_SAFE_ZONE_EDGE_BUFFER);
  if (zoneDistance <= retreatRadius) {return { ...ZERO };}
  let inward = dirTo(hero.x, hero.y, cx, cy);
  if (hypot2(inward.x, inward.y) < 0.1) {
    const ang = hero.slot * 0.7;
    inward = { x: -Math.cos(ang), y: -Math.sin(ang) };
  }
  const overrun = zoneDistance - zone.radius;
  const urgency = overrun > 0
    ? CPU_ZONE_OUT_URGENCY
    : clamp01((zoneDistance - retreatRadius) / Math.max(1, CPU_SAFE_ZONE_EDGE_BUFFER));
  const mag = 1.15 + urgency;
  return { x: inward.x * mag, y: inward.y * mag };
}

export function cpuWantUltimate(hero: CpuBody, prey: CpuBody | null): boolean {
  if (!hero.alive || hero.downed || hero.eliminated) {return false;}
  if ((hero.stunTime ?? 0) > 0 || hero.burrowed) {return false;}
  const animal = posmod(hero.animal ?? hero.slot, 12);
  const tslot = prey ? prey.slot : -1;
  let dist = 99999;
  if (prey) {dist = Math.hypot(prey.x - hero.x, prey.y - hero.y);}
  let hpRatio = 1;
  if ((hero.maxHp ?? 1) > 1) {hpRatio = hero.hp / hero.maxHp;}
  let want = false;
  switch (animal) {
    case 0: want = dist < 520; break;
    case 1: want = dist < 300; break;
    case 2: want = dist < 340; break;
    case 3: want = dist < 640 || hpRatio < 0.42; break;
    case 4: want = dist < 420; break;
    case 5: want = hpRatio < 0.55 || dist < 220; break;
    case 6: want = dist < 210; break;
    case 7: want = dist < 380 || hpRatio < 0.50; break;
    case 8: want = dist < 480; break;
    case 9: want = dist < 360; break;
    case 10: want = dist > 80 && dist < 520; break;
    case 11: want = dist < 300; break;
    default: want = dist < 420; break;
  }
  if (tslot < 0 && animal !== 5 && animal !== 7) {want = false;}
  return want;
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
  };
}

function findHero(heroes: readonly CpuBody[], slot: number): CpuBody | undefined {
  for (const h of heroes) {
    if (h.slot === slot) {return h;}
  }
  return undefined;
}

/**
 * think 주기: target_hold 감소, 만료 시 choose_target, 교전 위시 갱신.
 * 발사/궁극기/모빌리티는 매 틱 요청한다(cpu_behavior.gd:153-168).
 */
export function tickCpu(
  mind: CpuMind,
  hero: CpuBody,
  heroes: Iterable<CpuBody>,
  rng: MatchRng,
  dt: number,
  world?: CpuWorld,
): CpuMatchInput | null {
  if (!hero.alive || hero.eliminated || hero.downed) {return null;}
  if ((hero.stunTime ?? 0) > 0) {return null;}
  const bodies = bySlot(heroes).map((h) => (
    h.slot === hero.slot ? { ...h, target: mind.target, recentAttacker: mind.recentAttacker } : h
  ));
  mind.think -= dt;
  mind.targetHold = Math.max(0, mind.targetHold - dt);
  if (mind.think <= 0) {
    mind.think = CPU_THINK_MIN_SEC + rng.rangef(0, CPU_THINK_JITTER_SEC);
    const oldTarget = mind.target;
    const chosen = chooseCpuTarget(hero.slot, bodies, rng);
    const held = findHero(bodies, oldTarget);
    if (mind.targetHold <= 0 || oldTarget < 0 || !cpuTargetValid(held)) {
      mind.target = chosen;
      mind.targetHold = CPU_TARGET_HOLD_MIN_SEC + rng.rangef(0, CPU_TARGET_HOLD_JITTER_SEC);
    }
    const prey = findHero(bodies, mind.target);
    if (cpuTargetValid(prey)) {
      const wish = fightWish(hero, prey!, world);
      const scale = cpuActionSpeed(hero) * rng.rangef(CPU_MOVE_SCALE_MIN, CPU_MOVE_SCALE_MAX);
      const move = applyCpuMove(wish.x, wish.y, scale);
      const err = rng.rangef(-CPU_AIM_ERROR_RAD, CPU_AIM_ERROR_RAD);
      const aim = cpuAimPoint(hero, prey!, err);
      mind.action = wish.action;
      mind.mx = move.mx;
      mind.my = move.my;
      mind.aimX = aim.x;
      mind.aimY = aim.y;
      mind.ready = true;
    } else {
      mind.action = "HARASS";
      mind.ready = false;
    }
    const escape = zoneEscape(hero, world?.zone);
    if (hypot2(escape.x, escape.y) > 0.1) {
      const hazardCc = (hero.ccTime ?? 0) > 0 ? 0.42 : 1;
      const hazardLock = (hero.rootTime ?? 0) > 0
        ? 0.35
        : ((hero.hitstunTime ?? 0) > 0 || (hero.comboCaptureTime ?? 0) > 0 ? 0.72 : 1);
      const move = applyCpuMove(escape.x, escape.y, hazardCc * hazardLock);
      mind.mx = move.mx;
      mind.my = move.my;
      mind.action = "DODGE_WARNING";
      mind.ready = true;
    }
  }
  return applyCpu(mind, hero, bodies, rng, world);
}

/** 매 틱 버튼 — 직전 think 의 이동/조준 위에 fire/ultimate/mobility. */
export function applyCpu(
  mind: CpuMind,
  hero: CpuBody,
  heroes: Iterable<CpuBody>,
  rng: MatchRng,
  world?: CpuWorld,
): CpuMatchInput | null {
  if (!mind.ready) {return null;}
  const prey = findHero(bySlot(heroes), mind.target);
  const validPrey = cpuTargetValid(prey) ? prey! : null;
  let fire = false;
  let mobility = false;
  let ultimate = false;
  if ((hero.ultimateCharge ?? 0) >= CPU_ULTIMATE_READY && !hero.turtle) {
    if (cpuWantUltimate(hero, validPrey) && rng.chance(CPU_ULTIMATE_CHANCE)) {
      ultimate = true;
    }
  }
  if (validPrey) {
    if (cpuWantMobility(hero, validPrey, mind.action) && rng.chance(CPU_MOBILITY_CHANCE)) {
      mobility = true;
    }
    if (cpuWantFire(hero, validPrey, world) && (hero.fireCd ?? 0) <= 0) {
      fire = true;
    }
  }
  return {
    mx: mind.mx,
    my: mind.my,
    aimX: mind.aimX,
    aimY: mind.aimY,
    fire,
    ultimate,
    mobility,
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
  command(hero: CpuBody, heroes: Iterable<CpuBody>, _tick: number, zone?: CpuZone): CpuCommand | null {
    let mind = this.minds.get(hero.slot);
    if (!mind) {
      // 통합측은 틱마다 mx/my 로 속도를 다시 넣으므로, 첫 command 에서 바로 think 한다.
      mind = seedCpu(hero.slot, hero.x, hero.y);
      mind.think = 0;
      this.minds.set(hero.slot, mind);
    }
    mind.recentAttacker = hero.recentAttacker ?? mind.recentAttacker;
    const bodies = [...heroes].map((h) => {
      const other = this.minds.get(h.slot);
      return other ? { ...h, target: other.target } : h;
    });
    return tickCpu(mind, hero, bodies, this.rng, CPU_FIXED_DT, { zone });
  }
}
export const seed = seedCpu;
export const tick = tickCpu;
export const apply = applyCpu;
