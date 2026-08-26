import { EFFECTIVE_RANGE, HERO_RADIUS } from "./match-covers.js";

/** CPU 조종 — 사거리 유지·측면 이동·산개. 결정론(slot·tick 위상)만 쓴다. */

/** CPU 목표 유지 거리 — EFFECTIVE_RANGE 의 55~75% 밴드 중심(65%). */
export const CPU_TARGET_RANGE = EFFECTIVE_RANGE * 0.65;
export const CPU_RANGE_SLACK = EFFECTIVE_RANGE * 0.1;
export const CPU_STRAFE_WEIGHT = 0.6;
export const CPU_STRAFE_PERIOD_TICKS = 90;
export const CPU_STRAFE_SLOT_PHASE = 1.7;
export const CPU_SEPARATION_DIST = HERO_RADIUS * 4;
export const CPU_SEPARATION_WEIGHT = 1.2;

type CpuBody = { slot: number; x: number; y: number; alive: boolean };

export type CpuCommand = {
  mx: number;
  my: number;
  aimX: number;
  aimY: number;
  fire: boolean;
};

export function cpuAdvanceWeight(dist: number): number {
  if (dist > CPU_TARGET_RANGE + CPU_RANGE_SLACK) {return 1;}
  if (dist < CPU_TARGET_RANGE - CPU_RANGE_SLACK) {return -1;}
  return 0;
}

export function cpuStrafePhase(slot: number, tick: number): number {
  return Math.sin((tick / CPU_STRAFE_PERIOD_TICKS) * Math.PI * 2 + slot * CPU_STRAFE_SLOT_PHASE);
}

/** 가까운 다른 히어로들로부터 밀어내는 분리 벡터(뭉침 방지). */
export function cpuSeparation(hero: CpuBody, heroes: Iterable<CpuBody>): { x: number; y: number } {
  let sx = 0;
  let sy = 0;
  for (const other of heroes) {
    if (!other.alive || other.slot === hero.slot) {continue;}
    const dx = hero.x - other.x;
    const dy = hero.y - other.y;
    const d = Math.hypot(dx, dy);
    if (d === 0 || d >= CPU_SEPARATION_DIST) {continue;}
    const push = (CPU_SEPARATION_DIST - d) / CPU_SEPARATION_DIST;
    sx += (dx / d) * push;
    sy += (dy / d) * push;
  }
  return { x: sx, y: sy };
}

export function nearestPrey<H extends CpuBody>(hero: CpuBody, heroes: Iterable<H>): H | null {
  let best: H | null = null;
  let bestD = Infinity;
  for (const other of heroes) {
    if (!other.alive || other.slot === hero.slot) {continue;}
    const d = (other.x - hero.x) ** 2 + (other.y - hero.y) ** 2;
    if (d < bestD) {
      bestD = d;
      best = other;
    }
  }
  return best;
}

/** 이번 틱의 CPU 입력. 표적이 없으면 null. */
export function cpuCommand(hero: CpuBody, heroes: Iterable<CpuBody>, tick: number): CpuCommand | null {
  const bodies = [...heroes];
  const prey = nearestPrey(hero, bodies);
  if (!prey) {return null;}
  const dx = prey.x - hero.x;
  const dy = prey.y - hero.y;
  const dist = Math.hypot(dx, dy) || 1;
  const ux = dx / dist;
  const uy = dy / dist;
  const advance = cpuAdvanceWeight(dist);
  const strafe = cpuStrafePhase(hero.slot, tick) * CPU_STRAFE_WEIGHT;
  const sep = cpuSeparation(hero, bodies);
  return {
    mx: ux * advance - uy * strafe + sep.x * CPU_SEPARATION_WEIGHT,
    my: uy * advance + ux * strafe + sep.y * CPU_SEPARATION_WEIGHT,
    aimX: prey.x,
    aimY: prey.y,
    fire: dist < EFFECTIVE_RANGE - 40,
  };
}
