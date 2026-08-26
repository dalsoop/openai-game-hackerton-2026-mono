/**
 * 코어(수정구) — 레거시 결정론 포팅. RNG·시계 없음.
 * 원본: game_world.gd(_reset_heroes 코어 스폰·_core_exposed) +
 * damage_system.gd(damage_core·streak_damage_multiplier) + match_lifecycle.gd(eliminate).
 */
import {
  ARENA_CENTER, ARENA_MARGIN, ARENA_SIZE, pointInCover, type CoverRect,
} from "./match-covers.js";

/** game_world.gd:36 CORE_MAX_HP. */
export const CORE_MAX_HP = 210;
/** game_world.gd:35 CORE_RADIUS — 코어 히트박스 반지름. */
export const CORE_RADIUS = 34;
/** game_world.gd:33-34 — 히어로 스폰(3360/1940)보다 바깥 링. */
export const SPAWN_CORE_RADIUS = { x: 3600, y: 2120 };
/** game_world.gd:23 PLAYER_COUNT — 원본은 슬롯 8개 전부에 코어를 만든다. */
export const CORE_PLAYER_COUNT = 8;
/** damage_core — 코어에 닿은 데미지 보너스 배율. */
export const CORE_DAMAGE_BONUS = 1.15;
/** damage_core — 궁극기 충전은 코어 데미지의 55% 기준 (히어로 피격은 100%). */
export const CORE_CHARGE_RATIO = 0.55;
/** damage_core — 공격자 threat 가산 비율. */
export const CORE_THREAT_RATIO = 0.52;
/** damage_core — 점수 가중치: 코어 데미지 x1.5 (히어로는 x1.0). */
export const CORE_SCORE_MULT = 1.5;
/** projectile_hit.gd:170 — 투사체가 코어에 맞으면 데미지의 78%만 적용. */
export const PROJECTILE_CORE_DAMAGE_MULT = 0.78;
/** projectile_hit.gd:235 — 존(범위 공격)이 코어를 덮으면 데미지의 72%만 적용. */
export const ZONE_CORE_DAMAGE_MULT = 0.72;
/** match_lifecycle.gd eliminate — 탈락 점수 +300. */
export const ELIMINATE_SCORE = 300;
/** match_lifecycle.gd eliminate — 공격자 bounty 를 15 깎는다 (하한 0). */
export const ELIMINATE_BOUNTY_DROP = 15;
/** arena_geometry.gd nudge_out_of_cover — 중심 방향 28px 씩 최대 24회. */
const NUDGE_STEP = 28;
const NUDGE_MAX_STEPS = 24;

export type SimCore = {
  slot: number;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  alive: boolean;
};

/** 코어 주인 히어로의 노출 판정 필드 — 통합 때 SimHero 로 합류하는 구조적 타입. */
export type CoreOwnerState = {
  alive: boolean;
  ccTime: number;
  rootTime: number;
  stunTime: number;
};

/** damage_core 가 만지는 공격자 필드 — 통합 때 SimHero 로 합류. */
export type CoreAttackerState = {
  killStreak: number;
  threat: number;
  coreDamage: number;
  score: number;
};

/** eliminate 대상 히어로 필드 — 통합 때 SimHero 로 합류. */
export type EliminateTargetState = { alive: boolean; eliminated: boolean };
/** eliminate 공격자 필드 — 통합 때 SimHero 로 합류. */
export type EliminateAttackerState = {
  bounty: number;
  eliminations: number;
  score: number;
};

/** arena_geometry.gd clamp_arena_point — radius=CORE_RADIUS 로 마진 클램프. */
function clampCorePoint(x: number, y: number): { x: number; y: number } {
  const lo = ARENA_MARGIN + CORE_RADIUS;
  return {
    x: Math.min(ARENA_SIZE.x - lo, Math.max(lo, x)),
    y: Math.min(ARENA_SIZE.y - lo, Math.max(lo, y)),
  };
}

function moveToward(x: number, y: number, tx: number, ty: number, delta: number): { x: number; y: number } {
  const dx = tx - x;
  const dy = ty - y;
  const dist = Math.hypot(dx, dy);
  if (dist <= delta || dist === 0) {return { x: tx, y: ty };}
  return { x: x + (dx / dist) * delta, y: y + (dy / dist) * delta };
}

/** 커버 안이면 중심 방향으로 밀어낸다 — nudge_out_of_cover(radius=CORE_RADIUS). */
function nudgeCoreOutOfCover(
  point: { x: number; y: number },
  covers: readonly CoverRect[],
): { x: number; y: number } {
  if (!pointInCover(point.x, point.y, covers, CORE_RADIUS)) {return point;}
  let nudged = point;
  for (let step = 0; step < NUDGE_MAX_STEPS; step += 1) {
    const moved = moveToward(nudged.x, nudged.y, ARENA_CENTER.x, ARENA_CENTER.y, NUDGE_STEP);
    nudged = clampCorePoint(moved.x, moved.y);
    if (!pointInCover(nudged.x, nudged.y, covers, CORE_RADIUS)) {return nudged;}
  }
  return clampCorePoint(ARENA_CENTER.x, ARENA_CENTER.y);
}

/**
 * 슬롯별 코어 위치 — _reset_heroes: ang = -PI/2 + TAU*slot/count 의 방사형
 * (중심 + dir * SPAWN_CORE_RADIUS) 을 clamp 후 커버 밖으로 nudge.
 */
