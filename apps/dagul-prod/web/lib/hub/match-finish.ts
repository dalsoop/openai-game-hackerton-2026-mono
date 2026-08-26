/**
 * 확인사살 시네 — 원본 ultimate_effect.gd try_begin_finish·tick_finish_cine·
 * cancel_finish_cine + hero_movement.gd apply_human(F) 의 결정론 포팅.
 * RNG·시계 없음. down_hero 호출은 콜백(통합 때 match-life.downHero).
 */

/** 준비 구간(초) — ultimate_effect.gd FINISH_PREP. */
export const FINISH_PREP = 0.35;
/** 돌진 구간(초) — FINISH_RUSH. */
export const FINISH_RUSH = 0.184;
/** 히트스톱(초) — FINISH_HIT_STOP. */
export const FINISH_HIT_STOP = 0.40;
/** 시네 총 길이(초) — FINISH_TOTAL. 끝나면 down_hero. */
export const FINISH_TOTAL = 1.525;
/** 피격 비행(초) — FINISH_FLY = TOTAL - PREP - RUSH - HIT_STOP. */
export const FINISH_FLY = FINISH_TOTAL - FINISH_PREP - FINISH_RUSH - FINISH_HIT_STOP;
/** 시작 판정 거리 — try_begin_finish best_d 초기값, d < 이 값. */
export const FINISH_RANGE = 280;
/** 시네 중 두 번째 F 취소 하한 — tick_finish_cine t > 0.12. */
export const FINISH_CANCEL_AFTER = 0.12;
/** 시네 중 피해자 down_left 바닥 — maxf(0.12, down_left). */
export const FINISH_DOWN_HOLD = 0.12;
/** 돌진 변위 — atk_x = 220 * rush_t^3. */
export const FINISH_RUSH_X = 220;
/** 비행 X — vic_x = 1580 * fly_ease. */
export const FINISH_FLY_X = 1580;
/** 비행 Y — vic_y = -470 * fly_ease - 38 * sin(PI * fly_t). */
export const FINISH_FLY_Y = -470;
export const FINISH_FLY_ARC = 38;
/** 비행 스핀 — TAU * 2.85 * fly_ease. */
export const FINISH_FLY_SPINS = 2.85;

/** 모듈 로컬 히어로 — 통합 때 SimHero 로 합류. */
export type FinishHero = {
  slot: number;
  x: number;
  y: number;
  alive: boolean;
  downed: boolean;
  downLeft: number;
  eliminated: boolean;
  vx: number;
  vy: number;
};

/** finish_cine 사전 — snap_contract.gd pack_finish_cine 필드와 1:1. */
export type FinishCine = {
  on: boolean;
  atk: number;
  vic: number;
  t: number;
  hit: boolean;
  hitAge: number;
  fly: number;
  vicX: number;
  vicY: number;
  vicSpin: number;
  atkX: number;
  rush: boolean;
  midX: number;
  midY: number;
};

export type FinishCommand = { finish?: boolean };
export type FinishKillFn = (atk: number, vic: number) => void;

type FinishActors = { atk: number; vic: number; ah: FinishHero; vh: FinishHero };

function clamp01(t: number): number {
  return Math.min(1, Math.max(0, t));
}

function isFinishAttacker(h: FinishHero): boolean {
  return h.alive && !h.downed;
}

function isFinishTarget(h: FinishHero): boolean {
  return h.downed && h.alive;
}

function sortedSlots(heroes: ReadonlyMap<number, FinishHero>): number[] {
  return [...heroes.keys()].sort((a, b) => a - b);
}

function nearestDowned(
  heroes: ReadonlyMap<number, FinishHero>,
  slot: number,
  me: FinishHero,
): number {
  let best = -1;
  let bestD = FINISH_RANGE;
  for (const t of sortedSlots(heroes)) {
    if (t === slot) {continue;}
    const vic = heroes.get(t);
    if (vic === undefined || !isFinishTarget(vic)) {continue;}
    const d = Math.hypot(me.x - vic.x, me.y - vic.y);
    if (d < bestD) {
      bestD = d;
      best = t;
    }
  }
  return best;
}

function cineActors(
  cine: FinishCine,
  heroes: ReadonlyMap<number, FinishHero>,
): FinishActors | null {
  const ah = heroes.get(cine.atk);
  const vh = heroes.get(cine.vic);
  if (ah === undefined || vh === undefined) {return null;}
  return { atk: cine.atk, vic: cine.vic, ah, vh };
}

function finishActorsLive(actors: FinishActors): boolean {
  if (!actors.vh.downed || !actors.vh.alive) {return false;}
  if (!actors.ah.alive || actors.ah.eliminated) {return false;}
  return true;
}

function lockFinishActors(actors: FinishActors): void {
  actors.ah.vx = 0;
  actors.ah.vy = 0;
  actors.vh.downLeft = Math.max(FINISH_DOWN_HOLD, actors.vh.downLeft);
}

function assignEmpty(cine: FinishCine): void {
  const next = seedFinishCine();
  cine.on = next.on;
  cine.atk = next.atk;
  cine.vic = next.vic;
  cine.t = next.t;
  cine.hit = next.hit;
  cine.hitAge = next.hitAge;
  cine.fly = next.fly;
  cine.vicX = next.vicX;
  cine.vicY = next.vicY;
  cine.vicSpin = next.vicSpin;
  cine.atkX = next.atkX;
  cine.rush = next.rush;
  cine.midX = next.midX;
  cine.midY = next.midY;
}

