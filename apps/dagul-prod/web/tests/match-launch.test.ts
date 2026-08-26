import { describe, expect, it } from "vitest";
import {
  apply,
  applyLaunch,
  chainTug,
  computeLaunchDecision,
  launchDirection,
  launchDuration,
  launchSeedFields,
  launchSpeed,
  moveLaunchedHero,
  seed,
  startLaunch,
  tick,
  tickLaunch,
  tickLaunchTrailFade,
  wallBounceAttackerCredit,
  type LaunchDecisionInput,
  type LaunchVictim,
  type LaunchedHero,
} from "@/lib/hub/match-launch";
import {
  apply as applyKnockout,
  applyLaunchKnockout,
  deathVelocity,
  seed as seedKnockouts,
  spawnLaunchKnockout,
  tick as tickKnockouts,
  tickLaunchKnockouts,
} from "@/lib/hub/match-launch-knockout";

const DT = 1 / 60;
const NO_COVERS: readonly never[] = [];

function decisionInput(over: Partial<LaunchDecisionInput>): LaunchDecisionInput {
  return {
    source: "normal",
    knockback: 0,
    guardTime: 0,
    heavyBlast: false,
    attackFinisher: false,
    superArmorTime: 0,
    superArmorStrength: 0,
    ...over,
  };
}

function launchedHero(over: Partial<LaunchedHero>): LaunchedHero {
  return {
    x: 3000,
    y: 3000,
    hp: 1000,
    guardTime: 0,
    launchTime: 0.5,
    launchVel: { x: 0, y: 0 },
    wallBounces: 0,
    launchOwner: 1,
    launchTrail: [],
    launchTrailFade: 0.34,
    launchWallDamage: 0,
    ...over,
  };
}

