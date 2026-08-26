/**
 * 콤보·히트스턴·CC(군중제어)·가드·슈퍼아머 — 원본 damage_system.gd +
 * hero_movement.gd + cpu_behavior.gd + active_item.gd + match_lifecycle.gd 의 결정론 포팅.
 * RNG·시계 없음: 순수 함수와 상태 객체만. 피해 파이프라인 배선은 통합 단계 몫.
 */

/** 콤보 히트당 증폭 스텝(+6%) — damage_system.gd:251. */
export const COMBO_AMP_STEP = 0.06;
/** 콤보 증폭 상한(+12%) — damage_system.gd:251. */
export const COMBO_AMP_CAP = 0.12;
/** 일반 히트 후 콤보 유지 시간 — damage_system.gd:250. */
export const COMBO_TIME_NORMAL = 1.05;
/** 피니셔 히트 후 콤보 유지 시간 — damage_system.gd:250. */
export const COMBO_TIME_FINISHER = 0.38;
/** 콤보 타이머 만료 시 부여 면역 — match_lifecycle.gd:83. */
export const COMBO_EXPIRE_IMMUNITY = 0.58;
/** break_incoming_combo(캡처 탈출) 시 면역 — damage_system.gd:200. */
export const COMBO_BREAK_IMMUNITY = 0.52;
/** 모빌리티 콤보 브레이크 시 면역 — active_item.gd:57. */
export const COMBO_MOBILITY_IMMUNITY = 0.72;
/** 콤보 면역 중 히트스턴(고정) — damage_system.gd:291. */
export const HITSTUN_IMMUNE = 0.04;
/** 히트스턴 기본값 — damage_system.gd:291. */
export const HITSTUN_BASE = 0.07;
/** 히트스턴 히트당 가산 — damage_system.gd:291. */
export const HITSTUN_PER_HIT = 0.055;
/** 히트스턴 상한 — damage_system.gd:291. */
export const HITSTUN_CAP = 0.28;
/** chain 무기 히트스턴 가산 — damage_system.gd:292-293. */
export const HITSTUN_CHAIN_BONUS = 0.05;
/** 히트스턴/콤보캡처 중 이동 배율(28% 감속) — hero_movement.gd:66-69. */
export const HITSTUN_MOVE_MULT = 0.72;
/** slow CC(cc_time) 중 이동 배율(58% 감속) — hero_movement.gd:57. */
export const CC_SLOW_MOVE_MULT = 0.42;
/** CPU 의 root 중 이동 배율 — cpu_behavior.gd:138. */
export const CPU_ROOT_MOVE_MULT = 0.35;
/** 가드 중 피해 배율(45% 감소) — damage_system.gd:256. */
export const GUARD_DAMAGE_MULT = 0.55;
/** 가드 중 넉백 배율(48% 감소) — damage_system.gd:257. */
export const GUARD_KNOCKBACK_MULT = 0.52;
/** 슈퍼아머 감쇄 후 이 값 미만 넉백은 무효 — damage_system.gd:319. */
export const SUPER_ARMOR_KNOCKBACK_MIN = 55.0;
/** 피니셔 넉백 가산 — damage_system.gd:312. */
export const FINISHER_KNOCKBACK_BONUS = 104.0;

/** damage_hero 의 control_kind — 기본 slow(cc_time 만), root/stun 은 전용 타이머 추가. */
export type CcControlKind = "slow" | "root" | "stun";

/** 모듈 로컬 구조적 타입 — 통합 때 SimHero 로 합류(game_world.gd:270 초기 사전). */
export interface CcHeroState {
  comboHits: number;
  comboTime: number;
  comboDamage: number;
  comboOwner: number;
  comboImmunity: number;
  comboCaptureTime: number;
  comboTarget: number;
  normalStep: number;
  normalChainTime: number;
  hitstunTime: number;
  ccTime: number;
  rootTime: number;
  stunTime: number;
  guardTime: number;
  superArmorTime: number;
  superArmorStrength: number;
}

/** 공격자 측 콤보 링크 필드 — break 시 함께 리셋(damage_system.gd:203-208). */
export interface ComboAttackerFields {
  comboTarget: number;
  normalStep: number;
  normalChainTime: number;
}

/** SimHero 생성 시 콤보/CC 초기 필드 묶음 — game_world.gd:270. */
export function ccSeedFields(): CcHeroState {
  return {
    comboHits: 0, comboTime: 0, comboDamage: 0, comboOwner: -1,
    comboImmunity: 0, comboCaptureTime: 0, comboTarget: -1,
    normalStep: 0, normalChainTime: 0, hitstunTime: 0,
    ccTime: 0, rootTime: 0, stunTime: 0, guardTime: 0,
    superArmorTime: 0, superArmorStrength: 0,
  };
}

