import { describe, expect, it } from "vitest";
import {
  ARENA_CENTER,
  ARENA_SIZE,
  CPU_RANGE_SLACK,
  CPU_TARGET_RANGE,
  FIRE_INTERVAL,
  MATCH_DMG_TIME_CAP,
  MATCH_DMG_TIME_SPAN,
  MATCH_DMG_TIME_START,
  MatchSim,
  PROJECTILE_LEECH_MUL,
  PROJECTILE_SPLASH_MUL,
  RELOAD_TIME,
  clampArena,
  cpuAdvanceWeight,
  matchTimeDamageScale,
  spawnPoint,
} from "@/lib/hub/match-sim";
import { hopLift, muzzleWorldPos, RADIUS_FIRE_MUL } from "@/lib/hub/match-gun";
import { SHOVE_BASE, SHOVE_KB_MUL, SHOVE_MAX } from "@/lib/hub/match-launch";
import { idForBind, matchBindKey } from "@/lib/characters";
import type { SimBullet } from "@/lib/hub/match-sim";

describe("MatchSim", () => {
  it("스폰은 풀맵 안이고 좌석마다 갈라진다", () => {
    const a = spawnPoint(0, 2);
    const b = spawnPoint(1, 2);
    expect(a.x).toBeGreaterThan(100);
    expect(a.x).toBeLessThan(ARENA_SIZE.x - 100);
    expect(Math.hypot(a.x - b.x, a.y - b.y)).toBeGreaterThan(400);
  });

  it("클램프는 옛 섬 반경으로 끌어당기지 않는다", () => {
    const mid = clampArena(ARENA_CENTER.x, ARENA_CENTER.y);
    expect(mid.x).toBeCloseTo(ARENA_CENTER.x);
    expect(mid.y).toBeCloseTo(ARENA_CENTER.y);
  });

  it("양쪽 입력을 같은 권위로 적용한다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }]);
    sim.countdown = 0;
    const h0 = sim.heroes.get(0);
    const h1 = sim.heroes.get(1);
    expect(h0 && h1).toBeTruthy();
    if (!h0 || !h1) {return;}
    const x0 = h0.x;
    const x1 = h1.x;
    sim.pushInput(0, { mx: 1, my: 0, seq: 1 });
    sim.pushInput(1, { mx: -1, my: 0, seq: 1 });
    sim.step(1 / 60);
    expect(h0.x).toBeGreaterThan(x0);
    expect(h1.x).toBeLessThan(x1);
    // 이동속도는 캐릭터별 equipment.moveSpeed 가 기준 (원본 hero_movement.gd:436)
    expect(h0.x - x0).toBeCloseTo(h0.equipment.moveSpeed / 60, 0);
  });

  it("발사하면 id·속도가 있는 탄이 생기고 쿨다운을 가진다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const hero = sim.heroes.get(0);
    expect(hero).toBeDefined();
    if (!hero) {return;}
    sim.pushInput(0, { fire: true, aimX: hero.x + 100, aimY: hero.y, seq: 2 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
    const shot = [...sim.bullets.values()][0];
    expect(shot.id).toBe(1);
    expect(shot.owner).toBe(0);
    expect(shot.vx).toBeGreaterThan(0);
    expect(sim.fx).toHaveLength(1);
    sim.pushInput(0, { fire: true, aimX: hero.x + 100, aimY: hero.y, seq: 3 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
    expect(hero.fireCd).toBeGreaterThan(FIRE_INTERVAL - 0.03);
  });

  it("CPU 는 살아있는 상대를 향해 움직인다", () => {
    const sim = new MatchSim([{ slot: 0, name: "나" }, { slot: 1, name: "CPU2", cpu: true }]);
    sim.countdown = 0;
    const human = sim.heroes.get(0);
    const cpu = sim.heroes.get(1);
    expect(human && cpu).toBeTruthy();
    if (!human || !cpu) {return;}
    expect(cpu.cpu).toBe(true);
    const dist0 = Math.hypot(cpu.x - human.x, cpu.y - human.y);
    sim.step(1 / 60);
    const dist1 = Math.hypot(cpu.x - human.x, cpu.y - human.y);
    expect(dist1).toBeLessThan(dist0);
  });

  it("탄이 상대를 맞히면 HP 가 줄고 탄이 사라진다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    expect(a && b).toBeTruthy();
    if (!a || !b) {return;}
    b.x = a.x + 110;
    b.y = a.y;
    for (let i = 0; i < 40 && b.hp >= b.maxHp; i++) {
      sim.pushInput(0, { fire: true, firePressed: i === 0, aimX: b.x, aimY: b.y, seq: i + 1 });
      sim.step(1 / 60);
    }
    expect(b.hp).toBeLessThan(b.maxHp);
  });

  it("탄창이 비면 재장전 후 다시 발사한다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const hero = sim.heroes.get(0);
    expect(hero).toBeDefined();
    if (!hero) {return;}
    hero.mag = 0;
    const wait = Math.ceil(Math.max(RELOAD_TIME, hero.equipment.reloadTime) * 60) + 2;
    for (let i = 0; i < wait; i++) {
      sim.pushInput(0, { fire: true, aimX: hero.x + 80, aimY: hero.y, seq: i + 1 });
      sim.step(1 / 60);
    }
    expect(hero.mag).toBeLessThan(hero.magMax);
    expect(sim.bullets.size).toBeGreaterThan(0);
  });

  it("CPU 는 탄이 닿지 않는 거리에서 탄창을 비우지 않는다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1, cpu: true }]);
    sim.countdown = 0;
    const human = sim.heroes.get(0);
    const cpu = sim.heroes.get(1);
    expect(human && cpu).toBeTruthy();
    if (!human || !cpu) {return;}
    cpu.x = human.x + 900;
    cpu.y = human.y;
    sim.step(1 / 60);
    expect(cpu.mag).toBe(cpu.magMax);
    expect(sim.bullets.size).toBe(0);
  });

  it("CPU 는 사람이 고른 캐릭터를 피해서 배정받는다", () => {
    const key = matchBindKey();
    const humanPick = idForBind(key, 1);
    expect(humanPick).toBeDefined();
    const sim = new MatchSim([
      { slot: 0, name: "나", characterId: humanPick },
      { slot: 1, name: "CPU2", cpu: true },
    ]);
    sim.countdown = 0;
    const cpu = sim.heroes.get(1);
    expect(cpu).toBeDefined();
    if (!cpu) {return;}
    expect(cpu.characterId).not.toBe("");
    expect(cpu.characterId).not.toBe(humanPick);
  });

  it("사람 1 + CPU 7 좌석은 캐릭터가 전부 서로 다르다", () => {
    const key = matchBindKey();
    const seats = [
      { slot: 0, name: "나", characterId: idForBind(key, 3) },
      ...[1, 2, 3, 4, 5, 6, 7].map((slot) => ({ slot, name: `CPU${slot + 1}`, cpu: true })),
    ];
    const sim = new MatchSim(seats);
    sim.countdown = 0;
    const ids = [...sim.heroes.values()].map((h) => h.characterId);
    expect(ids.every((id) => id !== "")).toBe(true);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("CPU 는 목표 거리 부근에 도달하면 접근을 멈춘다", () => {
    expect(cpuAdvanceWeight(CPU_TARGET_RANGE)).toBe(0);
    expect(cpuAdvanceWeight(CPU_TARGET_RANGE + CPU_RANGE_SLACK * 2)).toBe(1);
    expect(cpuAdvanceWeight(CPU_TARGET_RANGE - CPU_RANGE_SLACK * 2)).toBe(-1);
    const sim = new MatchSim([{ slot: 0 }, { slot: 1, cpu: true }]);
    sim.countdown = 0;
    const human = sim.heroes.get(0);
    const cpu = sim.heroes.get(1);
    expect(human && cpu).toBeTruthy();
    if (!human || !cpu) {return;}
    human.x = ARENA_CENTER.x;
    human.y = ARENA_CENTER.y;
    human.maxHp = 1e9;
    human.hp = 1e9;
    cpu.x = human.x + 900;
    cpu.y = human.y;
    for (let i = 0; i < 400; i++) {sim.step(1 / 60);}
    const dist = Math.hypot(cpu.x - human.x, cpu.y - human.y);
    expect(dist).toBeLessThan(CPU_TARGET_RANGE + CPU_RANGE_SLACK + 150);
    expect(dist).toBeGreaterThan(CPU_TARGET_RANGE - CPU_RANGE_SLACK - 50);
  });

  it("CPU 는 너무 가까우면 목표 거리까지 물러난다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1, cpu: true }]);
    sim.countdown = 0;
    const human = sim.heroes.get(0);
    const cpu = sim.heroes.get(1);
    expect(human && cpu).toBeTruthy();
    if (!human || !cpu) {return;}
    human.x = ARENA_CENTER.x;
    human.y = ARENA_CENTER.y;
    human.maxHp = 1e9;
    human.hp = 1e9;
    cpu.x = human.x + 100;
    cpu.y = human.y;
    for (let i = 0; i < 120; i++) {sim.step(1 / 60);}
    const dist = Math.hypot(cpu.x - human.x, cpu.y - human.y);
    expect(dist).toBeGreaterThan(CPU_TARGET_RANGE - CPU_RANGE_SLACK - 40);
  });

  it("CPU 는 일직선 돌진이 아니라 측면 이동을 섞는다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1, cpu: true }]);
    sim.countdown = 0;
    const human = sim.heroes.get(0);
    const cpu = sim.heroes.get(1);
    expect(human && cpu).toBeTruthy();
    if (!human || !cpu) {return;}
    human.x = ARENA_CENTER.x;
    human.y = ARENA_CENTER.y;
    cpu.x = human.x + 900;
    cpu.y = human.y;
    sim.step(1 / 60);
    expect(cpu.y).not.toBe(human.y);
  });

  it("가까이 겹친 CPU 끼리는 서로 흩어진다", () => {
    const sim = new MatchSim([
      { slot: 0, cpu: true },
      { slot: 1, cpu: true },
    ]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    expect(a && b).toBeTruthy();
    if (!a || !b) {return;}
    a.x = ARENA_CENTER.x;
    a.y = ARENA_CENTER.y;
    b.x = a.x + 30;
    b.y = a.y;
    sim.step(1 / 60);
    const dist = Math.hypot(b.x - a.x, b.y - a.y);
    expect(dist).toBeGreaterThan(30);
  });
});

