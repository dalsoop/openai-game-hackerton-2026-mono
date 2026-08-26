import { describe, expect, it } from "vitest";
import {
  COMBO_BREAK_IMMUNITY,
  COMBO_EXPIRE_IMMUNITY,
  COMBO_MOBILITY_IMMUNITY,
  COMBO_TIME_FINISHER,
  COMBO_TIME_NORMAL,
  apply,
  applyControl,
  applyGuard,
  applyHitstun,
  armorScaledKnockback,
  breakIncomingCombo,
  ccAllowsAttack,
  ccAllowsMobility,
  ccIncapacitated,
  ccSeedFields,
  clearAttackerComboLink,
  comboAmplifier,
  cpuMovementMult,
  finisherKnockback,
  hitstunDuration,
  mobilityComboBreak,
  movementControl,
  registerComboHit,
  seed,
  tick,
  tickCcTimers,
} from "@/lib/hub/match-cc";

const DT = 1 / 60;

describe("콤보 증폭 공식 — damage_system.gd:251", () => {
  it("1히트 x1.00, 2히트 x1.06, 3히트 x1.12, 4히트+ 캡 x1.12", () => {
    expect(comboAmplifier(1)).toBeCloseTo(1.0, 10);
    expect(comboAmplifier(2)).toBeCloseTo(1.06, 10);
    expect(comboAmplifier(3)).toBeCloseTo(1.12, 10);
    expect(comboAmplifier(4)).toBeCloseTo(1.12, 10);
    expect(comboAmplifier(9)).toBeCloseTo(1.12, 10);
  });

  it("등록: 같은 소유자 연속 히트는 누적, 타이머 설정 1.05/0.38", () => {
    const h = ccSeedFields();
    expect(registerComboHit(h, 2, false)).toBe(1);
    expect(h.comboTime).toBe(COMBO_TIME_NORMAL);
    expect(registerComboHit(h, 2, false)).toBe(2);
    expect(registerComboHit(h, 2, true)).toBe(3);
    expect(h.comboTime).toBe(COMBO_TIME_FINISHER);
    expect(h.comboOwner).toBe(2);
  });

  it("등록: 소유자 변경·면역 중·타이머 만료면 1히트로 새 콤보", () => {
    const h = ccSeedFields();
    registerComboHit(h, 2, false);
    registerComboHit(h, 2, false);
    expect(registerComboHit(h, 5, false)).toBe(1); // 소유자 변경
    h.comboImmunity = 0.3;
    expect(registerComboHit(h, 5, false)).toBe(1); // 면역 중
    h.comboImmunity = 0;
    h.comboTime = 0;
    expect(registerComboHit(h, 5, false)).toBe(1); // 만료
  });
});

describe("히트스턴 — damage_system.gd:290-295", () => {
  it("지속 공식: 0.125 / 0.18 / 0.235 / 0.28 캡, 면역 중 0.04, chain +0.05", () => {
    expect(hitstunDuration(1, false, false)).toBeCloseTo(0.125, 10);
    expect(hitstunDuration(2, false, false)).toBeCloseTo(0.18, 10);
    expect(hitstunDuration(3, false, false)).toBeCloseTo(0.235, 10);
    expect(hitstunDuration(4, false, false)).toBeCloseTo(0.28, 10);
    expect(hitstunDuration(7, false, false)).toBeCloseTo(0.28, 10);
    expect(hitstunDuration(3, true, false)).toBeCloseTo(0.04, 10);
    expect(hitstunDuration(2, false, true)).toBeCloseTo(0.23, 10);
  });

  it("적용: max 승계, 슈퍼아머 활성이면 미적용, combo_hit 0 이면 미적용", () => {
    const h = ccSeedFields();
    applyHitstun(h, 2, false);
    expect(h.hitstunTime).toBeCloseTo(0.18, 10);
    applyHitstun(h, 1, false); // 0.125 < 0.18 → 유지
    expect(h.hitstunTime).toBeCloseTo(0.18, 10);
    h.superArmorTime = 1.0;
    applyHitstun(h, 4, false);
    expect(h.hitstunTime).toBeCloseTo(0.18, 10);
    const h2 = ccSeedFields();
    applyHitstun(h2, 0, false);
    expect(h2.hitstunTime).toBe(0);
  });
});

