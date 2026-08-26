/* eslint-disable max-lines -- cpu_behavior.gd 포팅: 회복·위험 회피·타게팅을 한 모듈에 둔다 */
/**
 * CPU 조종 — 원본 cpu_behavior.gd 의 결정론 포팅.
 * 표적 점수(threat·grudge·target_hold)·교전 밴드·발사/궁극기/모빌리티 요청.
 * 슬롯별 성격 배율은 원본에 없으므로 두지 않는다. 난수는 방 시드 LCG 만 쓴다.
 */
import { ARENA_CENTER, EFFECTIVE_RANGE, HERO_RADIUS } from "./match-covers.js";
import { isSignature } from "./match-equipment.js";
import type { MatchRng } from "./match-rng.js";

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
/** 메드킷 — cpu_behavior.gd:40. ITEM_POOL 이면 생략. */
export const CPU_MEDKIT_HP = 0.5;
export const CPU_MEDKIT_CHANCE = 0.30;
/** 회복 탐색 반경 — cpu_behavior.gd:224-230. */
export const CPU_HEAL_HP_SKIP = 0.65;
export const CPU_HEAL_R_BASE = 700;
export const CPU_HEAL_R_EMPTY = 980;
export const CPU_HEAL_R_LOW = 1190;
export const CPU_HEAL_R_CRIT = 1750;
export const CPU_HEAL_SIG_BONUS = 140;
/** 오브·타워·크레이트 탐색 — cpu_behavior.gd:85-103. */
export const CPU_ORB_CHANCE = 0.55;
export const CPU_ORB_FIGHT_CAP = 520;
export const CPU_TOWER_CHANCE = 0.42;
export const CPU_TOWER_FIGHT_CAP = 780;
export const CPU_CRATE_CHANCE = 0.28;
export const CPU_CRATE_FIGHT_CAP = 460;
export const CPU_CRATE_NEAR = 480;
export const CPU_ORB_NEAR = 420;
/** 위험 반경 패딩 — cpu_behavior.gd:263,310. */
export const CPU_HAZARD_PAD = 65;
export const CPU_MINE_PAD = 45;
export const CPU_WALL_SWEEP_CAP = 480;
export const CPU_ITEM_POOL_MODE = "item";
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
  equipmentCd?: number;
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
  medkits?: number;
  heldItem?: string;
};

export type CpuFields = {
  target: number;
  targetHold: number;
  think: number;
  action: string;
  recentAttacker: number;
  crateTarget: number;
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
  use: boolean;
};

export type CpuCommand = CpuMatchInput;

export type CpuPickup = {
  x: number; y: number; active: boolean; equipment?: string; gunId?: string;
};
export type CpuMark = { x: number; y: number; alive: boolean };
export type CpuOrb = { x: number; y: number; active?: boolean; arm?: number };
export type CpuWarn = {
  x: number; y: number; radius: number; owner: number; delay: number;
  applied?: boolean; warningDuration?: number;
};
export type CpuArc = {
  owner: number; arc?: boolean; landingX: number; landingY: number;
  splash: number; ttl: number; maxTtl?: number;
};
export type CpuDeploy = {
  owner: number; type?: string; x: number; y: number; armTime?: number;
  blastRadius?: number; triggerRadius?: number; triggered?: boolean;
  travelX?: number; travelY?: number; dirX?: number; dirY?: number;
  speed?: number; lifetime?: number; halfLength?: number;
};

export type CpuWorld = {
  zone?: CpuZone;
  lineBlocked?: (ax: number, ay: number, bx: number, by: number) => boolean;
  pickups?: readonly CpuPickup[];
  crates?: readonly CpuMark[];
  crateOrbs?: readonly CpuOrb[];
  midTower?: CpuMark;
  warnZones?: readonly CpuWarn[];
  projectiles?: readonly CpuArc[];
  deployables?: readonly CpuDeploy[];
  mode?: string;
};

function clamp01(n: number): number {
  return Math.min(1, Math.max(0, n));
}

function normalize(x: number, y: number): { x: number; y: number } {
  const d = Math.hypot(x, y);
  if (d <= 1e-8) {return { x: 0, y: 0 };}
  return { x: x / d, y: y / d };
}