function openPair(): { sim: MatchSim; a: NonNullable<ReturnType<MatchSim["heroes"]["get"]>>; b: NonNullable<ReturnType<MatchSim["heroes"]["get"]>> } {
  const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
  sim.countdown = 0;
  const a = sim.heroes.get(0);
  const b = sim.heroes.get(1);
  if (!a || !b) {throw new Error("heroes");}
  a.x = ARENA_CENTER.x;
  a.y = ARENA_CENTER.y;
  a.facingX = 1;
  a.facingY = 0;
  a.aimX = a.x + 100;
  a.aimY = a.y;
  b.x = a.x + 140;
  b.y = a.y;
  return { sim, a, b };
}

function injectBullet(sim: MatchSim, over: Partial<SimBullet> & Pick<SimBullet, "x" | "y" | "owner">): SimBullet {
  const id = 9000 + sim.bullets.size;
  const b: SimBullet = {
    id, vx: 0, vy: 0, ttl: 1, kind: "bolt", damage: 10, radius: 40, splash: 0, pierce: 0,
    knockback: 8, source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [],
    homing: 0,
    ...over,
  };
  sim.bullets.set(id, b);
  return b;
}

describe("총알 정합 W9", () => {
  it("머즐 위치는 spawnShot 좌표를 유지하고 facing*28 로 덮지 않는다", () => {
    const { sim, a } = openPair();
    sim.pushInput(0, { fire: true, firePressed: true, aimX: a.x + 200, aimY: a.y, seq: 1 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
    const shot = [...sim.bullets.values()][0] as SimBullet;
    const dt = 1 / 60;
    const originX = shot.x - shot.vx * dt;
    const originY = shot.y - shot.vy * dt;
    const muzzle = muzzleWorldPos(a.x, a.y - hopLift(a), a.facingX, a.facingY, a.equipment.id);
    expect(originX).toBeCloseTo(muzzle.x, 5);
    expect(originY).toBeCloseTo(muzzle.y, 5);
    const naiveX = a.x + a.facingX * 28;
    const naiveY = a.y + a.facingY * 28;
    expect(Math.hypot(originX - naiveX, originY - naiveY)).toBeGreaterThan(8);
  });

  it("반경은 spawnShot 의 eq.radius * 3 을 유지한다", () => {
    const { sim, a } = openPair();
    sim.pushInput(0, { fire: true, firePressed: true, aimX: a.x + 200, aimY: a.y, seq: 1 });
    sim.step(1 / 60);
    const shot = [...sim.bullets.values()][0] as SimBullet;
    expect(shot.radius).toBe(a.equipment.radius * RADIUS_FIRE_MUL);
  });

  it("시간 스케일 데미지 1 + clamp((t-65)/35, 0, 1.25)", () => {
    expect(matchTimeDamageScale(0)).toBe(1);
    expect(matchTimeDamageScale(MATCH_DMG_TIME_START)).toBe(1);
    expect(matchTimeDamageScale(MATCH_DMG_TIME_START + MATCH_DMG_TIME_SPAN)).toBe(2);
    expect(matchTimeDamageScale(400)).toBe(1 + MATCH_DMG_TIME_CAP);
    const { sim, a, b } = openPair();
    sim.matchTime = 100;
    const hp = b.hp;
    injectBullet(sim, { x: b.x, y: b.y, owner: a.slot, damage: 10, radius: 80 });
    sim.step(1 / 60);
    expect(b.hp).toBeCloseTo(hp - 10 * matchTimeDamageScale(sim.matchTime), 5);
  });

  it("벽 스플래시는 splash>0 이면 반경 내 히어로에게 damage*0.55", () => {
    const { sim, a, b } = openPair();
    const cover = sim.covers[0];
    const cx = cover.x + cover.w / 2;
    const cy = cover.y + cover.h / 2;
    b.x = cx + 40;
    b.y = cy;
    const hp = b.hp;
    injectBullet(sim, {
      x: cx, y: cy, owner: a.slot, damage: 100, splash: 120, radius: 5, kind: "shell",
    });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(0);
    expect(b.hp).toBeCloseTo(hp - 100 * PROJECTILE_SPLASH_MUL, 5);
  });

  it("일반 총격은 knockback 셔브 clamp(5+|kb|*0.35, 5, 16) 후 아레나 클램프", () => {
    const { sim, a, b } = openPair();
    const x0 = b.x;
    injectBullet(sim, {
      x: b.x, y: b.y, owner: a.slot, damage: 1, radius: 80, knockback: 20,
    });
    sim.step(1 / 60);
    const shove = Math.min(SHOVE_MAX, Math.max(SHOVE_BASE, SHOVE_BASE + 20 * SHOVE_KB_MUL));
    expect(shove).toBe(12);
    expect(b.x).toBeCloseTo(x0 + shove, 4);
    expect(b.y).toBeCloseTo(a.y, 4);
  });

  it("히어로 스플래시·리치: 주변 0.55, leech 는 damage*0.13 회복", () => {
    const { sim, a, b } = openPair();
    const c = sim.heroes.get(1);
    expect(c).toBe(b);
    sim.heroes.set(2, { ...b, slot: 2, x: b.x + 30, y: b.y, hp: b.hp, comboHits: 0, comboTime: 0 });
    const near = sim.heroes.get(2);
    if (!near) {return;}
    a.hp = 40;
    const hpB = b.hp;
    const hpN = near.hp;
    injectBullet(sim, {
      x: b.x, y: b.y, owner: a.slot, damage: 20, radius: 80, splash: 80, leech: true,
    });
    sim.step(1 / 60);
    expect(b.hp).toBeCloseTo(hpB - 20, 5);
    expect(near.hp).toBeCloseTo(hpN - 20 * PROJECTILE_SPLASH_MUL, 5);
    expect(a.hp).toBeCloseTo(40 + 20 * PROJECTILE_LEECH_MUL, 5);
  });
});
