/**
 * 설치물 보조 — 히어로 이동측 벽 충돌(deployable_system.gd:155-183
 * deployable_wall_hit / mark_wall_hit)과 Godot 클라 parse_deployables
 * (net_snap_parser.gd:38-61)가 기대하는 snap 직렬화(network_host.gd:145-152).
 * 설치·틱 본체는 match-deployable.ts.
 */
import { HERO_RADIUS } from "./match-covers.js";
import { attackDirection } from "./match-deployable.js";
import type { Deployable, DeployableState, WallDeployable } from "./match-deployable.js";

/** 세그먼트 근접 히트 마진 — dist(new_pos, closest) <= HERO_RADIUS + 9. */
export const WALL_TOUCH_MARGIN = 9.0;
/** 이동측 WALL SLAM 넉백 origin — old_pos - normal * 32 (hero_movement.gd:190). */
export const WALL_BOUNCE_ORIGIN_BACK = 32;

/** deployable_wall_hit 반환 — 원본 {id, owner, pos, normal, damage, knockback}. */
export type WallContact = {
  id: number;
  owner: number;
  /** 충돌점 — 벽 세그먼트 위 new_pos 최근접점. */
  x: number;
  y: number;
  /** 벽 전진 방향(travel_direction 정규화) = 밀려나는 법선. */
  normalX: number;
  normalY: number;
  damage: number;
  knockback: number;
};

/** Godot Geometry2D.get_closest_point_to_segment. */
function closestPointToSegment(
  px: number, py: number, ax: number, ay: number, bx: number, by: number,
): { x: number; y: number } {
  const dx = bx - ax;
  const dy = by - ay;
  const lenSq = dx * dx + dy * dy;
  if (lenSq <= 0) {return { x: ax, y: ay };}
  const t = Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / lenSq));
  return { x: ax + dx * t, y: ay + dy * t };
}

/** Godot Geometry2D.segment_intersects_segment 알고리즘 그대로(평행이면 false). */
function segmentsCross(
  p1x: number, p1y: number, q1x: number, q1y: number,
  p2x: number, p2y: number, q2x: number, q2y: number,
): boolean {
  const bx = q1x - p1x;
  const by = q1y - p1y;
  const abLen = bx * bx + by * by;
  if (abLen <= 0) {return false;}
  const bnx = bx / abLen;
  const bny = by / abLen;
  const cRawX = p2x - p1x;
  const cRawY = p2y - p1y;
  const dRawX = q2x - p1x;
  const dRawY = q2y - p1y;
  const cx = cRawX * bnx + cRawY * bny;
  const cy = cRawY * bnx - cRawX * bny;
  const dx = dRawX * bnx + dRawY * bny;
  const dy = dRawY * bnx - dRawX * bny;
  if ((cy < 0 && dy < 0) || (cy >= 0 && dy >= 0)) {return false;}
  const abba = cx + ((dx - cx) * cy) / (cy - dy);
  return abba >= 0 && abba <= 1;
}

function wallContactFor(
  wall: WallDeployable, oldX: number, oldY: number, newX: number, newY: number,
): WallContact | null {
  const dir = attackDirection(wall.dirX, wall.dirY);
  const ax = wall.x - dir.x * wall.halfLength;
  const ay = wall.y - dir.y * wall.halfLength;
  const bx = wall.x + dir.x * wall.halfLength;
  const by = wall.y + dir.y * wall.halfLength;
  const closest = closestPointToSegment(newX, newY, ax, ay, bx, by);
  const crossed = segmentsCross(oldX, oldY, newX, newY, ax, ay, bx, by);
  if (!crossed && Math.hypot(newX - closest.x, newY - closest.y) > HERO_RADIUS + WALL_TOUCH_MARGIN) {
    return null;
  }
  const normal = attackDirection(wall.travelX, wall.travelY);
  // 미교차 근접 히트는 벽 전진 방향(normal)을 거스르는 이동일 때만.
  if (!crossed && (newX - oldX) * normal.x + (newY - oldY) * normal.y >= 0) {return null;}
  return {
    id: wall.id, owner: wall.owner, x: closest.x, y: closest.y,
    normalX: normal.x, normalY: normal.y, damage: wall.damage, knockback: wall.knockback,
  };
}

