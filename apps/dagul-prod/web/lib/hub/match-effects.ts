// 서버 권위 시각 이펙트 스토어 — 원본 projectile_hit.gd add_effect/add_mobility_effect(52-70행) 대응.
// kind·반경·지속·색은 원본 호출 수치 그대로. 스냅 "effects" 로 나가 클라 렌더러가 kind 별로 그린다.

export const EFFECTS_SNAP_CAP = 48;
/** add_mobility_effect 의 지속 축소 — projectile_hit.gd:57 shortened_duration = duration * 0.80. */
export const MOBILITY_DURATION_SCALE = 0.8;

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

export type EffectStore = { items: SimEffect[] };

export function createEffectStore(): EffectStore {
  return { items: [] };
}

export type EffectOpts = {
  kind: string; x: number; y: number; radius: number; duration: number; color: string;
  label?: string; dx?: number; dy?: number; follow?: number;
};

/** 원본 add_effect. 스토어가 없으면(단위 조립 등) 조용히 무시. cap 초과 시 가장 오래된 것 제거. */
export function addEffect(store: EffectStore | undefined, opts: EffectOpts): void {
  if (!store) {return;}
  if (store.items.length >= EFFECTS_SNAP_CAP) {store.items.shift();}
  store.items.push({
    kind: opts.kind, x: opts.x, y: opts.y, radius: opts.radius,
    time: opts.duration, maxTime: opts.duration, color: opts.color,
    label: opts.label ?? "", dx: opts.dx ?? 1, dy: opts.dy ?? 0, follow: opts.follow ?? -1,
  });
}

/** 원본 add_mobility_effect — 도착점 기준, 지속 *0.8, follow=slot. */
export function addMobilityEffect(
  store: EffectStore | undefined, slot: number, kind: string,
  from: { x: number; y: number }, to: { x: number; y: number },
  radius: number, duration: number, color: string, label: string,
  dir: { x: number; y: number },
): void {
  void from;
  addEffect(store, {
    kind, x: to.x, y: to.y, radius, duration: duration * MOBILITY_DURATION_SCALE,
    color, label, dx: dir.x, dy: dir.y, follow: slot,
  });
}

/** 매 시뮬 스텝 감쇠 — 벽시계 초. */
export function decayEffects(store: EffectStore, dt: number): void {
  for (let i = store.items.length - 1; i >= 0; i -= 1) {
    store.items[i].time -= dt;
    if (store.items[i].time <= 0) {store.items.splice(i, 1);}
  }
}

/** CC 연출 — 원본 damage_system.gd:281(root=chain_bind), :287(stun=stun_burst). */
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

/** 차지 끊김 — 원본 damage_system.gd:241. */
export function addChargeBreakEffect(store: EffectStore | undefined, x: number, y: number): void {
  addEffect(store, { kind: "charge_break", x, y, radius: 54, duration: 0.22, color: "#8ca0b8" });
}

/** 회피 잔상 — blade evade 계열 afterimage. */
export function addEvadeEffect(store: EffectStore | undefined, x: number, y: number): void {
  addEffect(store, {
    kind: "afterimage", x, y, radius: 105, duration: 0.38, color: "#b9f3ff", label: "EVADE",
  });
}

export type HeroHitFx = {
  x: number; y: number; amount: number; knockback: number; source: string;
  kind: string; label: string; launchX: number; launchY: number; fromX: number; fromY: number;
};

/** 피격 임팩트 — 원본 damage_system.gd:350 반경 clamp(24+amount*1.4+|kb|*0.12, 32, 125). */
export function addHeroHitEffect(store: EffectStore | undefined, fx: HeroHitFx): void {
  const radius = Math.min(125, Math.max(32, 24 + fx.amount * 1.4 + Math.abs(fx.knockback) * 0.12));
  const duration = fx.source === "normal" ? 0.22 : 0.42;
  const len = Math.hypot(fx.x - fx.fromX, fx.y - fx.fromY) || 1;
  const dx = fx.launchX !== 0 || fx.launchY !== 0 ? fx.launchX : (fx.x - fx.fromX) / len;
  const dy = fx.launchX !== 0 || fx.launchY !== 0 ? fx.launchY : (fx.y - fx.fromY) / len;
  addEffect(store, {
    kind: fx.kind, x: fx.x, y: fx.y, radius, duration,
    color: fx.source === "normal" ? "#ff4f68" : "#ffb347", label: fx.label, dx, dy,
  });
}

