/**
 * 서버 이펙트 채널 — 원본 projectile_hit.gd add_effect / add_mobility_effect
 * + update_effects. 스냅 키는 parse_effects 계약(k,x,y,r,t,maxT,color,label,dx,dy,follow).
 * 수치 창작 없음: kind·반경·지속·색은 원본 add_effect 호출과 동일하다.
 */
export const EFFECTS_SNAP_CAP = 48;
/** add_mobility_effect: duration * 0.80. */
export const MOBILITY_DURATION_SCALE = 0.80;

export type EffectVec = { x: number; y: number };

export type SimEffect = {
  kind: string;
  x: number;
  y: number;
  radius: number;
  time: number;
  maxTime: number;
  color: string;
  label: string;
  dx: number;
  dy: number;
  follow: number;
};

export type AddEffectInput = {
  kind: string;
  x: number;
  y: number;
  radius: number;
  duration: number;
  color: string;
  label?: string;
  dx?: number;
  dy?: number;
  follow?: number;
};

export type EffectStore = { items: SimEffect[] };

export type MobilityDashInput = {
  equipmentId: string;
  slot: number;
  oldX: number;
  oldY: number;
  x: number;
  y: number;
  dirX: number;
  dirY: number;
  comboKind: "combo_break" | "escape" | "none";
};

type DashSpec = {
  kind: string;
  radius: number | "distance";
  duration: number;
  color: string;
  label: string;
  alongDash: boolean;
  drawDeparture: boolean;
};

const DASH_DEFAULT: DashSpec = {
  kind: "guard", radius: 78, duration: 0.30, color: "#8de1ff",
  label: "BRACE STEP", alongDash: true, drawDeparture: true,
};

const DASH_BY_ID: Record<string, DashSpec> = {
  scatter: {
    kind: "speed_streak", radius: "distance", duration: 0.30, color: "#ffb45c",
    label: "SKIRMISH HOP", alongDash: false, drawDeparture: true,
  },
  rail: {
    kind: "beam_step", radius: "distance", duration: 0.26, color: "#71e7ff",
    label: "SIGHTLINE STEP", alongDash: false, drawDeparture: true,
  },
  mortar: {
    kind: "blast_hop", radius: "distance", duration: 0.32, color: "#ff604f",
    label: "BLAST HOP", alongDash: false, drawDeparture: false,
  },
  leech: {
    kind: "drain", radius: 88, duration: 0.42, color: "#d45cff",
    label: "+8 SHADOW PULL", alongDash: false, drawDeparture: true,
  },
  breaker: {
    kind: "guard", radius: 68, duration: 0.20, color: "#ffe066",
    label: "IRON MARCH", alongDash: true, drawDeparture: true,
  },
  burst: {
    kind: "speed_streak", radius: "distance", duration: 0.28, color: "#ff5ca8",
    label: "FLASH CUT", alongDash: false, drawDeparture: true,
  },
  blade: {
    kind: "slash_dash", radius: "distance", duration: 0.34, color: "#b9f3ff",
    label: "SHADOW SHEATH", alongDash: false, drawDeparture: true,
  },
  brawler: {
    kind: "speed_streak", radius: "distance", duration: 0.28, color: "#ff9466",
    label: "WEAVE", alongDash: false, drawDeparture: true,
  },
  bomb: {
    kind: "fuse", radius: 75, duration: 0.50, color: "#ff5d4f",
    label: "BLAST ROLL", alongDash: false, drawDeparture: true,
  },
  spear: {
    kind: "spear_line", radius: "distance", duration: 0.32, color: "#ffe27a",
    label: "POLE VAULT", alongDash: false, drawDeparture: true,
  },
  chain: {
    kind: "chain_arc", radius: "distance", duration: 0.34, color: "#b78cff",
    label: "SWING STEP", alongDash: false, drawDeparture: true,
  },
};

export function createEffectStore(): EffectStore {
  return { items: [] };
}

function unitOrRight(x: number, y: number): EffectVec {
  const len = Math.hypot(x, y);
  if (len < 1e-9) {return { x: 1, y: 0 };}
  return { x: x / len, y: y / len };
}

function capPush(store: EffectStore, item: SimEffect): void {
  if (store.items.length >= EFFECTS_SNAP_CAP) {store.items.shift();}
  store.items.push(item);
}

/** projectile_hit.gd:51 add_effect. store 없으면 no-op (배선 전 호출 허용). */
export function addEffect(store: EffectStore | undefined, input: AddEffectInput): void {
  if (!store) {return;}
  const duration = input.duration;
  capPush(store, {
    kind: input.kind,
    x: input.x,
    y: input.y,
    radius: input.radius,
    time: duration,
    maxTime: duration,
    color: input.color,
    label: input.label ?? "",
    dx: input.dx ?? 1,
    dy: input.dy ?? 0,
    follow: input.follow ?? -1,
  });
}

