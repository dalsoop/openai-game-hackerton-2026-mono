/* eslint-disable max-lines -- 지뢰·이동벽 포팅: 설치·틱·폭발이 한 파일 */
/**
 * 설치물(지뢰·이동벽) — 원본 sim/deployable_system.gd 의 결정론 포팅. RNG·시계 없음.
 * 원본은 지뢰 폭발을 proj.add_zone, 벽 히트를 dmg.damage_hero/damage_core 로 직접 쏘지만
 * 이 모듈은 이벤트로 반환한다 — 배선측이 존/피해 파이프라인(applyScoredDamage 등)에 잇는다.
 * 히어로 이동측 벽 충돌·스냅 직렬화는 match-deployable-hit.ts 에 있다.
 */
import {
  ARENA_MARGIN, ARENA_SIZE, HERO_RADIUS, pointInCover, resolveCoverMotion,
} from "./match-covers.js";
import type { CoverRect } from "./match-covers.js";
import { addEffect, type EffectStore } from "./match-effects.js";

/** 코어 반지름 — game_world.gd:35 CORE_RADIUS. */
export const CORE_RADIUS = 34;
/** 지뢰 기본값 — place_mine 기본 인수(deployable_system.gd:9). */
export const MINE_ARM_TIME = 0.62;
export const MINE_LIFETIME = 8.0;
export const MINE_FUSE_TIME = 0.38;
/** trigger_radius = min(126, blast_radius * 0.72). */
export const MINE_TRIGGER_RADIUS_MAX = 126;
export const MINE_TRIGGER_RADIUS_RATIO = 0.72;
export const MINE_CC_TIME = 0.40;
export const MINE_CC_TIME_ULTIMATE = 0.55;
export const MINE_KNOCKBACK = 140;
export const MINE_KNOCKBACK_ULTIMATE = 175;
/** 비궁극 지뢰 동시 상한 — 도달 시 가장 오래된 것(index 0) 제거. */
export const MINE_MAX_PER_OWNER = 2;
/** 지뢰/벽 설치 클램프 — ARENA_MARGIN + 18 / + 26. */
export const MINE_CLAMP_INSET = 18;
export const WALL_CLAMP_INSET = 26;
export const WALL_ARM_TIME = 0.18;
/** 벽 진행 정지 경계 — ARENA_MARGIN + 24. */
export const WALL_STOP_INSET = 24;
/** 벽 커버 충돌 판정 패딩(deployable_system.gd:122). */
export const WALL_COVER_PADDING = 34;
export const WALL_HIT_CC_TIME = 0.32;
/** 벽 재히트 방지 쿨다운 — 스윕 히트·이동측 히트 공용. */
export const WALL_HIT_COOLDOWN = 0.78;
/** 벽 코어 피해 계수 — damage * 0.62. */
export const WALL_CORE_DAMAGE_RATIO = 0.62;
/** WALL SLAM 넉백 origin — 대상 위치에서 전진 방향 반대로 34px. */
export const WALL_SLAM_ORIGIN_BACK = 34;
/** 스윕 전방/후방 여유 — forward ∈ [-HERO_R-10, travel+HERO_R+14]. */
export const WALL_SWEEP_BACK_MARGIN = 10;
export const WALL_SWEEP_FRONT_MARGIN = 14;
/** 지뢰 폭발 zone 지연 — 원본 proj.add_zone(..., 0.01, ...). */
export const MINE_ZONE_DELAY = 0.01;
/** 지뢰 fizzle 이펙트 반경(원본 42; 벽 만료는 half_length). */
export const MINE_FIZZLE_RADIUS = 42;
const WALL_FIZZLE_RADIUS = 58;

type DeployableBase = {
  id: number;
  owner: number;
  x: number;
  y: number;
  armTime: number;
  armDuration: number;
  lifetime: number;
  maxLifetime: number;
};

