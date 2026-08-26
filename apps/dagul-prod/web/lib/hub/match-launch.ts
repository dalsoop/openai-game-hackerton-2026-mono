/* eslint-disable max-lines, max-depth -- 런치·넉백·벽튕김 포팅이 한 파일 */
/**
 * 넉백·런치·벽 튕김 — 레거시 damage_system.gd(damage_hero 런치 개시) +
 * hero_movement.gd(move_launched_hero / update_knockouts) +
 * match_lifecycle.gd(launch_trail_fade·death_velocity)의 결정론 포팅.
 * RNG·시계 없음: 60Hz tick 과 입력만으로 결과가 정해진다.
 * 통합 전 독립 모듈 — 히어로는 구조적 타입(LaunchedHero)으로만 만진다.
 */
import {
  ARENA_MARGIN,
  ARENA_SIZE,
  HERO_RADIUS,
  pointInCover,
  resolveCoverMotion,
  type CoverRect,
} from "./match-covers";
import { addEffect, type EffectStore } from "./match-effects.js";

export type Vec2 = { x: number; y: number };

// --- damage_system.gd 원본 수치 ---
export const GUARD_KNOCKBACK_MUL = 0.52;
export const FINISHER_KNOCKBACK_BONUS = 104;
export const ARMOR_LAUNCH_CANCEL = 55;
export const LAUNCH_TRAIL_FADE_TIME = 0.34;
export const LAUNCH_TRAIL_MAX = 14;
// --- hero_movement.gd 원본 수치 ---
export const WALL_BOUNCE_REFLECT = -0.84;
export const WALL_BOUNCE_MAX = 3;
export const LAUNCH_DRAG = 0.62;
export const LAUNCH_MIN_SPEED = 80;
export const GUARD_WALL_DAMAGE_MUL = 0.55;
/** 벽 튕김 공격자 점수 배율 — hero_movement.gd:263. */
export const WALL_BOUNCE_SCORE_MUL = 1.25;
/** 벽 튕김 공격자 threat 배율 — hero_movement.gd:264. */
export const WALL_BOUNCE_THREAT_MUL = 0.45;
/** 런치 속도 기저 — damage_system.gd:328 (900 + |kb|*9.8) / weight. */
export const LAUNCH_SPEED_BASE = 900;
export const LAUNCH_SPEED_KB_MUL = 9.8;
/** 런치 지속 — damage_system.gd:330 clamp(0.22+|kb|*0.0022, 0.26, 0.72). */
export const LAUNCH_TIME_BASE = 0.22;
export const LAUNCH_TIME_KB_MUL = 0.0022;
export const LAUNCH_TIME_MIN = 0.26;
export const LAUNCH_TIME_MAX = 0.72;
/** 마이크로 셔브 — damage_system.gd:303 clamp(5+|kb|*0.35, 5, 16). */
export const SHOVE_BASE = 5;
export const SHOVE_KB_MUL = 0.35;
export const SHOVE_MAX = 16;
/** chain tug — damage_system.gd:309 min(20, max(0, dist-55)). */
export const CHAIN_TUG_MAX = 20;
export const CHAIN_TUG_REST = 55;
/** 벽 데미지 — hero_movement.gd:254 clamp(9+v/78, 15, 36). */
export const WALL_DAMAGE_BASE = 9;
export const WALL_DAMAGE_DIV = 78;
export const WALL_DAMAGE_MIN = 15;
export const WALL_DAMAGE_MAX = 36;
function clampf(v: number, lo: number, hi: number): number {
  return Math.min(hi, Math.max(lo, v));
}

function normalize(x: number, y: number): Vec2 {
  const len = Math.hypot(x, y);
  if (len < 1e-9) {return { x: 0, y: 0 };}
  return { x: x / len, y: y / len };
}

/** tick % 2 == 0 마다 기록하는 링버퍼 (레거시 launch_trail / knockout trail 공용). */
export function pushTrail(trail: Vec2[], x: number, y: number, tick: number, max: number): void {
  if (tick % 2 !== 0) {return;}
  trail.push({ x, y });
  if (trail.length > max) {trail.shift();}
}