export function coreSpawnPoint(
  slot: number,
  count: number,
  covers: readonly CoverRect[],
): { x: number; y: number } {
  const n = Math.max(1, count);
  const ang = -Math.PI * 0.5 + (Math.PI * 2 * slot) / n;
  const raw = clampCorePoint(
    ARENA_CENTER.x + Math.cos(ang) * SPAWN_CORE_RADIUS.x,
    ARENA_CENTER.y + Math.sin(ang) * SPAWN_CORE_RADIUS.y,
  );
  return nudgeCoreOutOfCover(raw, covers);
}

/** 슬롯 0..count-1 에 코어 1개씩 — HP 210 만충·alive 로 시작. */
export function spawnCores(
  covers: readonly CoverRect[],
  count: number = CORE_PLAYER_COUNT,
): SimCore[] {
  const cores: SimCore[] = [];
  for (let slot = 0; slot < count; slot += 1) {
    const p = coreSpawnPoint(slot, count, covers);
    cores.push({ slot, x: p.x, y: p.y, hp: CORE_MAX_HP, maxHp: CORE_MAX_HP, alive: true });
  }
  return cores;
}

/** damage_system.gd:9 — 1 + min(0.10, kill_streak * 0.025). */
export function streakDamageMultiplier(killStreak: number): number {
  return 1 + Math.min(0.10, killStreak * 0.025);
}

/**
 * _core_exposed — 코어가 alive 이고, 주인이 죽었거나 CC(cc/root/stun) 중일 때만
 * 피격 가능. 주인이 없으면(슬롯 범위 밖) false.
 */
export function coreExposed(core: SimCore, owner: CoreOwnerState | undefined): boolean {
  if (!core.alive || owner === undefined) {return false;}
  return !owner.alive || owner.ccTime > 0 || owner.rootTime > 0 || owner.stunTime > 0;
}

export type CoreHitOutcome = "dead" | "blocked" | "hit" | "destroyed";

export type CoreHitResult = {
  outcome: CoreHitOutcome;
  /** 배율(스트릭 x1.15) 적용 후 실제 깎인 양. blocked/dead 면 0. */
  damage: number;
  /** award_charge 에 넘길 양 = damage * 0.55 — 궁 충전 환산은 호출자 소관. */
  chargeAward: number;
  remaining: number;
};

/**
 * damage_core — 노출 아니면 core_shield_blocked(데미지 0). 노출이면
 * amount x streak x1.15 를 깎고 공격자에 threat x0.52 · core_damage · score x1.5,
 * HP 0 이하면 alive=false (core_destroyed). 탈락은 일어나지 않는다.
 */
export function damageCore(
  core: SimCore,
  owner: CoreOwnerState | undefined,
  attacker: CoreAttackerState,
  rawAmount: number,
): CoreHitResult {
  if (!core.alive) {return { outcome: "dead", damage: 0, chargeAward: 0, remaining: core.hp };}
  if (!coreExposed(core, owner)) {
    return { outcome: "blocked", damage: 0, chargeAward: 0, remaining: core.hp };
  }
  const amount = rawAmount * streakDamageMultiplier(attacker.killStreak) * CORE_DAMAGE_BONUS;
  core.hp -= amount;
  attacker.threat += amount * CORE_THREAT_RATIO;
  attacker.coreDamage += amount;
  attacker.score += amount * CORE_SCORE_MULT;
  const chargeAward = amount * CORE_CHARGE_RATIO;
  if (core.hp <= 0) {
    core.hp = 0;
    core.alive = false;
    return { outcome: "destroyed", damage: amount, chargeAward, remaining: 0 };
  }
  return { outcome: "hit", damage: amount, chargeAward, remaining: core.hp };
}

/** projectile_hit.gd:169 — dist < p.radius + CORE_RADIUS (미만, 죽은 코어 제외). */
export function projectileHitsCore(px: number, py: number, radius: number, core: SimCore): boolean {
  return core.alive && Math.hypot(px - core.x, py - core.y) < radius + CORE_RADIUS;
}

/** projectile_hit.gd:233 — dist <= z.radius + CORE_RADIUS (이하, 죽은 코어 제외). */
export function zoneCoversCore(zx: number, zy: number, radius: number, core: SimCore): boolean {
  return core.alive && Math.hypot(zx - core.x, zy - core.y) <= radius + CORE_RADIUS;
}

/**
 * match_lifecycle.gd eliminate — 코어를 부수고 히어로를 즉시 탈락시킨다.
 * 원본에선 호출처가 없는 dead code 지만 규칙 그대로 이식 (통합 때 배선 결정).
 */
export function eliminatePlayer(
  core: SimCore,
  target: EliminateTargetState,
  attacker: EliminateAttackerState,
): void {
  core.alive = false;
  core.hp = 0;
  target.alive = false;
  target.eliminated = true;
  attacker.bounty = Math.max(0, attacker.bounty - ELIMINATE_BOUNTY_DROP);
  attacker.eliminations += 1;
  attacker.score += ELIMINATE_SCORE;
}

/** Godot net_snap_parser.parse_cores 필드명 — slot·x·y·hp·max_hp·alive. */
export type CoreSnap = {
  slot: number;
  x: number;
  y: number;
  hp: number;
  max_hp: number;
  alive: boolean;
};

/** 스냅 cores 배열 직렬화 — 죽은 코어도 포함한다 (렌더가 항상 그린다). */
export function packCoresSnap(cores: readonly SimCore[]): CoreSnap[] {
  return cores.map((c) => ({
    slot: c.slot, x: c.x, y: c.y, hp: c.hp, max_hp: c.maxHp, alive: c.alive,
  }));
}

export const packCores = packCoresSnap;
export const seedCores = spawnCores;
export const applyCoreDamage = damageCore;
export const seed = spawnCores;
export const apply = damageCore;
export const tick = packCoresSnap;
export const pack = packCoresSnap;