describe("런치 개시 공식", () => {
  it("건 전투 일반타는 런치 없이 마이크로 셔브 clamp(5+|kb|*0.35, 5, 16)", () => {
    const d = computeLaunchDecision(decisionInput({ knockback: 20 }));
    expect(d.launchKnockback).toBe(0);
    expect(d.shove).toBeCloseTo(12, 9);
    expect(computeLaunchDecision(decisionInput({ knockback: 100 })).shove).toBe(16);
    expect(computeLaunchDecision(decisionInput({ knockback: 1 })).shove).toBeCloseTo(5.35, 9);
    expect(computeLaunchDecision(decisionInput({ knockback: 0.005 })).shove).toBe(0);
    // 슈퍼아머 중에는 셔브도 없다.
    expect(computeLaunchDecision(decisionInput({ knockback: 20, superArmorTime: 1 })).shove).toBe(0);
  });

  it("피니셔는 |kb|+104, 가드는 kb*0.52 를 먼저 적용", () => {
    const fin = computeLaunchDecision(decisionInput({ knockback: 100, attackFinisher: true }));
    expect(fin.launchKnockback).toBeCloseTo(204, 9);
    const neg = computeLaunchDecision(decisionInput({ knockback: -100, attackFinisher: true }));
    expect(neg.launchKnockback).toBeCloseTo(-204, 9);
    const guarded = computeLaunchDecision(
      decisionInput({ knockback: 100, guardTime: 1, attackFinisher: true }),
    );
    expect(guarded.launchKnockback).toBeCloseTo(100 * 0.52 + 104, 9);
  });

  it("heavy blast·비총 소스는 kb 그대로, 슈퍼아머는 (1-strength) 감쇄·55 미만 취소", () => {
    const blast = computeLaunchDecision(decisionInput({ knockback: 80, heavyBlast: true }));
    expect(blast.launchKnockback).toBe(80);
    const skill = computeLaunchDecision(decisionInput({ source: "skill", knockback: 100 }));
    expect(skill.launchKnockback).toBe(100);
    const canceled = computeLaunchDecision(
      decisionInput({ source: "skill", knockback: 100, superArmorTime: 1, superArmorStrength: 0.5 }),
    );
    expect(canceled.launchKnockback).toBe(0);
    const reduced = computeLaunchDecision(
      decisionInput({ source: "skill", knockback: 100, superArmorTime: 1, superArmorStrength: 0.3 }),
    );
    expect(reduced.launchKnockback).toBeCloseTo(70, 9);
  });

  it("launch_speed=(900+|kb|*9.8)/weight, launch_time=clamp(0.22+|kb|*0.0022, 0.26, 0.72)", () => {
    expect(launchSpeed(104, 1)).toBeCloseTo(1919.2, 9);
    expect(launchSpeed(104, 2)).toBeCloseTo(959.6, 9);
    expect(launchDuration(104)).toBeCloseTo(0.22 + 104 * 0.0022, 9);
    expect(launchDuration(10)).toBe(0.26);
    expect(launchDuration(400)).toBe(0.72);
  });

  it("chain tug 는 min(20, max(0, 거리-55))", () => {
    expect(chainTug(50)).toBe(0);
    expect(chainTug(60)).toBe(5);
    expect(chainTug(200)).toBe(20);
  });

  it("런치 방향은 origin→victim, 제로면 aim, kb<=0 이면 반전", () => {
    const atk = { x: 100, y: 100 };
    const aim = { x: 0, y: 1 };
    const vic = { x: 200, y: 100 };
    expect(launchDirection({ x: 0, y: 0 }, atk, aim, vic, 100)).toEqual({ x: 1, y: 0 });
    expect(launchDirection({ x: 0, y: 0 }, atk, aim, vic, -100)).toEqual({ x: -1, y: -0 });
    expect(launchDirection({ x: 0, y: 0 }, { x: 200, y: 100 }, aim, vic, 100)).toEqual(aim);
    expect(launchDirection({ x: 200, y: 50 }, atk, aim, vic, 100)).toEqual({ x: 0, y: 1 });
  });

  it("launchSeedFields 는 game_world 초기값(런치 없음)이다", () => {
    expect(launchSeedFields()).toEqual({
      launchTime: 0, launchVel: { x: 0, y: 0 }, wallBounces: 0,
      launchOwner: -1, launchTrail: [], launchTrailFade: 0, launchWallDamage: 0,
    });
  });

  it("applyLaunch 는 건 일반타를 셔브하고 런치하지 않는다", () => {
    const h: LaunchVictim = { ...launchedHero({ x: 2000, y: 2000, launchTime: 0 }), comboCaptureTime: 0.4 };
    const out = applyLaunch(h, {
      source: "normal", knockback: 20, guardTime: 0, heavyBlast: false, attackFinisher: false,
      superArmorTime: 0, superArmorStrength: 0,
      impactOrigin: { x: 1990, y: 2000 }, attackerPos: { x: 1990, y: 2000 },
      attackerAim: { x: 1, y: 0 }, weight: 1, owner: 1, comboDamage: 10, covers: NO_COVERS,
    });
    expect(out.launched).toBe(false);
    expect(out.shove).toBeCloseTo(12, 9);
    expect(h.x).toBeCloseTo(2012, 9);
    expect(h.launchTime).toBe(0);
  });

  it("applyLaunch 는 비총 넉백으로 런치를 열고 chain tug 는 공격자 쪽으로 끈다", () => {
    const launched = launchedHero({ x: 2000, y: 2000, launchTime: 0 });
    const out = applyLaunch(launched, {
      source: "equipment", knockback: 100, guardTime: 0, heavyBlast: false, attackFinisher: false,
      superArmorTime: 0, superArmorStrength: 0,
      impactOrigin: { x: 1900, y: 2000 }, attackerPos: { x: 1900, y: 2000 },
      attackerAim: { x: 1, y: 0 }, weight: 1, owner: 2, comboDamage: 30, covers: NO_COVERS,
    });
    expect(out.launched).toBe(true);
    expect(out.launchKnockback).toBe(100);
    expect(launched.launchVel.x).toBeCloseTo(1880, 9);
    expect(launched.launchOwner).toBe(2);
    expect(launched.launchWallDamage).toBe(30);

    const tugged = launchedHero({ x: 2100, y: 2000, launchTime: 0 });
    applyLaunch(tugged, {
      source: "normal", knockback: 6, guardTime: 0, heavyBlast: false, attackFinisher: false,
      superArmorTime: 0, superArmorStrength: 0,
      impactOrigin: { x: 2000, y: 2000 }, attackerPos: { x: 2000, y: 2000 },
      attackerAim: { x: 1, y: 0 }, weight: 1, owner: 0, comboDamage: 0, covers: NO_COVERS,
      chainWeapon: true,
    });
    // 셔브 +x 후 dist 가 55 보다 크면 공격자(-x) 쪽으로 min(20, dist-55)
    expect(tugged.x).toBeLessThan(2100);
  });

  it("startLaunch 는 원본 필드 세트를 만든다", () => {
    const st = startLaunch({
      pos: { x: 10, y: 20 }, direction: { x: 1, y: 0 }, launchKnockback: 104,
      weight: 1, owner: 3, source: "normal", comboDamage: 42,
    });
    expect(st.launchVel.x).toBeCloseTo(1919.2, 9);
    expect(st.launchTime).toBeCloseTo(0.4488, 9);
    expect(st.wallBounces).toBe(0);
    expect(st.launchOwner).toBe(3);
    expect(st.launchTrail).toEqual([{ x: 10, y: 20 }]);
    expect(st.launchTrailFade).toBe(0.34);
    expect(st.launchWallDamage).toBe(42);
    const mob = startLaunch({
      pos: { x: 0, y: 0 }, direction: { x: 1, y: 0 }, launchKnockback: 104,
      weight: 1, owner: 3, source: "mobility", comboDamage: 42,
    });
    expect(mob.launchWallDamage).toBe(0);
  });
});