/** 공격자 콤보 링크 초기값 — game_world.gd:270 combo_target/normal_step/normal_chain_time. */
export function comboAttackerSeedFields(): ComboAttackerFields {
  return { comboTarget: -1, normalStep: 0, normalChainTime: 0 };
}

/** 슈퍼아머 활성 여부 — damage_system.gd:258. */
export function superArmorActive(h: CcHeroState): boolean {
  return h.superArmorTime > 0;
}

/**
 * 콤보 적중 등록 — damage_system.gd:242-250. source != "mobility" 일 때만 호출(호출측 게이트).
 * 새 콤보 조건: 타이머 만료 OR 면역 중 OR 소유자 변경. 반환 = 이번 combo_hit(1부터).
 */
export function registerComboHit(h: CcHeroState, owner: number, attackFinisher: boolean): number {
  if (h.comboTime <= 0 || h.comboImmunity > 0 || h.comboOwner !== owner) {
    h.comboHits = 1;
    h.comboDamage = 0;
  } else {
    h.comboHits += 1;
  }
  h.comboOwner = owner;
  h.comboTime = attackFinisher ? COMBO_TIME_FINISHER : COMBO_TIME_NORMAL;
  return h.comboHits;
}

/** 콤보 데미지 증폭 배율 — damage_system.gd:251. 1히트 x1.00, 2히트 x1.06, 3히트+ x1.12 캡. */
export function comboAmplifier(comboHit: number): number {
  return 1 + Math.min(COMBO_AMP_CAP, (comboHit - 1) * COMBO_AMP_STEP);
}

/** 콤보 누적 피해 적립 — damage_system.gd:262-263(가드/방어 계수 적용 후 amount, downed 제외). */
export function accumulateComboDamage(h: CcHeroState, amount: number): void {
  h.comboDamage += amount;
}

/**
 * 히트스턴 지속 시간 — damage_system.gd:291-293.
 * 면역 중 0.04 고정, 그 외 min(0.28, 0.07 + hit*0.055). chain 무기 +0.05.
 */
export function hitstunDuration(comboHit: number, comboImmune: boolean, chainWeapon: boolean): number {
  const base = comboImmune ? HITSTUN_IMMUNE
    : Math.min(HITSTUN_CAP, HITSTUN_BASE + comboHit * HITSTUN_PER_HIT);
  return base + (chainWeapon ? HITSTUN_CHAIN_BONUS : 0);
}

/**
 * 히트스턴 적용 — damage_system.gd:290-295. 총격(source=="normal")은 호출측에서 제외.
 * combo_hit 0 이거나 슈퍼아머 활성이면 미적용. max 승계(짧아지지 않음).
 */
export function applyHitstun(h: CcHeroState, comboHit: number, chainWeapon: boolean): void {
  if (comboHit <= 0 || superArmorActive(h)) {return;}
  const stun = hitstunDuration(comboHit, h.comboImmunity > 0, chainWeapon);
  h.hitstunTime = Math.max(h.hitstunTime, stun);
}

/** applyControl 결과 — 호출측이 속도 0/차지 취소를 반영한다. */
export interface CcApplyResult {
  applied: boolean;
  zeroVelocity: boolean;
  cancelCharge: boolean;
}

/**
 * CC 적용 — damage_system.gd:275-287. 슈퍼아머 활성이면 전체 스킵.
 * slow 는 cc_time 만, root/stun 은 전용 타이머 추가(모두 max 승계).
 */
export function applyControl(h: CcHeroState, ccTime: number, kind: CcControlKind): CcApplyResult {
  if (superArmorActive(h) || ccTime <= 0) {
    return { applied: false, zeroVelocity: false, cancelCharge: false };
  }
  h.ccTime = Math.max(h.ccTime, ccTime);
  if (kind === "root") {
    h.rootTime = Math.max(h.rootTime, ccTime);
    return { applied: true, zeroVelocity: true, cancelCharge: false };
  }
  if (kind === "stun") {
    h.stunTime = Math.max(h.stunTime, ccTime);
    return { applied: true, zeroVelocity: true, cancelCharge: true };
  }
  return { applied: true, zeroVelocity: false, cancelCharge: false };
}

