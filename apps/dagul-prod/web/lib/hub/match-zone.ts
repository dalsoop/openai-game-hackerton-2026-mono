/**
 * 자기장(Safe Zone) 5단계 + 210초 시간 제한 — 레거시 safe_zone_logic.gd 의 결정론 포팅.
 * RNG·시계 없음: 상수와 dt 만으로 상태가 정해진다. 중심은 항상 ARENA_CENTER 고정.
 */
import { ARENA_CENTER } from "./match-covers.js";

export const SAFE_ZONE_INITIAL_RADIUS = 3304;
export const SAFE_ZONE_DAMAGE_PER_SEC = 16;
/** 데미지 넘버 표시 간격(초) — 피해 자체는 매 60Hz 틱 연속 적용된다. */
export const SAFE_ZONE_TICK_INTERVAL = 0.5;
/** 매치 시간 제한(초) — 도달 시 HP 비율 판정. */
export const MATCH_TIME_LIMIT = 210;

export type SafeZonePhase = { wait: number; shrink: number; radius: number };

/** phase 0-4 — wait(대기) 후 shrink(축소) 로 radius 까지 줄어든다. */
export const SAFE_ZONE_PHASES: readonly SafeZonePhase[] = [
  { wait: 20, shrink: 22, radius: 2750 },
  { wait: 16, shrink: 20, radius: 2200 },
  { wait: 14, shrink: 18, radius: 1700 },
  { wait: 12, shrink: 16, radius: 1280 },
  { wait: 12, shrink: 16, radius: 900 },
];

export type SafeZoneState = {
  radius: number;
  fromRadius: number;
  targetRadius: number;
  phase: number;
  phaseTime: number;
  shrinking: boolean;
  complete: boolean;
  damageClock: number;
};

export function createSafeZone(): SafeZoneState {
  return {
    radius: SAFE_ZONE_INITIAL_RADIUS,
    fromRadius: SAFE_ZONE_INITIAL_RADIUS,
    targetRadius: SAFE_ZONE_PHASES[0].radius,
    phase: 0,
    phaseTime: 0,
    shrinking: false,
    complete: false,
    damageClock: 0,
  };
}

/** smoothstep 보간 — eased = t^2 * (3 - 2t), t 는 [0,1] 클램프. */
export function smoothstep01(t: number): number {
  const c = Math.min(1, Math.max(0, t));
  return c * c * (3 - 2 * c);
}

function advanceShrink(zone: SafeZoneState, dt: number): void {
  zone.phaseTime += dt;
  const spec = SAFE_ZONE_PHASES[zone.phase];
  const ratio = Math.min(1, Math.max(0, zone.phaseTime / spec.shrink));
  zone.radius = zone.fromRadius + (zone.targetRadius - zone.fromRadius) * smoothstep01(ratio);
  if (ratio < 1) {return;}
  zone.radius = zone.targetRadius;
  zone.shrinking = false;
  zone.phaseTime = 0;
  zone.phase += 1;
  if (zone.phase >= SAFE_ZONE_PHASES.length) {
    zone.complete = true;
    zone.phase = SAFE_ZONE_PHASES.length - 1;
    return;
  }
  zone.targetRadius = SAFE_ZONE_PHASES[zone.phase].radius;
}

function advanceWait(zone: SafeZoneState, dt: number): void {
  zone.phaseTime += dt;
  const spec = SAFE_ZONE_PHASES[zone.phase];
  if (zone.phaseTime < spec.wait) {return;}
  zone.shrinking = true;
  zone.phaseTime = 0;
  zone.fromRadius = zone.radius;
  zone.targetRadius = spec.radius;
}

/** wait→shrink 전이 + 피해 표시 시계. 반환 = 이번 스텝에 데미지 넘버를 표시할지(0.5초 간격). */
export function updateSafeZone(zone: SafeZoneState, dt: number): boolean {
  if (!zone.complete) {
    if (zone.shrinking) {advanceShrink(zone, dt);}
    else {advanceWait(zone, dt);}
  }
  zone.damageClock += dt;
  if (zone.damageClock < SAFE_ZONE_TICK_INTERVAL) {return false;}
  zone.damageClock -= SAFE_ZONE_TICK_INTERVAL;
  return true;
}

/** 장외 판정 — 중심(ARENA_CENTER)까지 거리 > 현재 반지름이면 밖. */
export function heroInSafeZone(zone: SafeZoneState, x: number, y: number): boolean {
  return Math.hypot(x - ARENA_CENTER.x, y - ARENA_CENTER.y) <= zone.radius;
}

type ZoneHero = { x: number; y: number; hp: number; alive: boolean };

/**
 * 장외 히어로에 16*dt 연속 피해. 이번 스텝에 HP 0 이 된 히어로 목록을 반환한다.
 * 환경 사망은 킬 크레딧이 없다 — 호출측은 knockout 연출만 만든다.
 */
export function applySafeZoneDamage<H extends ZoneHero>(
  zone: SafeZoneState,
  heroes: Iterable<H>,
  dt: number,
): H[] {
  const dead: H[] = [];
  for (const hero of heroes) {
    if (!hero.alive || heroInSafeZone(zone, hero.x, hero.y)) {continue;}
    hero.hp = Math.max(0, hero.hp - SAFE_ZONE_DAMAGE_PER_SEC * dt);
    if (hero.hp > 0) {continue;}
    hero.alive = false;
    dead.push(hero);
  }
  return dead;
}

type RankHero = { slot: number; hp: number; maxHp: number; alive: boolean; score?: number };

function hpRatio(hero: RankHero): number {
  if (!hero.alive) {return 0;}
  return Math.min(1, Math.max(0, hero.hp / Math.max(1, hero.maxHp)));
}

/** 우선순위: HP 비율 높음 → 실제 score 높음 → 슬롯 낮음 (safe_zone_logic.gd:93-102). */
function betterAtTimeLimit(candidate: RankHero, current: RankHero): boolean {
  const candidateHp = hpRatio(candidate);
  const currentHp = hpRatio(current);
  if (Math.abs(candidateHp - currentHp) > 1e-5) {return candidateHp > currentHp;}
  const candidateScore = candidate.score ?? 0;
  const currentScore = current.score ?? 0;
  if (candidateScore !== currentScore) {return candidateScore > currentScore;}
  return candidate.slot < current.slot;
}

/** 210초 판정 승자 슬롯 — 생존자가 없으면 -1(draw). */
export function pickTimeLimitWinner(heroes: Iterable<RankHero>): number {
  let best: RankHero | null = null;
  for (const hero of heroes) {
    if (!hero.alive) {continue;}
    if (!best || betterAtTimeLimit(hero, best)) {best = hero;}
  }
  return best ? best.slot : -1;
}
export const seed = createSafeZone;
export const tick = updateSafeZone;
export const apply = applySafeZoneDamage;