export type MineDeployable = DeployableBase & {
  type: "mine";
  damage: number;
  blastRadius: number;
  triggerRadius: number;
  triggered: boolean;
  fuseTime: number;
  fuseDuration: number;
  ccTime: number;
  knockback: number;
  ultimate: boolean;
  /** 미사용 -1. armed 후 매 tick 차감, [-0.5, 0] 도달 시 강제 트리거. */
  autoDetonate: number;
};

export type WallDeployable = DeployableBase & {
  type: "wall";
  /** 벽 축 방향 — travel_direction.orthogonal() = (ty, -tx). */
  dirX: number;
  dirY: number;
  travelX: number;
  travelY: number;
  halfLength: number;
  speed: number;
  damage: number;
  knockback: number;
  hitSlots: number[];
  hitCores: number[];
};

export type Deployable = MineDeployable | WallDeployable;

export type DeployableState = { deployables: Deployable[]; nextEntityId: number };

/** 지뢰 트리거·벽 스윕 대상 히어로 — 통합 시 SimHero 로 합류(wallHitCd 필드 추가 필요). */
export type DeployableHero = {
  slot: number;
  x: number;
  y: number;
  alive: boolean;
  wallHitCd: number;
};

/** 코어 대상 — exposed 는 원본 _core_exposed(slot) 판정 결과를 호출측이 넣는다. */
export type DeployableCore = {
  slot: number;
  x: number;
  y: number;
  alive: boolean;
  exposed: boolean;
};

export type DeployablePlacer = { slot: number; x: number; y: number };

export type DeployableEvent =
  | { kind: "fizzle"; x: number; y: number; radius: number; label: string }
  | { kind: "minePlaced"; owner: number; x: number; y: number; ultimate: boolean }
  | { kind: "wallPlaced"; owner: number; x: number; y: number; halfLength: number; speed: number }
  | { kind: "mineTriggered"; owner: number; x: number; y: number; triggerRadius: number; fuseDuration: number }
  | {
      kind: "mineExplode"; owner: number; x: number; y: number; blastRadius: number;
      damage: number; damageType: "ultimate" | "equipment"; ccTime: number;
      knockback: number; label: string; ultimate: boolean;
    }
  | { kind: "wallCrash"; x: number; y: number; halfLength: number }
  | {
      kind: "wallHitHero"; owner: number; target: number; damage: number;
      ccTime: number; knockback: number; originX: number; originY: number;
    }
  | { kind: "wallHitCore"; owner: number; target: number; damage: number };

/** game_world.gd reset: next_entity_id = 100. */
export const DEPLOYABLE_NEXT_ID_RESET = 100;

/** nextEntityId 는 원본 w.next_entity_id 공유 카운터 — 통합 시 시뮬 전역 카운터와 합친다. */
export function createDeployableState(nextEntityId = DEPLOYABLE_NEXT_ID_RESET): DeployableState {
  return { deployables: [], nextEntityId };
}

/** Sim 생성 시 설치물 상태 — 원본 reset 의 next_entity_id=100. */
export function seedDeployables(nextEntityId = DEPLOYABLE_NEXT_ID_RESET): DeployableState {
  return createDeployableState(nextEntityId);
}

export function deployableHeroSeedFields(): Pick<DeployableHero, "wallHitCd"> {
  return { wallHitCd: 0 };
}

/** damage_system.gd:19 attack_direction — 영벡터면 RIGHT, 아니면 정규화. */
export function attackDirection(x: number, y: number): { x: number; y: number } {
  const len = Math.hypot(x, y);
  if (len <= 0) {return { x: 1, y: 0 };}
  return { x: x / len, y: y / len };
}

function clampInset(v: number, size: number, inset: number): number {
  return Math.min(size - ARENA_MARGIN - inset, Math.max(ARENA_MARGIN + inset, v));
}

function sortedBySlot<T extends { slot: number }>(items: Iterable<T>): T[] {
  return [...items].sort((a, b) => a.slot - b.slot);
}

/**
 * 원본 place_mine 의 상한 컷 — owner 의 "비궁극" 설치물 2개 이상이면 index 0 제거.
 * 원본은 type 필터 없이 get("ultimate", false) 만 보므로 벽도 후보에 포함된다(그대로 이식).
 */