/** 가드 감쇄 — damage_system.gd:255-257. 가드 중 피해 x0.55, 넉백 x0.52. */
export function applyGuard(
  h: CcHeroState, amount: number, knockback: number,
): { amount: number; knockback: number } {
  if (h.guardTime <= 0) {return { amount, knockback };}
  return { amount: amount * GUARD_DAMAGE_MULT, knockback: knockback * GUARD_KNOCKBACK_MULT };
}

export type ApplyCcHitInput = {
  owner: number;
  amount: number;
  knockback: number;
  source: string;
  ccTime: number;
  controlKind: CcControlKind;
  attackFinisher: boolean;
  chainWeapon: boolean;
  downed?: boolean;
};

/**
 * damage_hero 콤보·가드·CC·히트스턴 경로 (런치 제외).
 * 순서: 콤보 등록/증폭 → 가드 → 슈퍼아머 캡처 해제 → 콤보 피해 적립 → CC → 히트스턴.
 */
export function applyCcHit(h: CcHeroState, input: ApplyCcHitInput): {
  amount: number; knockback: number; comboHit: number;
} {
  let comboHit = 0;
  let amount = input.amount;
  let knockback = input.knockback;
  if (input.source !== "mobility") {
    comboHit = registerComboHit(h, input.owner, input.attackFinisher);
    amount *= comboAmplifier(comboHit);
  }
  const guarded = applyGuard(h, amount, knockback);
  amount = guarded.amount;
  knockback = guarded.knockback;
  if (superArmorActive(h)) {h.comboCaptureTime = 0;}
  if (input.source !== "mobility" && !input.downed) {accumulateComboDamage(h, amount);}
  applyControl(h, input.ccTime, input.controlKind);
  if (comboHit > 0 && input.source !== "normal") {applyHitstun(h, comboHit, input.chainWeapon);}
  return { amount, knockback, comboHit };
}

/**
 * 슈퍼아머 넉백 감쇄 — damage_system.gd:317-320.
 * 강도만큼 감쇄 후 절대값 55 미만이면 0. 비활성이면 원값 통과.
 */
export function armorScaledKnockback(h: CcHeroState, knockback: number): number {
  if (!superArmorActive(h)) {return knockback;}
  const strength = Math.min(1, Math.max(0, h.superArmorStrength));
  const scaled = knockback * (1 - strength);
  return Math.abs(scaled) < SUPER_ARMOR_KNOCKBACK_MIN ? 0 : scaled;
}

/** 피니셔 넉백 — damage_system.gd:311-312. 부호 유지 + 절대값 104 가산. */
export function finisherKnockback(knockback: number): number {
  const sign = knockback < 0 ? -1 : 1;
  return sign * (Math.abs(knockback) + FINISHER_KNOCKBACK_BONUS);
}

/** 이동 판정 — locked=true 면 입력 처리 자체를 중단(stun). mult 는 속도 배율. */
export interface MoveControl {
  locked: boolean;
  mult: number;
}

/**
 * 인간 조작 이동 배율 — hero_movement.gd:57-69.
 * stun > root(0) > slow(0.42). 히트스턴 OR 콤보캡처는 x0.72 한 번만(elif — 중복 없음).
 */
export function movementControl(h: CcHeroState): MoveControl {
  if (h.stunTime > 0) {return { locked: true, mult: 0 };}
  let mult = h.ccTime > 0 ? CC_SLOW_MOVE_MULT : 1;
  if (h.rootTime > 0) {mult = 0;}
  if (h.hitstunTime > 0 || h.comboCaptureTime > 0) {mult *= HITSTUN_MOVE_MULT;}
  return { locked: false, mult };
}

/** CPU 이동 배율 — cpu_behavior.gd:137-138. cc(0.42) x (root 0.35 | 히트스턴/캡처 0.72). */
export function cpuMovementMult(h: CcHeroState): number {
  const ccSpeed = h.ccTime > 0 ? CC_SLOW_MOVE_MULT : 1;
  const lockSpeed = h.rootTime > 0 ? CPU_ROOT_MOVE_MULT
    : (h.hitstunTime > 0 || h.comboCaptureTime > 0 ? HITSTUN_MOVE_MULT : 1);
  return ccSpeed * lockSpeed;
}

/** 일반 공격 가능 — damage_system.gd:87. stun 만 차단(launch 등은 호출측 별도). */
export function ccAllowsAttack(h: CcHeroState): boolean {
  return h.stunTime <= 0;
}

/** 재장전 가능 — damage_system.gd:59. stun 차단(launch 는 호출측 별도). */
export function ccAllowsReload(h: CcHeroState): boolean {
  return h.stunTime <= 0;
}