describe("벽 튕김", () => {
  it("반사 -0.84 후 속도로 벽 데미지 clamp(9+v/78, 15, 36)", () => {
    const h = launchedHero({ x: 130, y: 2000, launchVel: { x: -600, y: 0 } });
    const ev = moveLaunchedHero(h, DT, 1, NO_COVERS);
    expect(ev.bounced).toBe(true);
    // -600 * -0.84 = 504 → 9 + 504/78
    expect(ev.wallDamage).toBeCloseTo(9 + 504 / 78, 9);
    expect(h.hp).toBeCloseTo(1000 - (9 + 504 / 78), 9);
    expect(h.launchWallDamage).toBeCloseTo(9 + 504 / 78, 9);
    expect(h.wallBounces).toBe(1);
    // 반사 + 감쇠된 속도
    expect(h.launchVel.x).toBeCloseTo(504 * Math.exp(-0.62 * DT), 9);
    expect(h.x).toBe(130);
  });

  it("벽 데미지는 15 미만·36 초과로 벗어나지 않고 가드 시 0.55 배", () => {
    const slow = launchedHero({ x: 124.5, y: 2000, launchVel: { x: -100, y: 0 } });
    expect(moveLaunchedHero(slow, DT, 1, NO_COVERS).wallDamage).toBe(15);
    const fast = launchedHero({ x: 200, y: 2000, launchVel: { x: -6000, y: 0 } });
    expect(moveLaunchedHero(fast, DT, 1, NO_COVERS).wallDamage).toBe(36);
    const guarded = launchedHero({ x: 200, y: 2000, launchVel: { x: -6000, y: 0 }, guardTime: 1 });
    expect(moveLaunchedHero(guarded, DT, 1, NO_COVERS).wallDamage).toBeCloseTo(36 * 0.55, 9);
  });

  it("벽 데미지로 hp<=0 이면 즉시 반환 (시간 감쇠 없음)", () => {
    const h = launchedHero({ x: 130, y: 2000, launchVel: { x: -600, y: 0 }, hp: 10 });
    const ev = moveLaunchedHero(h, DT, 1, NO_COVERS);
    expect(ev.died).toBe(true);
    expect(ev.ended).toBe(false);
    expect(h.hp).toBeLessThanOrEqual(0);
    expect(h.launchTime).toBe(0.5);
  });

  it("3바운스면 런치가 즉시 끝나고 속도 0", () => {
    const h = launchedHero({});
    for (let i = 0; i < 3; i += 1) {
      h.x = 130;
      h.y = 2000;
      h.launchVel = { x: -600, y: 0 };
      h.launchTime = 0.5;
      moveLaunchedHero(h, DT, 1, NO_COVERS);
    }
    expect(h.wallBounces).toBe(3);
    expect(h.launchTime).toBe(0);
    expect(h.launchVel).toEqual({ x: 0, y: 0 });
  });

  it("자유 비행은 exp(-0.62*dt) 감쇠, 속도 80 미만이면 종료", () => {
    const h = launchedHero({ launchVel: { x: 400, y: 0 }, launchTime: 10 });
    const ev = moveLaunchedHero(h, DT, 1, NO_COVERS);
    expect(ev.ended).toBe(false);
    expect(h.x).toBeCloseTo(3000 + 400 * DT, 9);
    expect(h.launchVel.x).toBeCloseTo(400 * Math.exp(-0.62 * DT), 9);
    const slow = launchedHero({ launchVel: { x: 79, y: 0 }, launchTime: 10 });
    expect(moveLaunchedHero(slow, DT, 1, NO_COVERS).ended).toBe(true);
    expect(slow.launchTime).toBe(0);
    expect(slow.launchVel).toEqual({ x: 0, y: 0 });
  });
});