function cullOwnerMines(
  state: DeployableState, owner: number, events: DeployableEvent[], fx?: EffectStore,
): void {
  const indices: number[] = [];
  state.deployables.forEach((d, i) => {
    if (d.owner === owner && !(d.type === "mine" && d.ultimate)) {indices.push(i);}
  });
  if (indices.length < MINE_MAX_PER_OWNER) {return;}
  const removed = state.deployables[indices[0]];
  events.push({ kind: "fizzle", x: removed.x, y: removed.y, radius: MINE_FIZZLE_RADIUS, label: "REPLACED" });
  addEffect(fx, {
    kind: "mine_fizzle", x: removed.x, y: removed.y, radius: 42, duration: 0.24,
    color: "#8ca0b8", label: "REPLACED",
  });
  state.deployables.splice(indices[0], 1);
}

export type MinePlaceOptions = {
  damage: number;
  blastRadius: number;
  armTime?: number;
  lifetime?: number;
  fuseTime?: number;
  ultimate?: boolean;
  autoDetonate?: number;
};

/** deployable_system.gd:9-36 place_mine. desired 위치는 커버 슬라이딩 후 마진+18 클램프. */
export function placeMine(
  state: DeployableState,
  owner: DeployablePlacer,
  desiredX: number,
  desiredY: number,
  covers: readonly CoverRect[],
  opts: MinePlaceOptions,
  fx?: EffectStore,
): DeployableEvent[] {
  const events: DeployableEvent[] = [];
  const slid = resolveCoverMotion(owner.x, owner.y, desiredX - owner.x, desiredY - owner.y, covers);
  const x = clampInset(slid.x, ARENA_SIZE.x, MINE_CLAMP_INSET);
  const y = clampInset(slid.y, ARENA_SIZE.y, MINE_CLAMP_INSET);
  const ultimate = opts.ultimate ?? false;
  if (!ultimate) {cullOwnerMines(state, owner.slot, events, fx);}
  const armTime = opts.armTime ?? MINE_ARM_TIME;
  const lifetime = opts.lifetime ?? MINE_LIFETIME;
  const fuseTime = opts.fuseTime ?? MINE_FUSE_TIME;
  state.deployables.push({
    id: state.nextEntityId, type: "mine", owner: owner.slot, x, y,
    damage: opts.damage, blastRadius: opts.blastRadius,
    triggerRadius: Math.min(MINE_TRIGGER_RADIUS_MAX, opts.blastRadius * MINE_TRIGGER_RADIUS_RATIO),
    armTime, armDuration: armTime, lifetime, maxLifetime: lifetime,
    triggered: false, fuseTime, fuseDuration: fuseTime,
    ccTime: ultimate ? MINE_CC_TIME_ULTIMATE : MINE_CC_TIME,
    knockback: ultimate ? MINE_KNOCKBACK_ULTIMATE : MINE_KNOCKBACK,
    ultimate, autoDetonate: opts.autoDetonate ?? -1,
  });
  state.nextEntityId += 1;
  events.push({ kind: "minePlaced", owner: owner.slot, x, y, ultimate });
  addEffect(fx, {
    kind: "mine_place", x, y, radius: 48, duration: 0.28, color: "#ff765f", label: "MINE",
  });
  return events;
}

export type WallPlaceOptions = {
  halfLength: number;
  lifetime: number;
  speed: number;
  damage: number;
  knockback: number;
};