type DashRow = {
  kind: string; duration: number; color: string; label: string;
  radius?: number; forward?: boolean;
};

/** 무기별 대시 연출 — 원본 active_item.gd:62-97. radius 미지정 = 대시 거리. forward = dir(전방). */
const DASH_TABLE: Readonly<Record<string, DashRow>> = {
  scatter: { kind: "speed_streak", duration: 0.30, color: "#ffb45c", label: "SKIRMISH HOP" },
  rail: { kind: "beam_step", duration: 0.26, color: "#71e7ff", label: "SIGHTLINE STEP" },
  mortar: { kind: "blast_hop", duration: 0.32, color: "#ff604f", label: "BLAST HOP" },
  leech: { kind: "drain", duration: 0.42, color: "#d45cff", label: "+8 SHADOW PULL", radius: 88 },
  breaker: { kind: "guard", duration: 0.20, color: "#ffe066", label: "IRON MARCH", radius: 68, forward: true },
  burst: { kind: "speed_streak", duration: 0.28, color: "#ff5ca8", label: "FLASH CUT" },
  blade: { kind: "slash_dash", duration: 0.34, color: "#b9f3ff", label: "SHADOW SHEATH" },
  brawler: { kind: "speed_streak", duration: 0.28, color: "#ff9466", label: "WEAVE" },
  bomb: { kind: "fuse", duration: 0.50, color: "#ff5d4f", label: "BLAST ROLL", radius: 75 },
  spear: { kind: "spear_line", duration: 0.32, color: "#ffe27a", label: "POLE VAULT" },
  chain: { kind: "chain_arc", duration: 0.34, color: "#b78cff", label: "SWING STEP" },
};
const DASH_DEFAULT: DashRow = {
  kind: "guard", duration: 0.30, color: "#8de1ff", label: "BRACE STEP", radius: 78, forward: true,
};

export type DashFx = {
  equipmentId: string; slot: number; oldX: number; oldY: number; x: number; y: number;
  dirX: number; dirY: number; comboKind: "none" | "combo_break" | "escape";
};

/** 대시(모빌리티) 연출 묶음 — 콤보 브레이크(active_item.gd:59-61) + 무기별 대시(62-97). */
export function addMobilityDashEffects(store: EffectStore | undefined, fx: DashFx): void {
  if (!store) {return;}
  if (fx.comboKind !== "none") {
    addEffect(store, {
      kind: "combo_break", x: fx.oldX, y: fx.oldY, radius: 72, duration: 0.34,
      color: "#6ef3a5", label: fx.comboKind === "escape" ? "ESCAPE" : "COMBO BREAK",
      dx: fx.dirX, dy: fx.dirY,
    });
  }
  const row = DASH_TABLE[fx.equipmentId] ?? DASH_DEFAULT;
  const distance = Math.hypot(fx.x - fx.oldX, fx.y - fx.oldY);
  if (fx.equipmentId === "mortar") {
    addEffect(store, {
      kind: "explosion", x: fx.oldX, y: fx.oldY, radius: 105, duration: 0.36,
      color: "#ff604f", label: "BLAST HOP",
    });
  }
  const sign = row.forward ? 1 : -1;
  addMobilityEffect(
    store, fx.slot, row.kind, { x: fx.oldX, y: fx.oldY }, { x: fx.x, y: fx.y },
    row.radius ?? distance, row.duration, row.color, row.label,
    { x: sign * fx.dirX, y: sign * fx.dirY },
  );
}

/** 스냅 "effects" 패킹 — 클라 계약 {k,x,y,r,t,maxT,color,label,dx,dy,follow}. */
export function packEffects(store: EffectStore | undefined): Record<string, unknown>[] {
  if (!store) {return [];}
  return store.items.map((e) => ({
    k: e.kind, x: e.x, y: e.y, r: e.radius, t: e.time, maxT: e.maxTime,
    color: e.color, label: e.label, dx: e.dx, dy: e.dy, follow: e.follow,
  }));
}