function tickFinishHit(
  cine: FinishCine,
  actors: FinishActors,
  dt: number,
  downHeroFn: FinishKillFn,
): void {
  const hitAge = cine.hitAge + dt;
  cine.hitAge = hitAge;
  if (hitAge <= FINISH_HIT_STOP) {return;}
  const flyTime = Math.min(hitAge - FINISH_HIT_STOP, FINISH_FLY);
  const flyT = clamp01(flyTime / FINISH_FLY);
  const flyEase = 1 - (1 - flyT) ** 3;
  cine.fly = flyTime;
  cine.vicX = FINISH_FLY_X * flyEase;
  cine.vicY = FINISH_FLY_Y * flyEase - FINISH_FLY_ARC * Math.sin(Math.PI * flyT);
  cine.vicSpin = Math.PI * 2 * FINISH_FLY_SPINS * flyEase;
  if (flyTime < FINISH_FLY) {return;}
  const { atk, vic } = actors;
  assignEmpty(cine);
  downHeroFn(atk, vic);
}

function tickFinishRush(cine: FinishCine): void {
  if (cine.t >= FINISH_PREP) {cine.rush = true;}
  if (!cine.rush) {return;}
  const rushT = clamp01((cine.t - FINISH_PREP) / FINISH_RUSH);
  cine.atkX = FINISH_RUSH_X * rushT * rushT * rushT;
  if (rushT < 1) {return;}
  cine.rush = false;
  cine.hit = true;
  cine.hitAge = Math.max(0, cine.t - FINISH_PREP - FINISH_RUSH);
  cine.fly = 0;
}

/** 빈 finish_cine — game_world.gd:127 {}. */
export function seedFinishCine(): FinishCine {
  return {
    on: false, atk: 0, vic: -1, t: 0, hit: false, hitAge: 0, fly: 0,
    vicX: 0, vicY: 0, vicSpin: 0, atkX: 0, rush: false, midX: 0, midY: 0,
  };
}

/** cancel_finish_cine — finish_cine = {}. */
export function cancelFinishCine(cine: FinishCine): void {
  assignEmpty(cine);
}

/** try_begin_finish — 살아 있고 다운이 아닌 슬롯이 280 안 다운 생존자를 고른다. */
export function tryBeginFinish(
  cine: FinishCine,
  heroes: ReadonlyMap<number, FinishHero>,
  slot: number,
): boolean {
  if (cine.on) {return false;}
  const me = heroes.get(slot);
  if (me === undefined || !isFinishAttacker(me)) {return false;}
  const best = nearestDowned(heroes, slot, me);
  if (best < 0) {return false;}
  const vic = heroes.get(best);
  if (vic === undefined) {return false;}
  cine.on = true;
  cine.atk = slot;
  cine.vic = best;
  cine.t = 0;
  cine.hit = false;
  cine.hitAge = 0;
  cine.fly = 0;
  cine.vicX = 0;
  cine.vicY = 0;
  cine.vicSpin = 0;
  cine.atkX = 0;
  cine.rush = false;
  cine.midX = (me.x + vic.x) * 0.5;
  cine.midY = (me.y + vic.y) * 0.5;
  return true;
}

/**
 * apply_human F 에지 — cine 켜져 있으면 취소, 아니면 try_begin_finish.
 * player_input.gd 가 KEY_F 에지를 command.finish 로 넣는다.
 */
export function applyFinish(
  cine: FinishCine,
  heroes: ReadonlyMap<number, FinishHero>,
  slot: number,
  finish: boolean,
): void {
  if (!finish) {return;}
  if (cine.on) {
    cancelFinishCine(cine);
    return;
  }
  tryBeginFinish(cine, heroes, slot);
}

/** tick_finish_cine — 준비·돌진·히트스톱·비행 후 down_hero. */
export function tickFinishCine(
  cine: FinishCine,
  heroes: ReadonlyMap<number, FinishHero>,
  command: FinishCommand,
  dt: number,
  downHeroFn: FinishKillFn,
): void {
  if (!cine.on) {return;}
  const actors = cineActors(cine, heroes);
  if (actors === null) {
    cancelFinishCine(cine);
    return;
  }
  if (!finishActorsLive(actors)) {
    cancelFinishCine(cine);
    return;
  }
  lockFinishActors(actors);
  cine.t += dt;
  if (command.finish === true && cine.t > FINISH_CANCEL_AFTER) {
    cancelFinishCine(cine);
    return;
  }
  if (cine.hit) {
    tickFinishHit(cine, actors, dt, downHeroFn);
    return;
  }
  tickFinishRush(cine);
}

/** 스냅 finish_cine — pack_finish_cine. off 이면 {}. */
export function packFinishCine(cine: FinishCine): Record<string, unknown> {
  if (!cine.on) {return {};}
  return {
    on: true,
    atk: cine.atk,
    vic: cine.vic,
    t: cine.t,
    hit: cine.hit,
    hit_age: cine.hitAge,
    fly: cine.fly,
    vic_x: cine.vicX,
    vic_y: cine.vicY,
    vic_spin: cine.vicSpin,
    atk_x: cine.atkX,
    rush: cine.rush,
    mx: cine.midX,
    my: cine.midY,
  };
}

export const seed = seedFinishCine;
export const apply = applyFinish;
export const tick = tickFinishCine;
