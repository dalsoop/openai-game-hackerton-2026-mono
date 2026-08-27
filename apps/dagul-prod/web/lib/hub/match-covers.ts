/**
 * 아레나 지오메트리 + 커버·knockout — 레거시 arena_geometry.gd 의 결정론 포팅.
 * RNG·시계 없음: 상수와 입력만으로 결과가 정해진다.
 */

export const SOURCE_ARENA_SIZE = { x: 2800, y: 1700 };
export const ARENA_TILE_SCALE = 1.4;
export const ARENA_SIZE = { x: 7840, y: 4760 };
export const ARENA_CENTER = { x: 3920, y: 2380 };
export const ARENA_MARGIN = 104;
export const HERO_RADIUS = 20;
/** knockout 연출 총 시간 — Godot render_heroes 가 spin=max_time-time, fade=time/0.42 로 소비한다. */
export const KNOCKOUT_TIME = 2.15;
const NUDGE_STEP = 28;
const NUDGE_MAX_STEPS = 24;

export type CoverRect = { x: number; y: number; w: number; h: number };

export type SimKnockout = {
  slot: number;
  animal: number;
  x: number;
  y: number;
  time: number;
  maxTime: number;
};

/** 원본 2800x1700 아레나의 커버 11개 — build_tiled_covers 의 source_rects 그대로. */
const SOURCE_COVERS: readonly CoverRect[] = [
  { x: 1330, y: 590, w: 140, h: 520 },
  { x: 930, y: 810, w: 300, h: 70 },
  { x: 1570, y: 810, w: 300, h: 70 },
  { x: 590, y: 350, w: 230, h: 82 },
  { x: 1980, y: 350, w: 230, h: 82 },
  { x: 590, y: 1268, w: 230, h: 82 },
  { x: 1980, y: 1268, w: 230, h: 82 },
  { x: 340, y: 715, w: 82, h: 270 },
  { x: 2378, y: 715, w: 82, h: 270 },
  { x: 1030, y: 260, w: 120, h: 120 },
  { x: 1650, y: 1320, w: 120, h: 120 },
];

function tileOrigins(): Array<{ x: number; y: number }> {
  const origins: Array<{ x: number; y: number }> = [];
  for (const tileX of [0, 1]) {
    for (const tileY of [0, 1]) {
      origins.push({
        x: tileX * SOURCE_ARENA_SIZE.x * ARENA_TILE_SCALE,
        y: tileY * SOURCE_ARENA_SIZE.y * ARENA_TILE_SCALE,
      });
    }
  }
  return origins;
}

/** 2x2 타일 x 원본 11개 = 44개 커버 rect (결정론). */
export function buildTiledCovers(): CoverRect[] {
  const covers: CoverRect[] = [];
  for (const origin of tileOrigins()) {
    for (const src of SOURCE_COVERS) {
      covers.push({
        x: origin.x + src.x * ARENA_TILE_SCALE,
        y: origin.y + src.y * ARENA_TILE_SCALE,
        w: src.w * ARENA_TILE_SCALE,
        h: src.h * ARENA_TILE_SCALE,
      });
    }
  }
  return covers;
}

/** 커버 충돌은 rect 중심 + 짧은 변 반지름의 원형이다 (레거시 point_in_cover). */
export function pointInCover(
  px: number,
  py: number,
  covers: readonly CoverRect[],
  padding = 0,
): boolean {
  for (const c of covers) {
    const r = Math.min(c.w, c.h) * 0.5 + padding;
    if (Math.hypot(px - (c.x + c.w * 0.5), py - (c.y + c.h * 0.5)) <= r) {return true;}
  }
  return false;
}

/** 축 분리 벽 슬라이딩 — X 먼저, 그 결과 위에서 Y (레거시 resolve_cover_motion). */
export function resolveCoverMotion(
  x: number,
  y: number,
  mx: number,
  my: number,
  covers: readonly CoverRect[],
): { x: number; y: number } {
  let rx = x;
  if (!pointInCover(x + mx, y, covers, HERO_RADIUS)) {rx = x + mx;}
  let ry = y;
  if (!pointInCover(rx, y + my, covers, HERO_RADIUS)) {ry = y + my;}
  return { x: rx, y: ry };
}

/** 한 스텝의 최대 이동거리. 가장 얇은 커버(반지름 35 안팎)보다 확실히 작게 잡아
 * 대시처럼 한 번에 300px 넘게 움직이는 이동이 벽을 관통해 지나가지 않게 한다. */
const SWEPT_MAX_STEP = 24;