/** deployable_system.gd:38-57 place_bounce_wall — owner 당 1개(기존 전부 제거 후 설치). */
export function placeBounceWall(
  state: DeployableState,
  owner: DeployablePlacer,
  desiredX: number,
  desiredY: number,
  facingX: number,
  facingY: number,
  covers: readonly CoverRect[],
  opts: WallPlaceOptions,
  fx?: EffectStore,
): DeployableEvent[] {
  const events: DeployableEvent[] = [];
  for (let i = state.deployables.length - 1; i >= 0; i -= 1) {
    const d = state.deployables[i];
    if (d.owner !== owner.slot || d.type !== "wall") {continue;}
    events.push({ kind: "fizzle", x: d.x, y: d.y, radius: WALL_FIZZLE_RADIUS, label: "REPLACED" });
    addEffect(fx, {
      kind: "mine_fizzle", x: d.x, y: d.y, radius: 58, duration: 0.26,
      color: "#8de1ff", label: "REPLACED",
    });
    state.deployables.splice(i, 1);
  }
  const slid = resolveCoverMotion(owner.x, owner.y, desiredX - owner.x, desiredY - owner.y, covers);
  const travel = attackDirection(facingX, facingY);
  const x = clampInset(slid.x, ARENA_SIZE.x, WALL_CLAMP_INSET);
  const y = clampInset(slid.y, ARENA_SIZE.y, WALL_CLAMP_INSET);
  state.deployables.push({
    id: state.nextEntityId, type: "wall", owner: owner.slot, x, y,
    // Godot Vector2.orthogonal() = (y, -x)
    dirX: travel.y, dirY: -travel.x, travelX: travel.x, travelY: travel.y,
    halfLength: opts.halfLength, speed: opts.speed,
    damage: opts.damage, knockback: opts.knockback,
    armTime: WALL_ARM_TIME, armDuration: WALL_ARM_TIME,
    lifetime: opts.lifetime, maxLifetime: opts.lifetime, hitSlots: [], hitCores: [],
  });
  state.nextEntityId += 1;
  events.push({ kind: "wallPlaced", owner: owner.slot, x, y, halfLength: opts.halfLength, speed: opts.speed });
  addEffect(fx, {
    kind: "charge_release", x, y, radius: opts.halfLength, duration: 0.18,
    color: "#8de1ff", label: "INCOMING", dx: travel.x, dy: travel.y,
  });
  return events;
}

/** deployable_system.gd:92-103 mine_has_target — 적 영웅/노출 코어가 트리거 반경 안인가. */
export function mineHasTarget(
  mine: MineDeployable,
  heroes: ReadonlyMap<number, DeployableHero>,
  cores: ReadonlyMap<number, DeployableCore>,
): boolean {
  for (const hero of heroes.values()) {
    if (hero.slot === mine.owner || !hero.alive) {continue;}
    if (Math.hypot(hero.x - mine.x, hero.y - mine.y) <= mine.triggerRadius + HERO_RADIUS) {return true;}
  }
  for (const core of cores.values()) {
    if (core.slot === mine.owner || !core.alive || !core.exposed) {continue;}
    if (Math.hypot(core.x - mine.x, core.y - mine.y) <= mine.triggerRadius + CORE_RADIUS) {return true;}
  }
  return false;
}

function sweepWallHeroes(
  wall: WallDeployable,
  heroes: ReadonlyMap<number, DeployableHero>,
  oldX: number,
  oldY: number,
  travelDist: number,
  events: DeployableEvent[],
  fx?: EffectStore,
): void {
  const f = attackDirection(wall.travelX, wall.travelY);
  const s = attackDirection(wall.dirX, wall.dirY);
  for (const hero of sortedBySlot(heroes.values())) {
    if (hero.slot === wall.owner || wall.hitSlots.includes(hero.slot) || !hero.alive) {continue;}
    const rx = hero.x - oldX;
    const ry = hero.y - oldY;
    const fd = rx * f.x + ry * f.y;
    const sd = Math.abs(rx * s.x + ry * s.y);
    if (fd < -HERO_RADIUS - WALL_SWEEP_BACK_MARGIN
      || fd > travelDist + HERO_RADIUS + WALL_SWEEP_FRONT_MARGIN
      || sd > wall.halfLength + HERO_RADIUS) {continue;}
    wall.hitSlots.push(hero.slot);
    hero.wallHitCd = WALL_HIT_COOLDOWN;
    events.push({
      kind: "wallHitHero", owner: wall.owner, target: hero.slot, damage: wall.damage,
      ccTime: WALL_HIT_CC_TIME, knockback: wall.knockback,
      originX: hero.x - f.x * WALL_SLAM_ORIGIN_BACK, originY: hero.y - f.y * WALL_SLAM_ORIGIN_BACK,
    });
    addEffect(fx, {
      kind: "wall_impact", x: hero.x, y: hero.y, radius: 102, duration: 0.30,
      color: "#8de1ff", label: "SLAM", dx: f.x, dy: f.y,
    });
  }
}

