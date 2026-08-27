import { afterEach, describe, expect, it, vi } from "vitest";
import { createEffectStore } from "@/lib/hub/match-effects";
import { makeEquipment } from "@/lib/hub/match-equipment";
import { gunSeedFields, type GunHero } from "@/lib/hub/match-gun";
import {
  CHARGE_MAX, applyEquipmentAttack, applySkillInput, beginSkillCharge, lerp,
  releaseSkillCharge, type SkillHero,
} from "@/lib/hub/match-skill";
import { SLIDE_ACCEL, SLIDE_DURATION, SPRING_BOOST, steerSlide } from "@/lib/hub/match-loot";
import { MatchSim } from "@/lib/hub/match-sim";

const DT = 1 / 60;

function hero(id: string, over: Partial<GunHero> = {}): GunHero {
  const eq = makeEquipment(id);
  return {
    slot: 0, x: 4000, y: 2400, hp: eq.maxHp, maxHp: eq.maxHp, alive: true,
    stunTime: 0, launchTime: 0, rootTime: 0, facingX: 1, facingY: 0, aimX: 1, aimY: 0,
    ...gunSeedFields(eq), ...over, equipment: over.equipment ?? eq,
  };
}

describe("차지 릴리즈 발동", () => {
  it("누르면 차지 시작, 떼면 charge_ratio 로 scatter 펠릿이 나간다", () => {
    const h = hero("scatter");
    const start = applySkillInput(h, true, true, false, DT, { x: 1, y: 0 }, []);
    expect(start.fired).toBe(false);
    expect(h.chargingSkill).toBe(true);
    const charged: SkillHero = h;
    expect(charged.action).toBe("CHARGING_SKILL");
    applySkillInput(h, true, false, false, CHARGE_MAX, { x: 1, y: 0 }, []);
    expect(h.chargeTime).toBeCloseTo(CHARGE_MAX, 8);
    const shot = applySkillInput(h, false, false, true, DT, { x: 1, y: 0 }, []);
    expect(shot.fired).toBe(true);
    expect(h.chargingSkill).toBe(false);
    expect(shot.projectiles).toHaveLength(7);
    expect(shot.projectiles[0]?.source).toBe("equipment");
    expect(shot.projectiles[0]?.kind).toBe("pellet");
    const power = lerp(0.65, 1.25, 1);
    expect(shot.projectiles[0]?.damage).toBeCloseTo(7.0 * power, 8);
  });

  it("DAGUL_SKILLS=off 이면 applyHero 가 우클릭 스킬을 무시한다", () => {
    vi.stubEnv("DAGUL_SKILLS", "off");
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const h = sim.heroes.get(0);
    expect(h).toBeDefined();
    if (!h) {return;}
    h.equipment = makeEquipment("rail");
    sim.pushInput(0, { equipment: true, equipmentPressed: true, aimX: h.x + 100, aimY: h.y, seq: 1 });
    sim.step(DT);
    expect(h.chargingSkill).toBe(false);
    sim.pushInput(0, { equipment: false, equipmentReleased: true, aimX: h.x + 100, aimY: h.y, seq: 2 });
    sim.step(DT);
    expect([...sim.bullets.values()].filter((b) => b.source === "equipment")).toHaveLength(0);
  });

  it("DAGUL_SKILLS=on 이면 MatchSim 우클릭 홀드→릴리즈가 장비 탄을 넣는다", () => {
    vi.stubEnv("DAGUL_SKILLS", "on");
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const h = sim.heroes.get(0);
    expect(h).toBeDefined();
    if (!h) {return;}
    h.equipment = makeEquipment("rail");
    sim.pushInput(0, { equipment: true, equipmentPressed: true, aimX: h.x + 100, aimY: h.y, seq: 1 });
    sim.step(DT);
    expect(h.chargingSkill).toBe(true);
    sim.pushInput(0, { equipment: true, aimX: h.x + 100, aimY: h.y, seq: 2 });
    for (let i = 0; i < 70; i += 1) {sim.step(DT);}
    sim.pushInput(0, { equipment: false, equipmentReleased: true, aimX: h.x + 100, aimY: h.y, seq: 3 });
    sim.step(DT);
    expect(h.chargingSkill).toBe(false);
    expect(h.equipmentCd).toBeCloseTo(3.50, 5);
    const shots = [...sim.bullets.values()].filter((b) => b.source === "equipment");
    expect(shots.length).toBeGreaterThanOrEqual(1);
    expect(shots[0]?.kind).toBe("beam");
    expect(shots[0]?.pierce).toBe(4);
  });
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("우클릭 스킬 대시 — 얇은 벽 관통 회귀", () => {
  // 회귀: 이동 대시(match-gun.ts)를 스윕으로 고친 것과 같은 버그가 우클릭
  // 스킬 대시(match-skill.ts dash())에도 있었다 — blade 풀차지 대시는
  // 190*reach(≈224px)로 얇은 커버 반지름(35px)을 가볍게 넘겨서 시작점·도착점
  // 둘 다 커버 밖이면 충돌 판정이 비어 벽을 관통했다.
  it("blade 풀차지 CROSS STEP 대시는 얇은 벽을 관통하지 않는다", () => {
    const h = hero("blade");
    h.x = 550;
    h.y = 300;
    const covers = [{ x: 400, y: 377, w: 300, h: 70 }]; // 중심 (550,412), r=35
    const result = applyEquipmentAttack(h, { x: 0, y: 1 }, 1, covers);
    expect(result.fired).toBe(true);
    expect(h.y).toBeLessThan(412 - 35 + 1);
    expect(h.y).toBeLessThan(300 + 224.2 - 100);
  });
});

describe("쿨다운 소모", () => {
  it("발동 시 charge_release 와 무기별 이펙트를 방출한다", () => {
    const store = createEffectStore();
    const rail = hero("rail");
    applyEquipmentAttack(rail, { x: 1, y: 0 }, 1, [], store);
    expect(store.items.some((e) => e.kind === "charge_release")).toBe(true);
    expect(store.items.some((e) => e.kind === "line")).toBe(true);
    const scatter = hero("scatter");
    const scatterStore = createEffectStore();
    applyEquipmentAttack(scatter, { x: 1, y: 0 }, 1, [], scatterStore);
    expect(scatterStore.items.some((e) => e.kind === "cast")).toBe(true);
  });

  it("풀차지 rail 은 cooldown 3.50 을 넣고 재발동을 막는다", () => {
    const h = hero("rail");
    const first = applyEquipmentAttack(h, { x: 1, y: 0 }, 1);
    expect(first.fired).toBe(true);
    expect(h.equipmentCd).toBe(3.50);
    expect(first.projectiles[0]?.pierce).toBe(4);
    expect(first.projectiles[0]?.ccTime).toBeCloseTo(1.20, 8);
    const second = applyEquipmentAttack(h, { x: 1, y: 0 }, 1);
    expect(second.fired).toBe(false);
    expect(second.projectiles).toHaveLength(0);
  });

  it("bomb 은 마인을 놓고 shield 는 벽을 놓으며 cooldown 을 소모한다", () => {
    const bomb = hero("bomb");
    const mine = applyEquipmentAttack(bomb, { x: 1, y: 0 }, 0);
    expect(mine.fired).toBe(true);
    expect(mine.mine).not.toBeNull();
    expect(mine.mine?.lifetime).toBe(8.0);
    expect(mine.mine?.fuseTime).toBe(0.38);
    expect(mine.mine?.armTime).toBeCloseTo(0.72, 8);
    expect(bomb.equipmentCd).toBe(4.40);
    const shield = hero("shield");
    const wall = applyEquipmentAttack(shield, { x: 0, y: 1 }, 1);
    expect(wall.wall).not.toBeNull();
    expect(wall.wall?.speed).toBeCloseTo(720.0, 8);
    expect(shield.equipmentCd).toBe(5.60);
    expect(shield.guardTime).toBeCloseTo(0.90, 8);
  });
});

describe("slide 물리", () => {
  it("steer_slide 는 가속 520·마찰 180 을 쓴다", () => {
    const body = { vx: 0, vy: 0, vel: { x: 0, y: 0 }, facingX: 1, facingY: 0, slideTime: SLIDE_DURATION, springTime: 0, evadeTime: 0, hopTime: 0, hopMax: 0, hopHeight: 0, heldItem: "slide" };
    steerSlide(body, 1, 0, 400, DT);
    expect(body.vx).toBeCloseTo(SLIDE_ACCEL * DT, 8);
    expect(body.vy).toBe(0);
    body.vx = 200;
    steerSlide(body, 0, 0, 400, DT);
    expect(body.vx).toBeCloseTo(200 - 180 * DT, 8);
  });

  it("MatchSim 에서 slideTime 중 입력이 속도를 쌓는다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const h = sim.heroes.get(0);
    expect(h).toBeDefined();
    if (!h) {return;}
    const x0 = h.x;
    h.slideTime = SLIDE_DURATION;
    h.vx = 0;
    h.vy = 0;
    sim.pushInput(0, { mx: 1, my: 0, seq: 1 });
    sim.step(DT);
    expect(h.vx).toBeCloseTo(SLIDE_ACCEL * DT, 6);
    expect(h.x).toBeGreaterThan(x0);
    expect(h.slideTime).toBeCloseTo(SLIDE_DURATION - DT, 6);
  });

  it("spring_time 중 이동에 SPRING_BOOST 220 이 더해진다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const h = sim.heroes.get(0);
    expect(h).toBeDefined();
    if (!h) {return;}
    h.springTime = 0.45;
    sim.pushInput(0, { mx: 1, my: 0, seq: 1 });
    sim.step(DT);
    expect(h.vx).toBeCloseTo(h.equipment.moveSpeed + SPRING_BOOST, 5);
  });
});

describe("차지 가드", () => {
  it("begin 은 cd/런치/스턴에서 막고, 릴리즈는 charging 이 아니면 무동작", () => {
    const blocked = hero("rail", { equipmentCd: 1 });
    expect(beginSkillCharge(blocked, { x: 1, y: 0 })).toBe(false);
    const idle = hero("rail");
    const none = releaseSkillCharge(idle, { x: 1, y: 0 });
    expect(none.fired).toBe(false);
  });
});