describe("트레일 링버퍼", () => {
  it("짝수 tick 마다 기록하고 14점을 넘으면 앞에서 버린다", () => {
    const st = startLaunch({
      pos: { x: 3000, y: 3000 }, direction: { x: 1, y: 0 }, launchKnockback: 104,
      weight: 1, owner: 0, source: "normal", comboDamage: 0,
    });
    const h = launchedHero({ ...st, launchTime: 10 });
    for (let tick = 0; tick < 4; tick += 1) {moveLaunchedHero(h, DT, tick, NO_COVERS);}
    expect(h.launchTrail).toHaveLength(3); // 시작 1점 + tick 0, 2
    for (let tick = 4; tick < 39; tick += 1) {moveLaunchedHero(h, DT, tick, NO_COVERS);}
    expect(h.launchTrail).toHaveLength(14);
    expect(h.launchTrail[0]).not.toEqual({ x: 3000, y: 3000 });
    expect(h.launchTrail[13]).toEqual({ x: h.x, y: h.y });
  });

  it("트레일 페이드는 런치 중 0.34 유지, 종료 후 감쇠·0 에서 트레일 소거", () => {
    const h = { launchTime: 0.2, launchTrailFade: 0.1, launchTrail: [{ x: 1, y: 2 }] };
    tickLaunchTrailFade(h, DT);
    expect(h.launchTrailFade).toBe(0.34);
    h.launchTime = 0;
    tickLaunchTrailFade(h, DT);
    expect(h.launchTrailFade).toBeCloseTo(0.34 - DT, 9);
    expect(h.launchTrail).toHaveLength(1);
    for (let i = 0; i < 21; i += 1) {tickLaunchTrailFade(h, DT);}
    expect(h.launchTrailFade).toBe(0);
    expect(h.launchTrail).toHaveLength(0);
  });
});

describe("넉아웃 시체 물리", () => {
  it("벽 반사 -0.82, 감쇠 exp(-0.48*dt)", () => {
    const k = spawnLaunchKnockout(0, { x: 110, y: 2000 }, { x: -600, y: 0 });
    const list = [k];
    const bounces = tickLaunchKnockouts(list, DT, 1, NO_COVERS);
    expect(bounces).toEqual([{ slot: 0, x: 110, y: 2000 }]);
    expect(k.bounces).toBe(1);
    expect(k.pos.x).toBe(110);
    expect(k.vel.x).toBeCloseTo(-600 * -0.82 * Math.exp(-0.48 * DT), 9);
    const free = spawnLaunchKnockout(1, { x: 3000, y: 3000 }, { x: 600, y: 0 });
    const list2 = [free];
    tickLaunchKnockouts(list2, DT, 1, NO_COVERS);
    expect(free.pos.x).toBeCloseTo(3000 + 600 * DT, 9);
    expect(free.vel.x).toBeCloseTo(600 * Math.exp(-0.48 * DT), 9);
  });

  it("3바운스면 finished·속도 0·time 은 0.42 로 캡", () => {
    const k = spawnLaunchKnockout(0, { x: 110, y: 2000 }, { x: -600, y: 0 });
    const list = [k];
    for (let i = 0; i < 3; i += 1) {
      k.pos = { x: 110, y: 2000 };
      k.vel = { x: -600, y: 0 };
      tickLaunchKnockouts(list, DT, 1, NO_COVERS);
    }
    expect(k.finished).toBe(true);
    expect(k.vel).toEqual({ x: 0, y: 0 });
    expect(k.time).toBe(0.42);
    // finished 후에는 물리 없이 time 만 줄고, 0 이하면 제거된다.
    tickLaunchKnockouts(list, DT, 1, NO_COVERS);
    expect(k.pos).toEqual({ x: 110, y: 2000 });
    expect(k.time).toBeCloseTo(0.42 - DT, 9);
    for (let i = 0; i < 30; i += 1) {tickLaunchKnockouts(list, DT, 1, NO_COVERS);}
    expect(list).toHaveLength(0);
  });

  it("트레일은 짝수 tick 기록·20점 캡", () => {
    const k = spawnLaunchKnockout(0, { x: 3000, y: 3000 }, { x: 300, y: 0 });
    const list = [k];
    for (let tick = 0; tick < 60; tick += 1) {tickLaunchKnockouts(list, DT, tick, NO_COVERS);}
    expect(k.trail).toHaveLength(20);
    expect(k.trail[0]).not.toEqual({ x: 3000, y: 3000 });
  });

  it("death_velocity 는 450 미만이면 fallback*1550, 이상이면 1.35배(최소 1550)", () => {
    expect(deathVelocity({ x: 100, y: 0 }, { x: 0, y: 1 })).toEqual({ x: 0, y: 1550 });
    const carried = deathVelocity({ x: 2000, y: 0 }, { x: 0, y: 1 });
    expect(carried.x).toBeCloseTo(2700, 9);
    const floored = deathVelocity({ x: 1000, y: 0 }, { x: 0, y: 1 });
    expect(floored.x).toBeCloseTo(1550, 9);
  });

  it("applyLaunchKnockout 은 death_velocity 를 입혀 시체를 만든다", () => {
    const k = applyLaunchKnockout(3, { x: 10, y: 20 }, { x: 100, y: 0 }, { x: 0, y: 1 });
    expect(k.slot).toBe(3);
    expect(k.vel).toEqual({ x: 0, y: 1550 });
    expect(k.time).toBe(2.15);
    expect(k.trail).toEqual([{ x: 10, y: 20 }]);
  });
});