function sweepWallCores(
  wall: WallDeployable,
  cores: ReadonlyMap<number, DeployableCore>,
  oldX: number,
  oldY: number,
  travelDist: number,
  events: DeployableEvent[],
): void {
  const f = attackDirection(wall.travelX, wall.travelY);
  const s = attackDirection(wall.dirX, wall.dirY);
  for (const core of sortedBySlot(cores.values())) {
    if (core.slot === wall.owner || wall.hitCores.includes(core.slot) || !core.alive || !core.exposed) {continue;}
    const rx = core.x - oldX;
    const ry = core.y - oldY;
    const fd = rx * f.x + ry * f.y;
    if (fd < -CORE_RADIUS || fd > travelDist + CORE_RADIUS
      || Math.abs(rx * s.x + ry * s.y) > wall.halfLength + CORE_RADIUS) {continue;}
    wall.hitCores.push(core.slot);
    events.push({
      kind: "wallHitCore", owner: wall.owner, target: core.slot,
      damage: wall.damage * WALL_CORE_DAMAGE_RATIO,
    });
  }
}

/** deployable_system.gd:59-90 moving_wall_sweep — AABB(전방/측방 거리) 스윕, 대상당 1회. */
export function movingWallSweep(
  wall: WallDeployable,
  heroes: ReadonlyMap<number, DeployableHero>,
  cores: ReadonlyMap<number, DeployableCore>,
  oldX: number,
  oldY: number,
  events: DeployableEvent[],
  fx?: EffectStore,
): void {
  const travelDist = Math.hypot(wall.x - oldX, wall.y - oldY);
  sweepWallHeroes(wall, heroes, oldX, oldY, travelDist, events, fx);
  sweepWallCores(wall, cores, oldX, oldY, travelDist, events);
}

function wallBlocked(x: number, y: number, covers: readonly CoverRect[]): boolean {
  const lo = ARENA_MARGIN + WALL_STOP_INSET;
  return x < lo || x > ARENA_SIZE.x - lo || y < lo || y > ARENA_SIZE.y - lo
    || pointInCover(x, y, covers, WALL_COVER_PADDING);
}

/** true = 유지. 무장 대기 → 수명 → 이동 → 경계/커버 CRASH → 스윕(원본 순서 그대로). */
function stepWall(
  wall: WallDeployable,
  heroes: ReadonlyMap<number, DeployableHero>,
  cores: ReadonlyMap<number, DeployableCore>,
  covers: readonly CoverRect[],
  dt: number,
  events: DeployableEvent[],
  fx?: EffectStore,
): boolean {
  if (wall.armTime > 0) {
    wall.armTime = Math.max(0, wall.armTime - dt);
    return true;
  }
  wall.lifetime -= dt;
  if (wall.lifetime <= 0) {
    events.push({ kind: "fizzle", x: wall.x, y: wall.y, radius: wall.halfLength, label: "" });
    addEffect(fx, {
      kind: "mine_fizzle", x: wall.x, y: wall.y, radius: wall.halfLength, duration: 0.24,
      color: "#8de1ff",
    });
    return false;
  }
  const nextX = wall.x + wall.travelX * wall.speed * dt;
  const nextY = wall.y + wall.travelY * wall.speed * dt;
  if (wallBlocked(nextX, nextY, covers)) {
    events.push({ kind: "wallCrash", x: wall.x, y: wall.y, halfLength: wall.halfLength });
    addEffect(fx, {
      kind: "wall_impact", x: wall.x, y: wall.y, radius: wall.halfLength, duration: 0.30,
      color: "#8de1ff", label: "CRASH", dx: wall.travelX, dy: wall.travelY,
    });
    return false;
  }
  const oldX = wall.x;
  const oldY = wall.y;
  wall.x = nextX;
  wall.y = nextY;
  movingWallSweep(wall, heroes, cores, oldX, oldY, events, fx);
  return true;
}