// ---------------------------------------------------------------- 런치 개시

export type LaunchDecisionInput = {
  /** 피해 소스 — "normal"(총) 만 건 전투 경로를 탄다. */
  source: string;
  /** 원시 넉백 (가드 0.52 반영 전). */
  knockback: number;
  guardTime: number;
  /** effect_kind=="explosion" 또는 label=="SPLASH". */
  heavyBlast: boolean;
  attackFinisher: boolean;
  superArmorTime: number;
  superArmorStrength: number;
};

export type LaunchDecision = {
  /** 0 이면 런치 없음. */
  launchKnockback: number;
  /** 건 전투 마이크로 셔브 픽셀 (런치 없을 때만 >0, 슈퍼아머 시 0). */
  shove: number;
};

/** damage_hero 의 heavy_blast 판정 그대로. */
export function isHeavyBlast(effectKind: string, effectLabel: string): boolean {
  return effectKind === "explosion" || effectLabel === "SPLASH";
}

/** damage_hero 런치 넉백 결정 경로 — 가드 0.52 → 건 전투/피니셔 → 슈퍼아머 감쇄. */
export function computeLaunchDecision(input: LaunchDecisionInput): LaunchDecision {
  const guarded = input.guardTime > 0 ? input.knockback * GUARD_KNOCKBACK_MUL : input.knockback;
  const armorActive = input.superArmorTime > 0;
  const armorStrength = armorActive ? clampf(input.superArmorStrength, 0, 1) : 0;
  const gunCombat = input.source === "normal";
  let launchKnockback = guarded;
  let shove = 0;
  if (gunCombat && !input.heavyBlast && !input.attackFinisher) {
    launchKnockback = 0;
    if (Math.abs(guarded) > 0.01 && !armorActive) {
      shove = clampf(SHOVE_BASE + Math.abs(guarded) * SHOVE_KB_MUL, SHOVE_BASE, SHOVE_MAX);
    }
  } else if (gunCombat && input.attackFinisher) {
    const sign = guarded < 0 ? -1 : 1;
    launchKnockback = sign * (Math.abs(guarded) + FINISHER_KNOCKBACK_BONUS);
  }
  if (armorActive) {
    launchKnockback *= 1 - armorStrength;
    if (Math.abs(launchKnockback) < ARMOR_LAUNCH_CANCEL) {launchKnockback = 0;}
  }
  return { launchKnockback, shove };
}

/** chain 무기 추가 끌기 — min(20, max(0, 거리-55)) 픽셀 (attacker 방향, 슈퍼아머 시 미적용). */
export function chainTug(distance: number): number {
  return Math.min(CHAIN_TUG_MAX, Math.max(0, distance - CHAIN_TUG_REST));
}

/** origin→victim 방향(제로 벡터면 aim), launch_knockback<=0 이면 반전. shove 방향은 kb=1 로 호출. */
export function launchDirection(
  impactOrigin: Vec2,
  attackerPos: Vec2,
  attackerAim: Vec2,
  victimPos: Vec2,
  launchKnockback: number,
): Vec2 {
  const origin = impactOrigin.x !== 0 || impactOrigin.y !== 0 ? impactOrigin : attackerPos;
  let push = normalize(victimPos.x - origin.x, victimPos.y - origin.y);
  if (push.x * push.x + push.y * push.y < 0.1) {push = { x: attackerAim.x, y: attackerAim.y };}
  if (launchKnockback > 0) {return push;}
  return { x: -push.x, y: -push.y };
}

/** 마이크로 셔브 적용 — 벽·커버를 존중하는 축 슬라이딩 이동 (resolve_cover_motion). */
export function applyMicroShove(
  victimPos: Vec2,
  dir: Vec2,
  magnitude: number,
  covers: readonly CoverRect[],
): Vec2 {
  return resolveCoverMotion(victimPos.x, victimPos.y, dir.x * magnitude, dir.y * magnitude, covers);
}