/** 대시급 큰 이동을 SWEPT_MAX_STEP 이하 조각으로 나눠 resolveCoverMotion 을 반복
 * 적용한다 — 한 번에 커버보다 큰 거리를 이동하면 시작점·도착점 둘 다 커버
 * 밖이라 충돌 판정 자체가 비어, 벽을 뚫고 지나가 버린다(터널링). 한 조각이라도
 * 막히면 그 지점에서 멈춘다 — 벽에 붙어 슬라이드하는 자연스러운 감속. */
export function resolveCoverMotionSwept(
  x: number,
  y: number,
  mx: number,
  my: number,
  covers: readonly CoverRect[],
): { x: number; y: number } {
  const dist = Math.hypot(mx, my);
  if (dist <= SWEPT_MAX_STEP) {return resolveCoverMotion(x, y, mx, my, covers);}
  const steps = Math.ceil(dist / SWEPT_MAX_STEP);
  const stepX = mx / steps;
  const stepY = my / steps;
  let cx = x;
  let cy = y;
  for (let i = 0; i < steps; i += 1) {
    const next = resolveCoverMotion(cx, cy, stepX, stepY, covers);
    if (next.x === cx && next.y === cy) {break;} // 완전히 막힘 — 더 밀어붙이지 않는다
    cx = next.x;
    cy = next.y;
  }
  return { x: cx, y: cy };
}

export function clampArena(x: number, y: number): { x: number; y: number } {
  return {
    x: Math.min(ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS, Math.max(ARENA_MARGIN + HERO_RADIUS, x)),
    y: Math.min(ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS, Math.max(ARENA_MARGIN + HERO_RADIUS, y)),
  };
}

export const FIRE_SPEED = 1000;
export const FIRE_TTL = 0.44;
/** burst 권총 normal_range 와 같다. 이보다 멀리서 쏘면 탄이 만료된다. */
export const EFFECTIVE_RANGE = FIRE_SPEED * FIRE_TTL;

/** 레거시 _reset_heroes 의 SPAWN_HERO_RADIUS — 가장자리 스폰이라 개전까지 거리가 남는다. */
export const SPAWN_RADIUS = { x: 3360, y: 1940 };

export function spawnPoint(slot: number, count: number): { x: number; y: number } {
  const n = Math.max(1, count);
  const ang = (Math.PI * 2 * slot) / n - Math.PI / 2;
  return clampArena(
    ARENA_CENTER.x + Math.cos(ang) * SPAWN_RADIUS.x,
    ARENA_CENTER.y + Math.sin(ang) * SPAWN_RADIUS.y,
  );
}

function moveToward(x: number, y: number, tx: number, ty: number, delta: number): { x: number; y: number } {
  const dx = tx - x;
  const dy = ty - y;
  const dist = Math.hypot(dx, dy);
  if (dist <= delta || dist === 0) {return { x: tx, y: ty };}
  return { x: x + (dx / dist) * delta, y: y + (dy / dist) * delta };
}

/** 커버 안이면 아레나 중심 방향으로 28px 씩 밀어낸다 (레거시 nudge_out_of_cover). */
export function nudgeOutOfCover(
  point: { x: number; y: number },
  covers: readonly CoverRect[],
): { x: number; y: number } {
  if (!pointInCover(point.x, point.y, covers, HERO_RADIUS)) {return point;}
  let nudged = point;
  for (let step = 0; step < NUDGE_MAX_STEPS; step += 1) {
    const moved = moveToward(nudged.x, nudged.y, ARENA_CENTER.x, ARENA_CENTER.y, NUDGE_STEP);
    nudged = clampArena(moved.x, moved.y);
    if (!pointInCover(nudged.x, nudged.y, covers, HERO_RADIUS)) {return nudged;}
  }
  return clampArena(ARENA_CENTER.x, ARENA_CENTER.y);
}

/** 히어로 사망 자리에 knockout 연출 항목을 만든다. */
export function spawnKnockout(hero: { slot: number; animal: number; x: number; y: number }): SimKnockout {
  return { slot: hero.slot, animal: hero.animal, x: hero.x, y: hero.y, time: KNOCKOUT_TIME, maxTime: KNOCKOUT_TIME };
}

/** time 은 매 스텝 감소하고 0 이하면 제거된다 (Godot draw_knockouts 기대와 동일). */
export function tickKnockouts(list: SimKnockout[], dt: number): void {
  for (let i = list.length - 1; i >= 0; i -= 1) {
    list[i].time -= dt;
    if (list[i].time <= 0) {list.splice(i, 1);}
  }
}
export const seed = buildTiledCovers;
export const tick = tickKnockouts;
export const apply = spawnKnockout;
