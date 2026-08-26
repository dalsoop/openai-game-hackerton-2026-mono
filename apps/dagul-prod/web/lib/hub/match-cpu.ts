import { ARENA_CENTER, EFFECTIVE_RANGE, HERO_RADIUS } from "./match-covers.js";
import { MatchRng } from "./match-rng.js";

/**
 * CPU 조종 — 사거리 유지·측면 이동·산개 위에 인간화 계층(think 주기·조준 오차·
 * 발사 절제·저체력 후퇴·슬롯 성향)을 얹는다. 난수는 방 시드 LCG 만 쓴다.
 */

/** CPU 목표 유지 거리 — EFFECTIVE_RANGE 의 55~75% 밴드 중심(65%). */
export const CPU_TARGET_RANGE = EFFECTIVE_RANGE * 0.65;
export const CPU_RANGE_SLACK = EFFECTIVE_RANGE * 0.1;
export const CPU_STRAFE_WEIGHT = 0.6;
/** 교전 밴드 안(advance 0)에서는 원본 HOLD_RANGE 처럼 횡이동 위주. */
export const CPU_STRAFE_HOLD_WEIGHT = 0.88;
/** think 마다 이 확률로 strafe 방향을 뒤집는 저크(juke) — 예측 사격을 흘린다. */
export const CPU_JUKE_CHANCE = 0.3;
export const CPU_STRAFE_PERIOD_TICKS = 90;
export const CPU_STRAFE_SLOT_PHASE = 1.7;
export const CPU_SEPARATION_DIST = HERO_RADIUS * 4;
export const CPU_SEPARATION_WEIGHT = 1.2;

/** think 주기 — 0.12초 + slot*0.025초 상당의 틱 수(60Hz). 사이에는 직전 방침 유지. */
export const CPU_THINK_BASE_SEC = 0.12;
export const CPU_THINK_SLOT_SEC = 0.025;
export const CPU_THINK_JITTER_TICKS = 3;
/** 조준 각도 오차 — 원본 cpu_behavior.gd 의 ±0.085 rad. */
export const CPU_AIM_ERROR_RAD = 0.085;
/** 발사 절제 — 사거리 안이어도 think 당 이 확률로만 버스트 시작, 뒤이어 휴식 틱. */
export const CPU_FIRE_BURST_CHANCE = 0.5;
export const CPU_FIRE_REST_MIN_TICKS = 40;
export const CPU_FIRE_REST_MAX_TICKS = 85;
/** 개전 직후 머뭇거림 — 슬롯별 1.5~4.5초는 트리거를 안 당긴다(즉발 학살 방지). */
export const CPU_OPENING_HOLD_MIN_TICKS = 90;
export const CPU_OPENING_HOLD_MAX_TICKS = 270;
/** 표적 유지 — 원본 target_hold 0.42~0.72초(25~43틱). */
export const CPU_TARGET_HOLD_MIN_TICKS = 25;
export const CPU_TARGET_HOLD_MAX_TICKS = 43;
/** 뭉침 방지 — 유효 표적 3명 이상일 때 이미 2명이 때리는 표적은 피한다(원본 L198). */
export const CPU_CROWD_LIMIT = 2;
/** 저체력 후퇴 — HP 30% 미만이면 think 당 이 확률로 후퇴 모드에 들어가 한동안 유지. */
export const CPU_FLEE_HP_RATIO = 0.3;
export const CPU_FLEE_CHANCE = 0.65;
export const CPU_FLEE_HOLD_MIN_TICKS = 120;
export const CPU_FLEE_HOLD_MAX_TICKS = 300;
/** 후퇴 중 맵 중심 쪽 가중 — 자기장 밖으로 도망치다 죽는 것을 막는다. */
export const CPU_FLEE_CENTER_PULL = 0.35;
/** 자기장 인식 — 반지름의 이 비율을 넘으면 안쪽으로 붙는다(원본 urgency 1.85). */
export const CPU_ZONE_EDGE_RATIO = 0.86;
export const CPU_ZONE_EDGE_PULL = 0.9;
export const CPU_ZONE_OUT_PULL = 1.85;

/** 슬롯별 성향 — 공격성(발사 빈도)·선호 거리 곱·조준 오차 곱. 결정론(슬롯 고정). */
export const CPU_PROFILES: ReadonlyArray<{
  aggression: number;
  rangeMult: number;
  aimScale: number;
}> = [
  { aggression: 0.5, rangeMult: 1.06, aimScale: 1.05 },
  { aggression: 0.7, rangeMult: 0.96, aimScale: 0.85 },
  { aggression: 0.35, rangeMult: 1.14, aimScale: 1.3 },
  { aggression: 0.6, rangeMult: 1.0, aimScale: 0.95 },
  { aggression: 0.45, rangeMult: 1.1, aimScale: 1.2 },
  { aggression: 0.65, rangeMult: 0.94, aimScale: 0.9 },
  { aggression: 0.4, rangeMult: 1.12, aimScale: 1.25 },
  { aggression: 0.55, rangeMult: 1.08, aimScale: 1.1 },
];