/** launch_speed = (900 + |kb|*9.8) / weight. */
export function launchSpeed(launchKnockback: number, weight: number): number {
  return (LAUNCH_SPEED_BASE + Math.abs(launchKnockback) * LAUNCH_SPEED_KB_MUL) / weight;
}

/** launch_time = clamp(0.22 + |kb|*0.0022, 0.26, 0.72). */
export function launchDuration(launchKnockback: number): number {
  return clampf(
    LAUNCH_TIME_BASE + Math.abs(launchKnockback) * LAUNCH_TIME_KB_MUL,
    LAUNCH_TIME_MIN,
    LAUNCH_TIME_MAX,
  );
}

export type LaunchState = {
  launchTime: number;
  launchVel: Vec2;
  wallBounces: number;
  launchOwner: number;
  launchTrail: Vec2[];
  launchTrailFade: number;
  launchWallDamage: number;
};

/** 런치 개시 시 히어로에 세팅되는 필드 묶음 (damage_hero 331-339행). */
export function startLaunch(params: {
  pos: Vec2;
  direction: Vec2;
  launchKnockback: number;
  weight: number;
  owner: number;
  source: string;
  comboDamage: number;
}): LaunchState {
  const speed = launchSpeed(params.launchKnockback, params.weight);
  return {
    launchTime: launchDuration(params.launchKnockback),
    launchVel: { x: params.direction.x * speed, y: params.direction.y * speed },
    wallBounces: 0,
    launchOwner: params.owner,
    launchTrail: [{ x: params.pos.x, y: params.pos.y }],
    launchTrailFade: LAUNCH_TRAIL_FADE_TIME,
    launchWallDamage: params.source === "mobility" ? 0 : params.comboDamage,
  };
}

/** SimHero 생성 시 런치 필드 — game_world.gd:270. */
export function launchSeedFields(): LaunchState {
  return {
    launchTime: 0,
    launchVel: { x: 0, y: 0 },
    wallBounces: 0,
    launchOwner: -1,
    launchTrail: [],
    launchTrailFade: 0,
    launchWallDamage: 0,
  };
}

export type LaunchVictim = LaunchedHero & {
  comboCaptureTime?: number;
};

export type ApplyLaunchParams = LaunchDecisionInput & {
  impactOrigin: Vec2;
  attackerPos: Vec2;
  attackerAim: Vec2;
  weight: number;
  owner: number;
  comboDamage: number;
  covers: readonly CoverRect[];
  chainWeapon?: boolean;
  fx?: EffectStore;
};

export type ApplyLaunchResult = {
  launched: boolean;
  shove: number;
  launchKnockback: number;
};

/**
 * damage_hero 런치 경로 — 셔브/체인 tug 후 |kb|>0.01 이면 런치 개시.
 * 피니셔·런치 시 combo_capture_time 이 있으면 0.
 */