/**
 * deployable_system.gd:155-173 deployable_wall_hit — 히어로 이동(old→new)이 적 벽과
 * 충돌하면 첫 번째 접촉을 반환. wallHitCd(재히트 쿨다운 0.78s) 진행 중이면 null.
 * 배선측은 히트 시 위치를 old 로 되돌리고 damage_hero(cc 0.32, origin=old-normal*32),
 * wallHitCd=0.78, markWallHit 을 적용한다(hero_movement.gd:185-196).
 */
export function deployableWallHit(
  state: DeployableState,
  slot: number,
  wallHitCd: number,
  oldX: number,
  oldY: number,
  newX: number,
  newY: number,
): WallContact | null {
  if (wallHitCd > 0) {return null;}
  for (const d of state.deployables) {
    if (d.type !== "wall" || d.owner === slot || d.armTime > 0 || d.hitSlots.includes(slot)) {
      continue;
    }
    const contact = wallContactFor(d, oldX, oldY, newX, newY);
    if (contact) {return contact;}
  }
  return null;
}

/** deployable_system.gd:175-183 mark_wall_hit — 벽의 hit_slots 에 슬롯 기록(중복 없음). */
export function markWallHit(state: DeployableState, wallId: number, slot: number): void {
  for (const d of state.deployables) {
    if (d.id !== wallId || d.type !== "wall") {continue;}
    if (!d.hitSlots.includes(slot)) {d.hitSlots.push(slot);}
    return;
  }
}

/** network_host.gd _snap_deployables 원소 — Godot parse_deployables 기대 필드 전부. */
export type DeployableSnap = {
  type: "mine" | "wall";
  owner: number;
  x: number;
  y: number;
  dx: number;
  dy: number;
  tdx: number;
  tdy: number;
  half_length: number;
  lifetime: number;
  max_lifetime: number;
  arm_time: number;
  arm_duration: number;
  triggered: boolean;
  trigger_radius: number;
  blast_radius: number;
  fuse_time: number;
  fuse_duration: number;
};

/** match_lifecycle.gd:89 — wall_hit_cd 자연 감소. */
export function tickWallHitCd(heroes: Iterable<{ wallHitCd: number }>, dt: number): void {
  for (const hero of heroes) {hero.wallHitCd = Math.max(0, hero.wallHitCd - dt);}
}

/** hero_movement.gd:190 — 이동측 WALL SLAM origin. */
export function wallBounceOrigin(
  oldX: number, oldY: number, normalX: number, normalY: number,
): { x: number; y: number } {
  return { x: oldX - normalX * WALL_BOUNCE_ORIGIN_BACK, y: oldY - normalY * WALL_BOUNCE_ORIGIN_BACK };
}

/**
 * network_host.gd:145-152 _snap_deployables — 서버 전용 필드(damage·knockback·speed·
 * cc_time·auto_detonate·hit_slots·hit_cores)는 싣지 않는다. 지뢰의 방향 기본값은
 * Vector2.RIGHT(1,0), half_length 0 — 원본 d.get 기본값 그대로.
 */
export function snapDeployables(deployables: readonly Deployable[]): DeployableSnap[] {
  return deployables.map((d) => ({
    type: d.type,
    owner: d.owner,
    x: d.x,
    y: d.y,
    dx: d.type === "wall" ? d.dirX : 1,
    dy: d.type === "wall" ? d.dirY : 0,
    tdx: d.type === "wall" ? d.travelX : 1,
    tdy: d.type === "wall" ? d.travelY : 0,
    half_length: d.type === "wall" ? d.halfLength : 0,
    lifetime: d.lifetime,
    max_lifetime: d.maxLifetime,
    arm_time: d.armTime,
    arm_duration: d.armDuration,
    triggered: d.type === "mine" ? d.triggered : false,
    trigger_radius: d.type === "mine" ? d.triggerRadius : 0,
    blast_radius: d.type === "mine" ? d.blastRadius : 0,
    fuse_time: d.type === "mine" ? d.fuseTime : 0,
    fuse_duration: d.type === "mine" ? d.fuseDuration : 0,
  }));
}

export const packDeployables = snapDeployables;
export const packDeployablesSnap = snapDeployables;
export const applyWallContact = deployableWallHit;
export const apply = deployableWallHit;
export const pack = snapDeployables;
export const tick = tickWallHitCd;