export function cpuDirTo(ax: number, ay: number, bx: number, by: number): { x: number; y: number } {
  return normalize(bx - ax, by - ay);
}

export function cpuHypot2(x: number, y: number): number {
  return x * x + y * y;
}

export function cpuOrthogonal(x: number, y: number): { x: number; y: number } {
  return { x: -y, y: x };
}

export function cpuFind(heroes: readonly CpuBody[], slot: number): CpuBody | undefined {
  for (const h of heroes) {
    if (h.slot === slot) {return h;}
  }
  return undefined;
}

export function cpuTargetValid(hero: CpuBody | undefined): hero is CpuBody {
  if (!hero) {return false;}
  return hero.alive && !hero.eliminated;
}

/** SimHero 생성 시 CPU 필드 — game_world.gd:270. */
export function cpuSeedFields(slot: number): CpuFields {
  return {
    target: -1,
    targetHold: 0,
    think: CPU_THINK_SEED_BASE + slot * CPU_THINK_SEED_SLOT,
    action: "HARASS",
    recentAttacker: -1,
    crateTarget: -1,
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

/** cc·루트·히트스턴 배율 — 회복/위험 이동. 공격 락은 넣지 않는다. */
export function cpuCcLockScale(hero: CpuBody): number {
  const ccSpeed = (hero.ccTime ?? 0) > 0 ? 0.42 : 1;
  if ((hero.rootTime ?? 0) > 0) {return ccSpeed * 0.35;}
  if ((hero.hitstunTime ?? 0) > 0 || (hero.comboCaptureTime ?? 0) > 0) {return ccSpeed * 0.72;}
  return ccSpeed;
}

export function cpuActionSpeed(hero: CpuBody): number {
  let actionSpeed = (hero.attackLockTime ?? 0) > 0 ? 0.76 : 1;
  if (hero.chargingSkill) {actionSpeed *= 0.62;}
  return cpuCcLockScale(hero) * actionSpeed;
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

function attackerCountsOf(list: readonly CpuBody[], n: number): number[] {
  const counts = new Array<number>(n).fill(0);
  for (const other of list) {
    const t = other.target ?? -1;
    if (t >= 0 && t < n) {counts[t] += 1;}
  }
  return counts;
}

function validTargetCountOf(
  index: Map<number, CpuBody>,
  n: number,
  slot: number,
): number {
  let valid = 0;
  for (let candidate = 0; candidate < n; candidate++) {
    if (candidate !== slot && cpuTargetValid(index.get(candidate))) {valid += 1;}
  }
  return valid;
}

/**
 * choose_target — threat·finish·grudge·dogpile·bounty − crowd·retaliation·거리.
 * cpu_behavior.gd:182-216.
 */
function scoreCpuTarget(
  self: CpuBody,
  targetH: CpuBody,
  target: number,
  attackerCounts: number[],
  recent: number,
  rng: MatchRng,
): number {
  const distance = Math.hypot(self.x - targetH.x, self.y - targetH.y);
  const threat = targetH.threat ?? 0;
  const finishability = clamp01((targetH.maxHp - targetH.hp) / Math.max(1, targetH.maxHp));
  const dogpile = attackerCounts[target] === 1 ? 1 : 0;
  const crowdPenalty = Math.max(0, attackerCounts[target] - 1) * CPU_SCORE_CROWD;
  let score = CPU_SCORE_LEADER * clamp01(threat / 180) + CPU_SCORE_FINISH * finishability;
  score += CPU_SCORE_THREAT * clamp01(threat / 120);
  score += CPU_SCORE_GRUDGE * (recent === target ? 1 : 0) + CPU_SCORE_DOGPILE * dogpile
    + CPU_SCORE_BOUNTY * clamp01((targetH.bounty ?? 0) / 80);
  score -= crowdPenalty + CPU_SCORE_RETAIL * clamp01(threat / 150)
    + CPU_SCORE_DIST * clamp01(distance / CPU_SCORE_DIST_REF);
  return score + rng.rangef(-CPU_SCORE_JITTER, CPU_SCORE_JITTER);
}

export function chooseCpuTarget(slot: number, heroes: Iterable<CpuBody>, rng: MatchRng): number {
  const list = bySlot(heroes);
  const n = playerCount(list);
  const index = new Map<number, CpuBody>();
  for (const h of list) {index.set(h.slot, h);}
  const self = index.get(slot);
  if (!self) {return -1;}
  const attackerCounts = attackerCountsOf(list, n);
  const validTargetCount = validTargetCountOf(index, n, slot);
  let best = -1;
  let bestScore = -999;
  const recent = self.recentAttacker ?? -1;
  for (let target = 0; target < n; target++) {
    const targetH = index.get(target);
    if (target === slot || !cpuTargetValid(targetH)) {continue;}
    if (validTargetCount >= 3 && attackerCounts[target] >= CPU_CROWD_LIMIT) {continue;}
    const score = scoreCpuTarget(self, targetH, target, attackerCounts, recent, rng);
    if (score > bestScore) {
      bestScore = score;
      best = target;
    }
  }
  return best;
}

/** SafeZoneState 처럼 radius 만 있는 인자는 CpuWorld.zone 으로 감싼다. */
export function asCpuWorld(arg?: CpuZone | CpuWorld): CpuWorld | undefined {
  if (!arg) {return undefined;}
  const w = arg as CpuWorld;
  if (typeof (arg as CpuZone).radius === "number" && w.zone === undefined && w.pickups === undefined
    && w.crates === undefined && w.warnZones === undefined && w.deployables === undefined
    && w.midTower === undefined && w.crateOrbs === undefined && w.projectiles === undefined
    && w.lineBlocked === undefined) {
    return { zone: arg as CpuZone };
  }
  return w;
}

function healRadius(ratio: number, empty: boolean): number {
  if (ratio <= 0.30) {return CPU_HEAL_R_CRIT;}
  if (ratio <= 0.48) {return CPU_HEAL_R_LOW;}
  return empty ? CPU_HEAL_R_EMPTY : CPU_HEAL_R_BASE;
}

/** best_health_pickup — cpu_behavior.gd:218-246. */
export function bestHealthPickup(hero: CpuBody, world?: CpuWorld): number {
  if (!world?.pickups) {return -1;}
  const list = world.pickups;
  const ratio = hero.hp / Math.max(1, hero.maxHp);
  const empty = world.mode === CPU_ITEM_POOL_MODE && !hero.heldItem;
  if (ratio > CPU_HEAL_HP_SKIP && !empty) {return -1;}
  const radius = healRadius(ratio, empty);
  let best = -1;
  let bestD = radius;
  for (let i = 0; i < list.length; i++) {
    const p = list[i];
    if (!p.active) {continue;}
    let d = Math.hypot(hero.x - p.x, hero.y - p.y);
    if (d >= radius) {continue;}
    const id = p.equipment ?? p.gunId ?? "";
    if (id !== "" && isSignature(hero.slot, id)) {d = Math.max(0, d - CPU_HEAL_SIG_BONUS);}
    if (d >= bestD) {continue;}
    bestD = d;
    best = i;
  }
  return best;
}

export function cpuWantMedkit(hero: CpuBody, rng: MatchRng, world?: CpuWorld): boolean {
  if (world?.mode === CPU_ITEM_POOL_MODE) {return false;}
  if ((hero.medkits ?? 0) <= 0) {return false;}
  if (hero.hp >= hero.maxHp * CPU_MEDKIT_HP) {return false;}
  return rng.chance(CPU_MEDKIT_CHANCE);
}

export function nearestAlive(x: number, y: number, marks: readonly CpuMark[], cap: number): number {
  let best = -1;
  let bestD = cap;
  for (let i = 0; i < marks.length; i++) {
    if (!marks[i].alive) {continue;}
    const d = Math.hypot(x - marks[i].x, y - marks[i].y);
    if (d >= bestD) {continue;}
    bestD = d;
    best = i;
  }
  return best;
}

export function nearestOrb(x: number, y: number, orbs: readonly CpuOrb[]): number {
  let best = -1;
  let bestD = CPU_ORB_NEAR;
  for (let i = 0; i < orbs.length; i++) {
    if (orbs[i].active === false || (orbs[i].arm ?? 0) > 0) {continue;}
    const d = Math.hypot(x - orbs[i].x, y - orbs[i].y);
    if (d >= bestD) {continue;}
    bestD = d;
    best = i;
  }
  return best;
}

export function cpuWantTowerFire(hero: CpuBody, action: string, tower?: CpuMark): boolean {
  if (action !== "SEEK_TOWER" || (hero.fireCd ?? 0) > 0) {return false;}
  if (!tower?.alive) {return false;}
  return Math.hypot(hero.x - tower.x, hero.y - tower.y) < cpuNormalReach(hero);
}

export function cpuWantCrateFire(
  hero: CpuBody, action: string, crate: CpuMark | undefined, world?: CpuWorld,
): boolean {
  if (action !== "SEEK_CRATE" || (hero.fireCd ?? 0) > 0 || !crate?.alive) {return false;}
  if (Math.hypot(hero.x - crate.x, hero.y - crate.y) >= cpuNormalReach(hero)) {return false;}
  return !world?.lineBlocked?.(hero.x, hero.y, crate.x, crate.y);
}

function fallbackDir(kind: "r" | "d" | "l", slot: number, mul: number): { x: number; y: number } {
  const a = slot * mul;
  if (kind === "d") {return { x: -Math.sin(a), y: Math.cos(a) };}
  if (kind === "l") {return { x: -Math.cos(a), y: -Math.sin(a) };}
  return { x: Math.cos(a), y: Math.sin(a) };
}

function unitAway(
  fromX: number, fromY: number, hero: CpuBody, owner: number,
  bodies: readonly CpuBody[], kind: "r" | "d" | "l", mul: number,
): { x: number; y: number } {
  let a = cpuDirTo(fromX, fromY, hero.x, hero.y);
  if (cpuHypot2(a.x, a.y) >= 0.1) {return a;}
  const o = cpuFind(bodies, owner);
  if (o) {
    a = cpuDirTo(o.x, o.y, hero.x, hero.y);
    if (cpuHypot2(a.x, a.y) >= 0.1) {return a;}
  }
  return fallbackDir(kind, hero.slot, mul);
}

function warnPush(hero: CpuBody, z: CpuWarn, bodies: readonly CpuBody[]): { x: number; y: number } {
  if (z.owner === hero.slot || z.applied || z.delay <= 0) {return { x: 0, y: 0 };}
  const dangerR = z.radius + HERO_RADIUS + CPU_HAZARD_PAD;
  const dist = Math.hypot(hero.x - z.x, hero.y - z.y);
  if (dist >= dangerR) {return { x: 0, y: 0 };}
  const away = unitAway(z.x, z.y, hero, z.owner, bodies, "r", 1.7);
  const warnDur = Math.max(0.01, z.warningDuration ?? z.delay);
  const urgency = 1 - clamp01(z.delay / warnDur);
  const mag = 1 - dist / dangerR + urgency * 1.25;
  return { x: away.x * mag, y: away.y * mag };
}

function arcPush(hero: CpuBody, p: CpuArc, bodies: readonly CpuBody[]): { x: number; y: number } {
  if (p.owner === hero.slot || !p.arc) {return { x: 0, y: 0 };}
  const dangerR = p.splash + HERO_RADIUS + CPU_HAZARD_PAD;
  const dist = Math.hypot(hero.x - p.landingX, hero.y - p.landingY);
  if (dist >= dangerR) {return { x: 0, y: 0 };}
  const away = unitAway(p.landingX, p.landingY, hero, p.owner, bodies, "d", 1.3);
  const flight = Math.max(0.01, p.maxTtl ?? p.ttl);
  const urgency = 1 - clamp01(p.ttl / flight);
  const mag = 1 - dist / dangerR + urgency * 1.25;
  return { x: away.x * mag, y: away.y * mag };
}

function wallSweepHit(d: CpuDeploy, fwd: number, sideDot: number): boolean {
  const sweep = Math.min((d.speed ?? 0) * (d.lifetime ?? 0), CPU_WALL_SWEEP_CAP);
  if (fwd < -HERO_RADIUS || fwd > sweep + HERO_RADIUS) {return false;}
  return Math.abs(sideDot) <= (d.halfLength ?? 0) + HERO_RADIUS + CPU_MINE_PAD;
}

function wallDodgeSign(slot: number, sideDot: number): number {
  if (Math.abs(sideDot) < 8) {return slot % 2 === 0 ? 1 : -1;}
  return sideDot >= 0 ? 1 : -1;
}

function wallPush(hero: CpuBody, d: CpuDeploy): { x: number; y: number } {
  const forward = normalize(d.travelX ?? 1, d.travelY ?? 0);
  const side = normalize(d.dirX ?? 0, d.dirY ?? 1);
  const rx = hero.x - d.x;
  const ry = hero.y - d.y;
  const sideDot = rx * side.x + ry * side.y;
  if (!wallSweepHit(d, rx * forward.x + ry * forward.y, sideDot)) {return { x: 0, y: 0 };}
  const sign = wallDodgeSign(hero.slot, sideDot);
  const mag = (d.armTime ?? 0) > 0 ? 1.15 : 1.75;
  return { x: side.x * sign * mag, y: side.y * sign * mag };
}

function minePush(hero: CpuBody, d: CpuDeploy, bodies: readonly CpuBody[]): { x: number; y: number } {
  if ((d.armTime ?? 0) > 0) {return { x: 0, y: 0 };}
  const rawR = d.triggered ? (d.blastRadius ?? 0) : (d.triggerRadius ?? 0);
  const dangerR = rawR + HERO_RADIUS + CPU_MINE_PAD;
  const dist = Math.hypot(hero.x - d.x, hero.y - d.y);
  if (dist >= dangerR) {return { x: 0, y: 0 };}
  const away = unitAway(d.x, d.y, hero, d.owner, bodies, "l", 1.1);
  const urgency = d.triggered ? 1.3 : 0.55;
  const mag = 1 - dist / dangerR + urgency;
  return { x: away.x * mag, y: away.y * mag };
}

function deployPush(hero: CpuBody, d: CpuDeploy, bodies: readonly CpuBody[]): { x: number; y: number } {
  if (d.owner === hero.slot) {return { x: 0, y: 0 };}
  if (d.type === "wall") {return wallPush(hero, d);}
  return minePush(hero, d, bodies);
}

function safeZonePush(hero: CpuBody, zone?: CpuZone): { x: number; y: number } {
  if (!zone) {return { x: 0, y: 0 };}
  const cx = zone.x ?? ARENA_CENTER.x;
  const cy = zone.y ?? ARENA_CENTER.y;
  const zoneDistance = Math.hypot(hero.x - cx, hero.y - cy);
  const retreatRadius = Math.max(40, zone.radius - CPU_SAFE_ZONE_EDGE_BUFFER);
  if (zoneDistance <= retreatRadius) {return { x: 0, y: 0 };}
  let inward = cpuDirTo(hero.x, hero.y, cx, cy);
  if (cpuHypot2(inward.x, inward.y) < 0.1) {inward = fallbackDir("l", hero.slot, 0.7);}
  const overrun = zoneDistance - zone.radius;
  const urgency = overrun > 0
    ? CPU_ZONE_OUT_URGENCY
    : clamp01((zoneDistance - retreatRadius) / Math.max(1, CPU_SAFE_ZONE_EDGE_BUFFER));
  const mag = 1.15 + urgency;
  return { x: inward.x * mag, y: inward.y * mag };
}

function addPush(acc: { x: number; y: number }, p: { x: number; y: number }): void {
  acc.x += p.x;
  acc.y += p.y;
}

/** hazard_escape_vector — cpu_behavior.gd:254-330. */
export function hazardEscapeVector(
  hero: CpuBody, world: CpuWorld | undefined, bodies: readonly CpuBody[],
): { x: number; y: number } {
  if (!hero.alive) {return { x: 0, y: 0 };}
  const escape = { x: 0, y: 0 };
  for (const z of world?.warnZones ?? []) {addPush(escape, warnPush(hero, z, bodies));}
  for (const p of world?.projectiles ?? []) {addPush(escape, arcPush(hero, p, bodies));}
  for (const d of world?.deployables ?? []) {addPush(escape, deployPush(hero, d, bodies));}
  addPush(escape, safeZonePush(hero, world?.zone));
  if (cpuHypot2(escape.x, escape.y) <= 0.1) {return { x: 0, y: 0 };}
  return normalize(escape.x, escape.y);
}