describe("이동 배율 — hero_movement.gd:57-69 / cpu_behavior.gd:137-138", () => {
  it("stun 은 locked, root 는 0, slow(cc)는 0.42", () => {
    const h = ccSeedFields();
    expect(movementControl(h)).toEqual({ locked: false, mult: 1 });
    h.stunTime = 0.5;
    expect(movementControl(h).locked).toBe(true);
    h.stunTime = 0;
    h.rootTime = 0.5;
    expect(movementControl(h).mult).toBe(0);
    h.rootTime = 0;
    h.ccTime = 0.5;
    expect(movementControl(h).mult).toBeCloseTo(0.42, 10);
  });

  it("히트스턴 OR 콤보캡처 x0.72 — 둘 다 있어도 한 번만(elif)", () => {
    const h = ccSeedFields();
    h.hitstunTime = 0.1;
    expect(movementControl(h).mult).toBeCloseTo(0.72, 10);
    h.comboCaptureTime = 0.4;
    expect(movementControl(h).mult).toBeCloseTo(0.72, 10); // 중복 없음
    h.hitstunTime = 0;
    expect(movementControl(h).mult).toBeCloseTo(0.72, 10);
    h.ccTime = 0.3;
    expect(movementControl(h).mult).toBeCloseTo(0.42 * 0.72, 10); // slow 와는 곱
  });

  it("CPU: root 0.35, 히트스턴/캡처 0.72, cc 와 곱", () => {
    const h = ccSeedFields();
    h.rootTime = 0.5;
    expect(cpuMovementMult(h)).toBeCloseTo(0.35, 10);
    h.ccTime = 0.5;
    expect(cpuMovementMult(h)).toBeCloseTo(0.42 * 0.35, 10);
    h.rootTime = 0;
    h.hitstunTime = 0.1;
    expect(cpuMovementMult(h)).toBeCloseTo(0.42 * 0.72, 10);
  });
});

describe("CC 적용·차단 — damage_system.gd:275-287", () => {
  it("slow 는 cc_time 만, root/stun 은 전용 타이머 + max 승계", () => {
    const h = ccSeedFields();
    expect(applyControl(h, 0.4, "slow")).toEqual({ applied: true, zeroVelocity: false, cancelCharge: false });
    expect(h.ccTime).toBe(0.4);
    expect(h.rootTime).toBe(0);
    const root = applyControl(h, 0.3, "root");
    expect(root.zeroVelocity).toBe(true);
    expect(h.ccTime).toBe(0.4); // max — 짧아지지 않음
    expect(h.rootTime).toBe(0.3);
    const stun = applyControl(h, 1.2, "stun");
    expect(stun.cancelCharge).toBe(true);
    expect(h.stunTime).toBe(1.2);
    expect(h.ccTime).toBe(1.2);
  });

  it("슈퍼아머 활성이면 CC 전체 스킵", () => {
    const h = ccSeedFields();
    h.superArmorTime = 1;
    expect(applyControl(h, 1.0, "stun").applied).toBe(false);
    expect(h.ccTime).toBe(0);
    expect(h.stunTime).toBe(0);
  });

  it("행동 차단: stun 만 공격 차단, root/stun 모빌리티 차단, 무력화 판정", () => {
    const h = ccSeedFields();
    h.ccTime = 0.4;
    expect(ccAllowsAttack(h)).toBe(true);
    expect(ccAllowsMobility(h)).toBe(true);
    expect(ccIncapacitated(h)).toBe(true);
    h.rootTime = 0.4;
    expect(ccAllowsAttack(h)).toBe(true);
    expect(ccAllowsMobility(h)).toBe(false);
    h.stunTime = 0.4;
    expect(ccAllowsAttack(h)).toBe(false);
  });
});