export function applyLaunch(h: LaunchVictim, params: ApplyLaunchParams): ApplyLaunchResult {
  const decision = computeLaunchDecision(params);
  const gunShovePath = params.source === "normal" && !params.heavyBlast && !params.attackFinisher;
  if (gunShovePath) {
    if (decision.shove > 0) {
      const dir = launchDirection(
        params.impactOrigin, params.attackerPos, params.attackerAim,
        { x: h.x, y: h.y }, 1,
      );
      const pos = applyMicroShove({ x: h.x, y: h.y }, dir, decision.shove, params.covers);
      h.x = pos.x;
      h.y = pos.y;
    }
    if (params.chainWeapon && params.superArmorTime <= 0) {
      const dx = params.attackerPos.x - h.x;
      const dy = params.attackerPos.y - h.y;
      const dist = Math.hypot(dx, dy);
      const tug = chainTug(dist);
      if (tug > 0 && dist > 1e-9) {
        const pos = applyMicroShove(
          { x: h.x, y: h.y },
          { x: dx / dist, y: dy / dist },
          tug,
          params.covers,
        );
        h.x = pos.x;
        h.y = pos.y;
      }
    }
  } else if (params.source === "normal" && params.attackFinisher) {
    if (h.comboCaptureTime !== undefined) {h.comboCaptureTime = 0;}
    const dir = normalize(h.x - params.attackerPos.x, h.y - params.attackerPos.y);
    addEffect(params.fx, {
      kind: "combo_finisher", x: h.x, y: h.y, radius: 118, duration: 0.34,
      color: "#fff2b2", dx: dir.x, dy: dir.y,
    });
  }
  if (Math.abs(decision.launchKnockback) <= 0.01) {
    return { launched: false, shove: decision.shove, launchKnockback: decision.launchKnockback };
  }
  if (h.comboCaptureTime !== undefined) {h.comboCaptureTime = 0;}
  const dir = launchDirection(
    params.impactOrigin, params.attackerPos, params.attackerAim,
    { x: h.x, y: h.y }, decision.launchKnockback,
  );
  const st = startLaunch({
    pos: { x: h.x, y: h.y },
    direction: dir,
    launchKnockback: decision.launchKnockback,
    weight: params.weight,
    owner: params.owner,
    source: params.source,
    comboDamage: params.comboDamage,
  });
  h.launchTime = st.launchTime;
  h.launchVel = st.launchVel;
  h.wallBounces = st.wallBounces;
  h.launchOwner = st.launchOwner;
  h.launchTrail = st.launchTrail;
  h.launchTrailFade = st.launchTrailFade;
  h.launchWallDamage = st.launchWallDamage;
  return { launched: true, shove: decision.shove, launchKnockback: decision.launchKnockback };
}

/** 벽 튕김 공격자 적립 — damage_dealt + score*1.25 + threat*0.45 (자해 제외는 호출측). */
export function wallBounceAttackerCredit(wallDamage: number): {
  damageDealt: number; score: number; threat: number;
} {
  return {
    damageDealt: wallDamage,
    score: wallDamage * WALL_BOUNCE_SCORE_MUL,
    threat: wallDamage * WALL_BOUNCE_THREAT_MUL,
  };
}

// ---------------------------------------------------------------- 런치 이동

export type LaunchedHero = LaunchState & {
  x: number;
  y: number;
  hp: number;
  guardTime: number;
};

export type LaunchStepEvent = {
  bounced: boolean;
  /** 이번 tick 벽 데미지 (미반동이면 0). owner 크레딧(score*1.25, threat*0.45)은 통합 측 몫. */
  wallDamage: number;
  wallBounces: number;
  /** 벽 데미지로 hp<=0 — 통합 측이 apply_lethal_or_down 대응 처리. */
  died: boolean;
  /** 이번 tick 에 런치 종료. */
  ended: boolean;
};

type BounceResult = { vx: number; vy: number; wallDamage: number; died: boolean };

/** 반사(-0.84) 후 속도로 벽 데미지 clamp(9+v/78, 15, 36), 가드 시 0.55 배. */
function applyWallBounce(
  h: LaunchedHero,
  hitX: boolean,
  hitY: boolean,
  vx0: number,
  vy0: number,
): BounceResult {
  const vx = hitX ? vx0 * WALL_BOUNCE_REFLECT : vx0;
  const vy = hitY ? vy0 * WALL_BOUNCE_REFLECT : vy0;
  h.wallBounces += 1;
  let wallDamage = clampf(
    WALL_DAMAGE_BASE + Math.hypot(vx, vy) / WALL_DAMAGE_DIV,
    WALL_DAMAGE_MIN,
    WALL_DAMAGE_MAX,
  );
  if (h.guardTime > 0) {wallDamage *= GUARD_WALL_DAMAGE_MUL;}
  h.launchWallDamage += wallDamage;
  h.hp -= wallDamage;
  return { vx, vy, wallDamage, died: h.hp <= 0 };
}