export type CpuBody = {
  slot: number;
  x: number;
  y: number;
  alive: boolean;
  hp: number;
  maxHp: number;
};

export type CpuZone = { radius: number };

export type CpuCommand = {
  mx: number;
  my: number;
  aimX: number;
  aimY: number;
  fire: boolean;
};

type CpuMind = {
  nextThinkTick: number;
  fireRestUntilTick: number;
  fleeUntilTick: number;
  targetSlot: number;
  targetHoldUntilTick: number;
  cmd: CpuCommand | null;
};

export function cpuProfile(slot: number): (typeof CPU_PROFILES)[number] {
  return CPU_PROFILES[((slot % CPU_PROFILES.length) + CPU_PROFILES.length) % CPU_PROFILES.length];
}

export function cpuThinkPeriodTicks(slot: number): number {
  return Math.round((CPU_THINK_BASE_SEC + slot * CPU_THINK_SLOT_SEC) * 60);
}

export function cpuAdvanceWeight(dist: number, rangeMult = 1): number {
  const target = CPU_TARGET_RANGE * rangeMult;
  if (dist > target + CPU_RANGE_SLACK) {return 1;}
  if (dist < target - CPU_RANGE_SLACK) {return -1;}
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

/** 조준점 — 표적 현재 좌표(리드 없음)를 히어로 기준 각도 오차만큼 회전. */
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

/** 방별 CPU 두뇌 묶음 — MatchSim 이 시드로 하나 만들어 매 틱 command() 를 부른다. */
export class CpuFleet {
  private readonly rng: MatchRng;
  private readonly minds = new Map<number, CpuMind>();

  constructor(seed?: number) {
    this.rng = new MatchRng(seed);
  }

  /** 이번 틱의 CPU 입력. 표적이 없으면 null. think 틱이 아니면 직전 방침 반복. */
  command(hero: CpuBody, heroes: Iterable<CpuBody>, tick: number, zone?: CpuZone): CpuCommand | null {
    let mind = this.minds.get(hero.slot);
    if (!mind) {
      mind = {
        nextThinkTick: 0,
        fireRestUntilTick: this.rng.rangei(CPU_OPENING_HOLD_MIN_TICKS, CPU_OPENING_HOLD_MAX_TICKS),
        fleeUntilTick: 0,
        targetSlot: -1,
        targetHoldUntilTick: 0,
        cmd: null,
      };
      this.minds.set(hero.slot, mind);
    }
    if (tick < mind.nextThinkTick) {return mind.cmd;}
    mind.nextThinkTick = tick + cpuThinkPeriodTicks(hero.slot) + this.rng.rangei(0, CPU_THINK_JITTER_TICKS);
    mind.cmd = this.think(mind, hero, heroes, tick, zone);
    return mind.cmd;
  }

  private think(
    mind: CpuMind,
    hero: CpuBody,
    heroes: Iterable<CpuBody>,
    tick: number,
    zone?: CpuZone,
  ): CpuCommand | null {
    const bodies = [...heroes];
    const prey = this.chooseTarget(mind, hero, bodies, tick);
    if (!prey) {return null;}
    const profile = cpuProfile(hero.slot);
    const dx = prey.x - hero.x;
    const dy = prey.y - hero.y;
    const dist = Math.hypot(dx, dy) || 1;
    const ux = dx / dist;
    const uy = dy / dist;
    const fleeing = this.rollFlee(mind, hero, tick);
    const advance = fleeing ? -1 : cpuAdvanceWeight(dist, profile.rangeMult);
    const strafeWeight = advance === 0 ? CPU_STRAFE_HOLD_WEIGHT : CPU_STRAFE_WEIGHT;
    const juke = this.rng.chance(CPU_JUKE_CHANCE) ? -1 : 1;
    const strafe = cpuStrafePhase(hero.slot, tick) * strafeWeight * juke;
    const sep = cpuSeparation(hero, bodies);
    const pull = fleeing ? this.centerPull(hero, CPU_FLEE_CENTER_PULL) : { x: 0, y: 0 };
    const zonePull = this.zoneEscape(hero, zone);
    const aimError = this.rng.rangef(-CPU_AIM_ERROR_RAD, CPU_AIM_ERROR_RAD) * profile.aimScale;
    const aim = cpuAimPoint(hero, prey, aimError);
    return {
      mx: ux * advance - uy * strafe + sep.x * CPU_SEPARATION_WEIGHT + pull.x + zonePull.x,
      my: uy * advance + ux * strafe + sep.y * CPU_SEPARATION_WEIGHT + pull.y + zonePull.y,
      aimX: aim.x,
      aimY: aim.y,
      fire: dist < EFFECTIVE_RANGE - 40 && this.rollFireBurst(mind, profile.aggression, fleeing, tick),
    };
  }

  /**
   * 표적 선택 — 기본은 최근접이되, 원본의 target_hold(0.42~0.72초 유지)와
   * 뭉침 방지(유효 표적 3명 이상이면 이미 CPU_CROWD_LIMIT 명이 때리는 표적 제외)를 얹는다.
   */
  private chooseTarget(mind: CpuMind, hero: CpuBody, bodies: CpuBody[], tick: number): CpuBody | null {
    const valid = bodies.filter((b) => b.alive && b.slot !== hero.slot);
    if (valid.length === 0) {
      mind.targetSlot = -1;
      return null;
    }
    if (tick < mind.targetHoldUntilTick) {
      const held = valid.find((b) => b.slot === mind.targetSlot);
      if (held) {return held;}
    }
    const crowds = this.attackerCounts(hero.slot);
    const uncrowded = valid.length >= 3
      ? valid.filter((b) => (crowds.get(b.slot) ?? 0) < CPU_CROWD_LIMIT)
      : valid;
    const pool = uncrowded.length > 0 ? uncrowded : valid;
    const prey = nearestPrey(hero, pool);
    mind.targetSlot = prey ? prey.slot : -1;
    mind.targetHoldUntilTick =
      tick + this.rng.rangei(CPU_TARGET_HOLD_MIN_TICKS, CPU_TARGET_HOLD_MAX_TICKS);
    return prey;
  }

  /** 다른 CPU 들이 현재 슬롯별로 몇 명씩 노리는지 센다(자기 자신 제외). */
  private attackerCounts(selfSlot: number): Map<number, number> {
    const counts = new Map<number, number>();
    for (const [slot, other] of this.minds) {
      if (slot === selfSlot || other.targetSlot < 0) {continue;}
      counts.set(other.targetSlot, (counts.get(other.targetSlot) ?? 0) + 1);
    }
    return counts;
  }

  private centerPull(hero: CpuBody, weight: number): { x: number; y: number } {
    const cx = ARENA_CENTER.x - hero.x;
    const cy = ARENA_CENTER.y - hero.y;
    const d = Math.hypot(cx, cy) || 1;
    return { x: (cx / d) * weight, y: (cy / d) * weight };
  }

  /** 자기장 회피 — 경계 근처면 안쪽으로, 밖이면 원본 urgency 1.85 로 강하게 끌어온다. */
  private zoneEscape(hero: CpuBody, zone?: CpuZone): { x: number; y: number } {
    if (!zone) {return { x: 0, y: 0 };}
    const centerDist = Math.hypot(hero.x - ARENA_CENTER.x, hero.y - ARENA_CENTER.y);
    if (centerDist > zone.radius) {return this.centerPull(hero, CPU_ZONE_OUT_PULL);}
    if (centerDist > zone.radius * CPU_ZONE_EDGE_RATIO) {
      return this.centerPull(hero, CPU_ZONE_EDGE_PULL);
    }
    return { x: 0, y: 0 };
  }

  /**
   * 발사 절제 — 사거리 안이어도 트리거를 쉰다. think 당 확률로 버스트(1 think 길이)를
   * 시작하고, 버스트 뒤에는 휴식 틱(공격성이 높을수록 짧다)을 강제한다.
   */
  private rollFireBurst(mind: CpuMind, aggression: number, fleeing: boolean, tick: number): boolean {
    if (tick < mind.fireRestUntilTick) {return false;}
    const p = fleeing ? CPU_FIRE_BURST_CHANCE * 0.5 : CPU_FIRE_BURST_CHANCE;
    if (!this.rng.chance(p)) {return false;}
    const rest = this.rng.rangei(CPU_FIRE_REST_MIN_TICKS, CPU_FIRE_REST_MAX_TICKS);
    mind.fireRestUntilTick = mind.nextThinkTick + Math.round(rest * (1.35 - aggression * 0.7));
    return true;
  }

  /** 저체력 후퇴 성향 — 한번 발동하면 CPU_FLEE_HOLD 동안 유지한다(우왕좌왕 방지). */
  private rollFlee(mind: CpuMind, hero: CpuBody, tick: number): boolean {
    if (hero.maxHp <= 0 || hero.hp / hero.maxHp >= CPU_FLEE_HP_RATIO) {return false;}
    if (tick < mind.fleeUntilTick) {return true;}
    if (!this.rng.chance(CPU_FLEE_CHANCE)) {return false;}
    mind.fleeUntilTick = tick + this.rng.rangei(CPU_FLEE_HOLD_MIN_TICKS, CPU_FLEE_HOLD_MAX_TICKS);
    return true;
  }
}