describe("tick/seed/apply 진입점", () => {
  it("tickLaunch 는 launchTime>0 만 이동하고 벽 크레딧 공식은 1.25/0.45", () => {
    const flying = launchedHero({ launchVel: { x: 400, y: 0 }, launchTime: 1 });
    const idle = launchedHero({ x: 1000, y: 1000, launchTime: 0 });
    const events = tickLaunch([flying, idle], DT, 1, NO_COVERS);
    expect(events).toHaveLength(1);
    expect(flying.x).toBeCloseTo(3000 + 400 * DT, 9);
    expect(idle.x).toBe(1000);
    const credit = wallBounceAttackerCredit(20);
    expect(credit).toEqual({ damageDealt: 20, score: 25, threat: 9 });
  });

  it("seed/apply/tick 별칭은 런치 개시·이동과 같다", () => {
    expect(seed()).toEqual(launchSeedFields());
    const h: LaunchVictim = { ...launchedHero({ x: 2000, y: 2000, launchTime: 0 }), comboCaptureTime: 0 };
    const out = apply(h, {
      source: "equipment", knockback: 100, guardTime: 0, heavyBlast: false, attackFinisher: false,
      superArmorTime: 0, superArmorStrength: 0,
      impactOrigin: { x: 1900, y: 2000 }, attackerPos: { x: 1900, y: 2000 },
      attackerAim: { x: 1, y: 0 }, weight: 1, owner: 2, comboDamage: 30, covers: NO_COVERS,
    });
    expect(out).toEqual(applyLaunch(launchedHero({ x: 2000, y: 2000, launchTime: 0 }), {
      source: "equipment", knockback: 100, guardTime: 0, heavyBlast: false, attackFinisher: false,
      superArmorTime: 0, superArmorStrength: 0,
      impactOrigin: { x: 1900, y: 2000 }, attackerPos: { x: 1900, y: 2000 },
      attackerAim: { x: 1, y: 0 }, weight: 1, owner: 2, comboDamage: 30, covers: NO_COVERS,
    }));
    expect(h.launchTime).toBeGreaterThan(0);
    const before = h.x;
    tick([h], DT, 1, NO_COVERS);
    expect(h.x).toBeGreaterThan(before);
  });

  it("넉아웃 seed 는 빈 리스트, apply/tick 은 death_velocity 시체 물리", () => {
    expect(seedKnockouts()).toEqual([]);
    const k = applyKnockout(3, { x: 10, y: 20 }, { x: 100, y: 0 }, { x: 0, y: 1 });
    expect(k.vel).toEqual({ x: 0, y: 1550 });
    const list = [k];
    tickKnockouts(list, DT, 1, NO_COVERS);
    expect(k.pos.y).toBeCloseTo(20 + 1550 * DT, 9);
  });
});