/** move_launched_hero — 축별 충돌·반사·감쇠·트레일·종료를 1 tick 진행 (launchTime>0 일 때만 호출). */
export function moveLaunchedHero(
  h: LaunchedHero,
  dt: number,
  tick: number,
  covers: readonly CoverRect[],
  fx?: EffectStore,
): LaunchStepEvent {
  const ev: LaunchStepEvent = {
    bounced: false, wallDamage: 0, wallBounces: h.wallBounces, died: false, ended: false,
  };
  let px = h.x;
  let py = h.y;
  let vx = h.launchVel.x;
  let vy = h.launchVel.y;
  const minX = ARENA_MARGIN + HERO_RADIUS;
  const maxX = ARENA_SIZE.x - ARENA_MARGIN - HERO_RADIUS;
  const minY = ARENA_MARGIN + HERO_RADIUS;
  const maxY = ARENA_SIZE.y - ARENA_MARGIN - HERO_RADIUS;
  const cx = px + vx * dt;
  const hitX = cx < minX || cx > maxX || pointInCover(cx, py, covers, HERO_RADIUS);
  if (!hitX) {px = cx;}
  const cy = py + vy * dt;
  const hitY = cy < minY || cy > maxY || pointInCover(px, cy, covers, HERO_RADIUS);
  if (!hitY) {py = cy;}
  if (hitX || hitY) {
    const b = applyWallBounce(h, hitX, hitY, vx, vy);
    vx = b.vx;
    vy = b.vy;
    ev.bounced = true;
    ev.wallDamage = b.wallDamage;
    ev.wallBounces = h.wallBounces;
    const crash = normalize(-vx, -vy);
    addEffect(fx, {
      kind: "wall_impact", x: px, y: py, radius: 78, duration: 0.32,
      color: "#ff774f", label: `WALL CRASH -${Math.round(b.wallDamage)}`,
      dx: crash.x, dy: crash.y,
    });
    if (b.died) {
      h.x = px;
      h.y = py;
      h.launchVel = { x: vx, y: vy };
      ev.died = true;
      return ev;
    }
    if (h.wallBounces >= WALL_BOUNCE_MAX) {
      h.launchTime = 0;
      vx = 0;
      vy = 0;
    }
  }
  h.launchTime = Math.max(0, h.launchTime - dt);
  const drag = Math.exp(-LAUNCH_DRAG * dt);
  vx *= drag;
  vy *= drag;
  h.launchVel = { x: vx, y: vy };
  h.x = px;
  h.y = py;
  pushTrail(h.launchTrail, px, py, tick, LAUNCH_TRAIL_MAX);
  if (h.launchTime <= 0 || Math.hypot(vx, vy) < LAUNCH_MIN_SPEED) {
    h.launchTime = 0;
    h.launchVel = { x: 0, y: 0 };
    ev.ended = true;
  }
  return ev;
}

/** update_timers 의 트레일 페이드 — 런치 중 0.34 유지, 끝나면 1x 로 감쇠 후 트레일 소거. */
export function tickLaunchTrailFade(
  h: { launchTime: number; launchTrailFade: number; launchTrail: Vec2[] },
  dt: number,
): void {
  if (h.launchTime > 0) {
    h.launchTrailFade = LAUNCH_TRAIL_FADE_TIME;
    return;
  }
  h.launchTrailFade = Math.max(0, h.launchTrailFade - dt);
  if (h.launchTrailFade <= 0) {h.launchTrail = [];}
}

/** move_heroes 의 런치 분기 — launchTime>0 인 히어로만 1 tick 이동. */
export function tickLaunch(
  heroes: Iterable<LaunchedHero>,
  dt: number,
  tickCount: number,
  covers: readonly CoverRect[],
  fx?: EffectStore,
): LaunchStepEvent[] {
  const events: LaunchStepEvent[] = [];
  for (const h of heroes) {
    if (h.launchTime > 0) {events.push(moveLaunchedHero(h, dt, tickCount, covers, fx));}
  }
  return events;
}

export const seed = launchSeedFields;
export const apply = applyLaunch;
export const tick = tickLaunch;

// 넉아웃 시체 물리(update_knockouts·death_velocity)는 match-launch-knockout.ts 로 분리.