/** 모빌리티 가능 — active_item.gd:28. root/stun 둘 다 차단. */
export function ccAllowsMobility(h: CcHeroState): boolean {
  return h.rootTime <= 0 && h.stunTime <= 0;
}

/** 무력화 판정 — game_world.gd:323. cc/root/stun 중 하나라도 걸려 있으면 true. */
export function ccIncapacitated(h: CcHeroState): boolean {
  return h.ccTime > 0 || h.rootTime > 0 || h.stunTime > 0;
}

function resetComboVictim(h: CcHeroState): void {
  h.comboHits = 0;
  h.comboTime = 0;
  h.comboDamage = 0;
  h.comboOwner = -1;
}

/**
 * 캡처 탈출 — break_incoming_combo(damage_system.gd:190-201) 피해자 측.
 * 면역 max(현재, 0.52). 반환 = 직전 콤보 소유자 slot(공격자 측 리셋용, 없으면 -1).
 */
export function breakIncomingCombo(h: CcHeroState): number {
  const owner = h.comboOwner;
  h.comboCaptureTime = 0;
  resetComboVictim(h);
  h.comboImmunity = Math.max(h.comboImmunity, COMBO_BREAK_IMMUNITY);
  return owner;
}

/** 공격자 측 콤보 링크 해제 — damage_system.gd:203-208. 대상이 일치할 때만 리셋. */
export function clearAttackerComboLink(attacker: ComboAttackerFields, victimSlot: number): boolean {
  if (attacker.comboTarget !== victimSlot) {return false;}
  attacker.comboTarget = -1;
  attacker.normalStep = 0;
  attacker.normalChainTime = 0;
  return true;
}

/**
 * 모빌리티 콤보 브레이크 — active_item.gd:32-61 순서 그대로.
 * 캡처 중이면 breakIncomingCombo(면역 0.52) 후 "escape",
 * 아니고 히트 누적 중이면 전체 리셋 + 면역 0.72 대입 + 히트스턴 해제 후 "combo_break".
 */
export function mobilityComboBreak(h: CcHeroState): { kind: "escape" | "combo_break" | "none"; prevOwner: number } {
  if (h.comboCaptureTime > 0) {
    return { kind: "escape", prevOwner: breakIncomingCombo(h) };
  }
  if (h.comboHits > 0) {
    const prevOwner = h.comboOwner;
    resetComboVictim(h);
    h.comboImmunity = COMBO_MOBILITY_IMMUNITY;
    h.hitstunTime = 0;
    return { kind: "combo_break", prevOwner };
  }
  return { kind: "none", prevOwner: -1 };
}

/**
 * 매 틱 타이머 소진 — match_lifecycle.gd:53-87 순서.
 * 콤보 타이머 만료 시 리셋 + 면역 max(현재, 0.58). 슈퍼아머 만료 시 강도 0.
 */
export function tickCcTimers(h: CcHeroState, dt: number): void {
  h.guardTime = Math.max(0, h.guardTime - dt);
  h.superArmorTime = Math.max(0, h.superArmorTime - dt);
  if (h.superArmorTime <= 0) {h.superArmorStrength = 0;}
  h.hitstunTime = Math.max(0, h.hitstunTime - dt);
  h.comboCaptureTime = Math.max(0, h.comboCaptureTime - dt);
  const prevChain = h.normalChainTime;
  h.normalChainTime = Math.max(0, prevChain - dt);
  if (prevChain > 0 && h.normalChainTime <= 0) {
    h.normalStep = 0;
    h.comboTarget = -1;
  }
  h.comboImmunity = Math.max(0, h.comboImmunity - dt);
  const prevComboTime = h.comboTime;
  h.comboTime = Math.max(0, prevComboTime - dt);
  if (prevComboTime > 0 && h.comboTime <= 0) {
    resetComboVictim(h);
    h.comboImmunity = Math.max(h.comboImmunity, COMBO_EXPIRE_IMMUNITY);
  }
  h.ccTime = Math.max(0, h.ccTime - dt);
  h.rootTime = Math.max(0, h.rootTime - dt);
  h.stunTime = Math.max(0, h.stunTime - dt);
}

/** 히어로 묶음 타이머 — update_timers 루프. */
export function tickCc(heroes: Iterable<CcHeroState>, dt: number): void {
  for (const h of heroes) {tickCcTimers(h, dt);}
}

export const seed = ccSeedFields;
export const apply = applyCcHit;
export const tick = tickCc;