describe("가드·슈퍼아머 감쇄 — damage_system.gd:255-257, 317-320", () => {
  it("가드 중 피해 x0.55, 넉백 x0.52 — 비활성이면 원값", () => {
    const h = ccSeedFields();
    expect(applyGuard(h, 100, 50)).toEqual({ amount: 100, knockback: 50 });
    h.guardTime = 0.8;
    const out = applyGuard(h, 100, 50);
    expect(out.amount).toBeCloseTo(55, 10);
    expect(out.knockback).toBeCloseTo(26, 10);
  });

  it("슈퍼아머: 강도만큼 감쇄, |넉백| < 55 면 0", () => {
    const h = ccSeedFields();
    expect(armorScaledKnockback(h, 200)).toBe(200); // 비활성 통과
    h.superArmorTime = 1;
    h.superArmorStrength = 0.8;
    expect(armorScaledKnockback(h, 200)).toBe(0); // 200*0.2=40 < 55 → 무효
    expect(armorScaledKnockback(h, 400)).toBeCloseTo(80, 10);
    expect(armorScaledKnockback(h, -400)).toBeCloseTo(-80, 10);
  });

  it("피니셔 넉백: 부호 유지 + 104 가산", () => {
    expect(finisherKnockback(40)).toBeCloseTo(144, 10);
    expect(finisherKnockback(-40)).toBeCloseTo(-144, 10);
    expect(finisherKnockback(0)).toBeCloseTo(104, 10);
  });
});

describe("타이머 전이 — match_lifecycle.gd:53-87", () => {
  it("콤보 타이머 만료 시 리셋 + 면역 0.58", () => {
    const h = ccSeedFields();
    registerComboHit(h, 1, false);
    registerComboHit(h, 1, false);
    h.comboDamage = 30;
    const ticks = Math.ceil(COMBO_TIME_NORMAL / DT) + 1;
    for (let i = 0; i < ticks; i++) {tickCcTimers(h, DT);}
    expect(h.comboHits).toBe(0);
    expect(h.comboDamage).toBe(0);
    expect(h.comboOwner).toBe(-1);
    expect(h.comboImmunity).toBeGreaterThan(0);
    expect(h.comboImmunity).toBeLessThanOrEqual(COMBO_EXPIRE_IMMUNITY);
  });

  it("만료 틱에 면역은 max(현재, 0.58) — 큰 기존 면역 유지", () => {
    const h = ccSeedFields();
    h.comboTime = DT / 2;
    h.comboHits = 1;
    h.comboImmunity = 0.9;
    tickCcTimers(h, DT);
    expect(h.comboImmunity).toBeCloseTo(0.9 - DT, 10);
  });

  it("슈퍼아머 만료 시 강도 0, cc/root/stun/가드/히트스턴 0 바닥", () => {
    const h = ccSeedFields();
    h.superArmorTime = DT;
    h.superArmorStrength = 0.8;
    h.ccTime = DT / 2;
    h.rootTime = DT / 2;
    h.stunTime = DT / 2;
    h.guardTime = DT / 2;
    h.hitstunTime = DT / 2;
    h.comboCaptureTime = DT / 2;
    tickCcTimers(h, DT);
    expect(h.superArmorTime).toBe(0);
    expect(h.superArmorStrength).toBe(0);
    expect(h.ccTime).toBe(0);
    expect(h.rootTime).toBe(0);
    expect(h.stunTime).toBe(0);
    expect(h.guardTime).toBe(0);
    expect(h.hitstunTime).toBe(0);
    expect(h.comboCaptureTime).toBe(0);
  });
});