/** projectile_hit.gd:54 add_mobility_effect. duration * 0.80, follow=slot, pos=end. */
export function addMobilityEffect(
  store: EffectStore | undefined,
  slot: number,
  kind: string,
  _start: EffectVec,
  end: EffectVec,
  radius: number,
  duration: number,
  color: string,
  label: string,
  direction: EffectVec,
  _drawDeparture = true,
): void {
  addEffect(store, {
    kind, x: end.x, y: end.y, radius,
    duration: duration * MOBILITY_DURATION_SCALE,
    color, label, dx: direction.x, dy: direction.y, follow: slot,
  });
}

/** projectile_hit.gd:250 update_effects — time -= dt, time>0 만 유지. */
export function decayEffects(store: EffectStore, dt: number): void {
  const kept: SimEffect[] = [];
  for (const e of store.items) {
    e.time -= dt;
    if (e.time > 0) {kept.push(e);}
  }
  store.items = kept;
}

function packOne(e: SimEffect): Record<string, unknown> {
  return {
    k: e.kind, x: e.x, y: e.y, r: e.radius, t: e.time, maxT: e.maxTime,
    color: e.color, label: e.label, dx: e.dx, dy: e.dy, follow: e.follow,
  };
}

/** network_host.gd _snap_effects — 최대 48, 삽입 순. 빈 배열은 호출측 omit-empty. */
export function packEffects(store: EffectStore | undefined): Record<string, unknown>[] {
  if (!store) {return [];}
  return store.items.slice(0, EFFECTS_SNAP_CAP).map(packOne);
}

/** damage_system.gd:222 EVADE. */
export function addEvadeEffect(store: EffectStore | undefined, x: number, y: number): void {
  addEffect(store, {
    kind: "afterimage", x, y, radius: 105, duration: 0.38, color: "#b9f3ff", label: "EVADE",
  });
}

/** damage_system.gd:241 charge_break. */
export function addChargeBreakEffect(store: EffectStore | undefined, x: number, y: number): void {
  addEffect(store, { kind: "charge_break", x, y, radius: 54, duration: 0.22, color: "#8ca0b8" });
}

/** damage_system.gd:281 / :287 root·stun 이펙트. */
export function addControlEffect(
  store: EffectStore | undefined, kind: "root" | "stun", x: number, y: number, ccTime: number,
): void {
  if (kind === "root") {
    addEffect(store, {
      kind: "chain_bind", x, y, radius: 48, duration: Math.min(0.48, ccTime),
      color: "#b78cff", label: "ROOTED",
    });
    return;
  }
  addEffect(store, {
    kind: "stun_burst", x, y, radius: 58, duration: Math.min(0.52, ccTime),
    color: "#ffe27a", label: "STUNNED",
  });
}

/** damage_system.gd:350-352 히트 임팩트. */
export function addHeroHitEffect(
  store: EffectStore | undefined,
  input: {
    x: number; y: number; amount: number; knockback: number; source: string;
    kind: string; label: string; launchX: number; launchY: number;
    fromX: number; fromY: number;
  },
): void {
  const radius = Math.min(125, Math.max(32, 24 + input.amount * 1.4 + Math.abs(input.knockback) * 0.12));
  const launch = unitOrRight(input.launchX, input.launchY);
  const launchLen = Math.hypot(input.launchX, input.launchY);
  const dir = launchLen * launchLen > 0.1
    ? launch
    : unitOrRight(input.x - input.fromX, input.y - input.fromY);
  addEffect(store, {
    kind: input.kind, x: input.x, y: input.y, radius,
    duration: input.source === "normal" ? 0.22 : 0.42,
    color: "#ffffff", label: input.label, dx: dir.x, dy: dir.y,
  });
}

/** active_item.gd:59-97 대시 이펙트 12종 + 콤보 브레이크. match-gun applyMobility 배선용. */
export function addMobilityDashEffects(
  store: EffectStore | undefined, input: MobilityDashInput,
): void {
  if (!store) {return;}
  const dir = unitOrRight(input.dirX, input.dirY);
  const old = { x: input.oldX, y: input.oldY };
  const end = { x: input.x, y: input.y };
  const distance = Math.hypot(input.x - input.oldX, input.y - input.oldY);
  if (input.comboKind === "combo_break" || input.comboKind === "escape") {
    const label = input.comboKind === "combo_break" ? "COMBO BREAK" : "ESCAPE";
    addEffect(store, {
      kind: "combo_break", x: old.x, y: old.y, radius: 72, duration: 0.34,
      color: "#6ef3a5", label, dx: dir.x, dy: dir.y,
    });
  }
  if (input.equipmentId === "mortar") {
    addEffect(store, {
      kind: "explosion", x: old.x, y: old.y, radius: 105, duration: 0.36,
      color: "#ff604f", label: "BLAST HOP",
    });
  }
  const spec = DASH_BY_ID[input.equipmentId] ?? DASH_DEFAULT;
  const radius = spec.radius === "distance" ? distance : spec.radius;
  const face = spec.alongDash ? dir : { x: -dir.x, y: -dir.y };
  addMobilityEffect(
    store, input.slot, spec.kind, old, end, radius, spec.duration,
    spec.color, spec.label, face, spec.drawDeparture,
  );
}

export const seed = createEffectStore;
export const add = addEffect;
export const tick = decayEffects;
export const pack = packEffects;
export const apply = addEffect;