function tryTriggerMine(
  mine: MineDeployable,
  heroes: ReadonlyMap<number, DeployableHero>,
  cores: ReadonlyMap<number, DeployableCore>,
  dt: number,
  events: DeployableEvent[],
  fx?: EffectStore,
): void {
  if (mine.autoDetonate >= 0) {mine.autoDetonate -= dt;}
  const autoFire = mine.autoDetonate >= -0.5 && mine.autoDetonate <= 0;
  if (!autoFire && !mineHasTarget(mine, heroes, cores)) {return;}
  mine.triggered = true;
  mine.fuseTime = mine.fuseDuration;
  events.push({
    kind: "mineTriggered", owner: mine.owner, x: mine.x, y: mine.y,
    triggerRadius: mine.triggerRadius, fuseDuration: mine.fuseDuration,
  });
  addEffect(fx, {
    kind: "fuse", x: mine.x, y: mine.y, radius: mine.triggerRadius,
    duration: mine.fuseDuration, color: "#ff554a", label: "MOVE!",
  });
}

/** 원본 add_zone 인수 그대로 — 배선측이 zone(delay=MINE_ZONE_DELAY)으로 변환한다. */
function explosionEvent(mine: MineDeployable): DeployableEvent {
  return {
    kind: "mineExplode", owner: mine.owner, x: mine.x, y: mine.y,
    blastRadius: mine.blastRadius, damage: mine.damage,
    damageType: mine.ultimate ? "ultimate" : "equipment",
    ccTime: mine.ccTime, knockback: mine.knockback,
    label: mine.ultimate ? "PANIC MINE" : "PROX MINE", ultimate: mine.ultimate,
  };
}

/** true = 유지. 수명 → 무장 대기 → 트리거 판정 → 도화선 → 폭발(원본 순서 그대로). */
function stepMine(
  mine: MineDeployable,
  heroes: ReadonlyMap<number, DeployableHero>,
  cores: ReadonlyMap<number, DeployableCore>,
  dt: number,
  events: DeployableEvent[],
  fx?: EffectStore,
): boolean {
  mine.lifetime -= dt;
  if (mine.lifetime <= 0) {
    events.push({ kind: "fizzle", x: mine.x, y: mine.y, radius: MINE_FIZZLE_RADIUS, label: "EXPIRED" });
    addEffect(fx, {
      kind: "mine_fizzle", x: mine.x, y: mine.y, radius: 42, duration: 0.24,
      color: "#8ca0b8", label: "EXPIRED",
    });
    return false;
  }
  if (mine.armTime > 0) {
    mine.armTime = Math.max(0, mine.armTime - dt);
    return true;
  }
  if (!mine.triggered) {
    tryTriggerMine(mine, heroes, cores, dt, events, fx);
    return true;
  }
  mine.fuseTime -= dt;
  if (mine.fuseTime <= 0) {
    events.push(explosionEvent(mine));
    return false;
  }
  return true;
}

/** deployable_system.gd:105-153 update_deployables — 매 60Hz tick 호출. */
export function updateDeployables(
  state: DeployableState,
  heroes: ReadonlyMap<number, DeployableHero>,
  cores: ReadonlyMap<number, DeployableCore>,
  covers: readonly CoverRect[],
  dt: number,
  fx?: EffectStore,
): DeployableEvent[] {
  const events: DeployableEvent[] = [];
  const kept: Deployable[] = [];
  for (const d of state.deployables) {
    const keep = d.type === "wall"
      ? stepWall(d, heroes, cores, covers, dt, events, fx)
      : stepMine(d, heroes, cores, dt, events, fx);
    if (keep) {kept.push(d);}
  }
  state.deployables = kept;
  return events;
}

export const tickDeployables = updateDeployables;
export const applyMine = placeMine;
export const applyBounceWall = placeBounceWall;
export const seed = seedDeployables;
export const tick = updateDeployables;
export const apply = placeMine;