describe("콤보 브레이크 — active_item.gd:32-61 / damage_system.gd:190-208", () => {
  it("캡처 탈출: breakIncomingCombo 리셋 + 면역 max(,0.52) + 소유자 반환", () => {
    const h = ccSeedFields();
    registerComboHit(h, 3, false);
    h.comboCaptureTime = 0.4;
    const owner = breakIncomingCombo(h);
    expect(owner).toBe(3);
    expect(h.comboCaptureTime).toBe(0);
    expect(h.comboHits).toBe(0);
    expect(h.comboOwner).toBe(-1);
    expect(h.comboImmunity).toBeCloseTo(COMBO_BREAK_IMMUNITY, 10);
  });

  it("모빌리티: 캡처 중이면 escape, 히트만 있으면 combo_break(면역 0.72·히트스턴 해제)", () => {
    const captured = ccSeedFields();
    registerComboHit(captured, 2, false);
    captured.comboCaptureTime = 0.4;
    expect(mobilityComboBreak(captured)).toEqual({ kind: "escape", prevOwner: 2 });

    const hitOnly = ccSeedFields();
    registerComboHit(hitOnly, 4, false);
    hitOnly.hitstunTime = 0.2;
    const out = mobilityComboBreak(hitOnly);
    expect(out).toEqual({ kind: "combo_break", prevOwner: 4 });
    expect(hitOnly.comboImmunity).toBeCloseTo(COMBO_MOBILITY_IMMUNITY, 10);
    expect(hitOnly.hitstunTime).toBe(0);
    expect(hitOnly.comboHits).toBe(0);

    expect(mobilityComboBreak(ccSeedFields()).kind).toBe("none");
  });

  it("공격자 측 링크 해제: 대상 일치 시에만 리셋", () => {
    const attacker = { comboTarget: 5, normalStep: 2, normalChainTime: 0.3 };
    expect(clearAttackerComboLink(attacker, 1)).toBe(false);
    expect(attacker.comboTarget).toBe(5);
    expect(clearAttackerComboLink(attacker, 5)).toBe(true);
    expect(attacker).toEqual({ comboTarget: -1, normalStep: 0, normalChainTime: 0 });
  });
});

describe("hurtHero 파이프라인 부품 — 콤보/가드/CC/히트스턴", () => {
  it("장비 히트는 콤보 증폭 후 가드·히트스턴·root 를 적용한다", () => {
    const h = ccSeedFields();
    h.guardTime = 1;
    const comboHit = registerComboHit(h, 1, false);
    const amplified = 100 * comboAmplifier(comboHit);
    const guarded = applyGuard(h, amplified, 50);
    applyControl(h, 0.4, "root");
    applyHitstun(h, comboHit, false);
    expect(comboHit).toBe(1);
    expect(guarded.amount).toBeCloseTo(55, 10);
    expect(guarded.knockback).toBeCloseTo(26, 10);
    expect(h.rootTime).toBe(0.4);
    expect(h.hitstunTime).toBeCloseTo(0.125, 10);
  });

  it("총격은 히트스턴을 넣지 않고, 모빌리티는 콤보를 올리지 않는다", () => {
    const gun = ccSeedFields();
    const gunHit = registerComboHit(gun, 2, false);
    expect(gunHit).toBe(1);
    expect(gun.hitstunTime).toBe(0);

    const mob = ccSeedFields();
    applyControl(mob, 0.12, "slow");
    expect(mob.comboHits).toBe(0);
    expect(mob.ccTime).toBe(0.12);
  });

  it("normal_chain_time 만료 시 combo_target 과 normal_step 을 리셋한다", () => {
    const h = ccSeedFields();
    h.normalChainTime = DT / 2;
    h.normalStep = 2;
    h.comboTarget = 4;
    tickCcTimers(h, DT);
    expect(h.normalChainTime).toBe(0);
    expect(h.normalStep).toBe(0);
    expect(h.comboTarget).toBe(-1);
  });

  it("seed/apply/tick 별칭은 CC 적용과 타이머 소진을 연다", () => {
    const h = seed();
    expect(h).toEqual(ccSeedFields());
    const out = apply(h, 0.4, "root");
    expect(out.applied).toBe(true);
    expect(h.rootTime).toBe(0.4);
    h.comboHits = 2;
    h.comboTime = DT / 2;
    tick([h], DT);
    expect(h.comboHits).toBe(0);
    expect(h.comboImmunity).toBeCloseTo(COMBO_EXPIRE_IMMUNITY, 10);
  });
});
