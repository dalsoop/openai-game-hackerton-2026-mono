/**
 * 넉아웃 시체 물리 — 레거시 hero_movement.gd(update_knockouts) +
 * match_lifecycle.gd(down_hero death_velocity)의 결정론 포팅.
 * 런치 본체(match-launch.ts)와 짝이며, 사망 순간의 launch_vel 을 이어받는다.
 * 기존 match-covers 의 단순 SimKnockout 과 별개 타입 — 통합 때 합류한다.
 */
import {
  ARENA_MARGIN,
  ARENA_SIZE,
  HERO_RADIUS,
  pointInCover,
  type CoverRect,
} from "./match-covers";
import { WALL_BOUNCE_MAX, pushTrail, type Vec2 } from "./match-launch";
import { addEffect, type EffectStore } from "./match-effects.js";

// --- hero_movement.gd update_knockouts 원본 수치 ---
export const KNOCKOUT_REFLECT = -0.82;
export const KNOCKOUT_DRAG = 0.48;
export const KNOCKOUT_TRAIL_MAX = 20;
export const KNOCKOUT_STOP_TIME = 0.42;
// --- match_lifecycle.gd down_hero 원본 수치 ---
export const KNOCKOUT_MAX_TIME = 2.15;
export const DEATH_SPEED_MIN = 1550;
export const DEATH_SPEED_CARRY = 1.35;
export const DEATH_CARRY_THRESHOLD = 450;

export type LaunchKnockout = {
  slot: number;
  pos: Vec2;
  vel: Vec2;
  time: number;
  maxTime: number;
  bounces: number;
  finished: boolean;
  trail: Vec2[];
};

/** down_hero 의 death_velocity — 런치 속도 450 미만이면 fallback 방향 * 1550, 이상이면 1.35 배(최소 1550). */
export function deathVelocity(launchVel: Vec2, fallbackDirection: Vec2): Vec2 {
  const len = Math.hypot(launchVel.x, launchVel.y);
  if (len < DEATH_CARRY_THRESHOLD) {
    return { x: fallbackDirection.x * DEATH_SPEED_MIN, y: fallbackDirection.y * DEATH_SPEED_MIN };
  }
  const speed = Math.max(DEATH_SPEED_MIN, len * DEATH_SPEED_CARRY);
  return { x: (launchVel.x / len) * speed, y: (launchVel.y / len) * speed };
}

/** owner 없음/제자리일 때의 방향 — Vector2.RIGHT.rotated(slot * TAU / playerCount). */
export function deathFallbackDirection(slot: number, playerCount: number): Vec2 {
  const ang = (slot * Math.PI * 2) / Math.max(1, playerCount);
  return { x: Math.cos(ang), y: Math.sin(ang) };
}

export function spawnLaunchKnockout(slot: number, pos: Vec2, vel: Vec2): LaunchKnockout {
  return {
    slot,
    pos: { x: pos.x, y: pos.y },
    vel: { x: vel.x, y: vel.y },
    time: KNOCKOUT_MAX_TIME,
    maxTime: KNOCKOUT_MAX_TIME,
    bounces: 0,
    finished: false,
    trail: [{ x: pos.x, y: pos.y }],
  };
}

/** down_hero 시체 스폰 — death_velocity 를 입힌 뒤 knockout 리스트 항목을 만든다. */
export function applyLaunchKnockout(
  slot: number,
  pos: Vec2,
  launchVel: Vec2,
  fallbackDirection: Vec2,
  fx?: EffectStore,
): LaunchKnockout {
  const vel = deathVelocity(launchVel, fallbackDirection);
  const len = Math.hypot(vel.x, vel.y);
  const dx = len < 1e-9 ? 1 : vel.x / len;
  const dy = len < 1e-9 ? 0 : vel.y / len;
  addEffect(fx, {
    kind: "death_burst", x: pos.x, y: pos.y, radius: 260, duration: 0.80,
    color: "#ff3349", dx, dy,
  });
  return spawnLaunchKnockout(slot, pos, vel);
}

export type KnockoutBounce = { slot: number; x: number; y: number };

/** 넉아웃 바운드는 HERO_RADIUS 없이 ARENA_MARGIN 만 쓴다 (update_knockouts 원본 그대로). */
function stepKnockout(
  k: LaunchKnockout,
  dt: number,
  tick: number,
  covers: readonly CoverRect[],
  bounces: KnockoutBounce[],
  fx?: EffectStore,
): void {
  const mx = k.vel.x * dt;
  const my = k.vel.y * dt;
  const nx = k.pos.x + mx;
  const ny = k.pos.y + my;
  const hitX = nx < ARENA_MARGIN || nx > ARENA_SIZE.x - ARENA_MARGIN
    || pointInCover(k.pos.x + mx, k.pos.y, covers, HERO_RADIUS);
  const hitY = ny < ARENA_MARGIN || ny > ARENA_SIZE.y - ARENA_MARGIN
    || pointInCover(k.pos.x, k.pos.y + my, covers, HERO_RADIUS);
  if (hitX || hitY) {
    if (hitX) {k.vel.x *= KNOCKOUT_REFLECT;} else {k.pos.x = nx;}
    if (hitY) {k.vel.y *= KNOCKOUT_REFLECT;} else {k.pos.y = ny;}
    k.bounces += 1;
    bounces.push({ slot: k.slot, x: k.pos.x, y: k.pos.y });
    const len = Math.hypot(k.vel.x, k.vel.y);
    const dx = len < 1e-9 ? -1 : -k.vel.x / len;
    const dy = len < 1e-9 ? 0 : -k.vel.y / len;
    addEffect(fx, {
      kind: "wall_impact", x: k.pos.x, y: k.pos.y, radius: 58, duration: 0.24,
      color: "#ff4f5e", dx, dy,
    });
  } else {
    k.pos.x = nx;
    k.pos.y = ny;
  }
  const drag = Math.exp(-KNOCKOUT_DRAG * dt);
  k.vel.x *= drag;
  k.vel.y *= drag;
  pushTrail(k.trail, k.pos.x, k.pos.y, tick, KNOCKOUT_TRAIL_MAX);
  if (k.bounces >= WALL_BOUNCE_MAX) {
    k.finished = true;
    k.vel = { x: 0, y: 0 };
    k.time = Math.min(k.time, KNOCKOUT_STOP_TIME);
  }
}

/** update_knockouts — 리스트를 제자리 갱신, wall_impact 연출용 바운스 이벤트를 돌려준다. */
export function tickLaunchKnockouts(
  list: LaunchKnockout[],
  dt: number,
  tickCount: number,
  covers: readonly CoverRect[],
  fx?: EffectStore,
): KnockoutBounce[] {
  const bounces: KnockoutBounce[] = [];
  const kept: LaunchKnockout[] = [];
  for (const k of list) {
    k.time -= dt;
    if (!k.finished) {stepKnockout(k, dt, tickCount, covers, bounces, fx);}
    if (k.time > 0) {kept.push(k);}
  }
  list.length = 0;
  list.push(...kept);
  return bounces;
}

/** 매치 시작 knockout 리스트 — game_world 는 빈 배열로 시작한다. */
export function launchKnockoutSeed(): LaunchKnockout[] {
  return [];
}

export const seed = launchKnockoutSeed;
export const apply = applyLaunchKnockout;
export const tick = tickLaunchKnockouts;
