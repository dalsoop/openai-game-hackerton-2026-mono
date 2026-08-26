import { describe, expect, it } from "vitest";
import {
  ARENA_CENTER,
  HERO_RADIUS,
  KNOCKOUT_TIME,
  buildTiledCovers,
  pointInCover,
  resolveCoverMotion,
} from "@/lib/hub/match-covers";
import { MatchSim } from "@/lib/hub/match-sim";
import { packAuthoritySnap } from "@/lib/hub/match-authority";

// 타일 (0,0) 의 첫 커버: (1330,590,140,520) * 1.4 — 중심 (1960,1190), 원 반지름 98.
const C0 = { x: 1330 * 1.4, y: 590 * 1.4, w: 140 * 1.4, h: 520 * 1.4 };
const C0_CENTER = { x: C0.x + C0.w / 2, y: C0.y + C0.h / 2 };

describe("match-covers", () => {
  it("타일 커버는 44개이고 1.4 스케일 결정론이다", () => {
    const covers = buildTiledCovers();
    expect(covers).toHaveLength(44);
    expect(covers[0].x).toBeCloseTo(C0.x, 6);
    expect(covers[0].y).toBeCloseTo(C0.y, 6);
    expect(covers[0].w).toBeCloseTo(C0.w, 6);
    expect(covers[0].h).toBeCloseTo(C0.h, 6);
    // 두 번째 타일 원점 (0, 2380) 오프셋
    expect(covers[11].x).toBeCloseTo(C0.x, 6);
    expect(covers[11].y).toBeCloseTo(C0.y + 1700 * 1.4, 6);
    expect(buildTiledCovers()).toEqual(covers);
  });

  it("점-커버 충돌은 중심·짧은변 반지름 원형이다", () => {
    const covers = buildTiledCovers();
    expect(pointInCover(C0_CENTER.x, C0_CENTER.y, covers)).toBe(true);
    expect(pointInCover(C0_CENTER.x, C0_CENTER.y + 100, covers)).toBe(false);
    expect(pointInCover(C0_CENTER.x, C0_CENTER.y + 100, covers, HERO_RADIUS)).toBe(true);
  });

  it("커버로의 이동은 막히고 축 슬라이딩된다", () => {
    const covers = buildTiledCovers();
    const blocked = resolveCoverMotion(C0_CENTER.x - 130, C0_CENTER.y, 20, 0, covers);
    expect(blocked.x).toBe(C0_CENTER.x - 130);
    const slid = resolveCoverMotion(C0_CENTER.x - 130, C0_CENTER.y, 20, 30, covers);
    expect(slid.x).toBe(C0_CENTER.x - 130);
    expect(slid.y).toBe(C0_CENTER.y + 30);
    const free = resolveCoverMotion(600, 600, 20, 30, covers);
    expect(free).toEqual({ x: 620, y: 630 });
  });

  it("히어로 이동은 커버를 관통하지 못한다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const hero = sim.heroes.get(0);
    const other = sim.heroes.get(1);
    expect(hero && other).toBeTruthy();
    if (!hero || !other) {return;}
    hero.x = C0_CENTER.x - 210;
    hero.y = C0_CENTER.y;
    other.x = ARENA_CENTER.x;
    other.y = ARENA_CENTER.y;
    for (let i = 0; i < 120; i++) {
      sim.pushInput(0, { mx: 1, my: 0, seq: i + 1 });
      sim.step(1 / 60);
    }
    const dist = Math.hypot(hero.x - C0_CENTER.x, hero.y - C0_CENTER.y);
    expect(dist).toBeGreaterThan(Math.min(C0.w, C0.h) / 2 + HERO_RADIUS);
    expect(hero.x).toBeGreaterThan(C0_CENTER.x - 210);
    expect(pointInCover(hero.x, hero.y, sim.covers, HERO_RADIUS)).toBe(false);
  });

  it("탄은 커버에 맞으면 소멸하고 뒤의 히어로를 지나치지 못한다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const shooter = sim.heroes.get(0);
    const victim = sim.heroes.get(1);
    expect(shooter && victim).toBeTruthy();
    if (!shooter || !victim) {return;}
    shooter.x = C0_CENTER.x;
    shooter.y = C0_CENTER.y - 300;
    victim.x = C0_CENTER.x;
    victim.y = C0_CENTER.y + 140;
    sim.pushInput(0, { fire: true, aimX: victim.x, aimY: victim.y, seq: 1 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
    sim.pushInput(0, { seq: 2 });
    for (let i = 0; i < 30; i++) {sim.step(1 / 60);}
    expect(sim.bullets.size).toBe(0);
    expect(victim.hp).toBe(victim.maxHp);
    expect(victim.alive).toBe(true);
  });

  it("다운 전이 시 knockout 이 생기고 시간이 다 되면 사라진다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const shooter = sim.heroes.get(0);
    const victim = sim.heroes.get(1);
    expect(shooter && victim).toBeTruthy();
    if (!shooter || !victim) {return;}
    shooter.x = 600;
    shooter.y = 600;
    victim.x = 660;
    victim.y = 600;
    victim.hp = 10;
    const animal = victim.animal;
    sim.pushInput(0, { fire: true, aimX: victim.x, aimY: victim.y, seq: 1 });
    sim.step(1 / 60);
    // HP 0 은 즉사가 아니라 다운 — knockout 연출은 다운 전이 시점에 유지된다.
    expect(victim.downed).toBe(true);
    expect(victim.alive).toBe(true);
    expect(sim.knockouts).toHaveLength(1);
    const ko = sim.knockouts[0];
    expect(ko.slot).toBe(1);
    expect(ko.animal).toBe(animal);
    expect(ko.x).toBeCloseTo(660, 5);
    expect(ko.y).toBeCloseTo(600, 5);
    expect(ko.time).toBeCloseTo(KNOCKOUT_TIME, 5);
    expect(ko.maxTime).toBeCloseTo(KNOCKOUT_TIME, 5);
    sim.pushInput(0, { seq: 2 });
    sim.step(1 / 60);
    expect(ko.time).toBeLessThan(KNOCKOUT_TIME);
    for (let i = 0; i < Math.ceil(KNOCKOUT_TIME * 60) + 2; i++) {sim.step(1 / 60);}
    expect(sim.knockouts).toHaveLength(0);
  });

  it("스냅에 covers 가 Godot parse_covers 필드명으로 실린다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const snap = packAuthoritySnap(sim, new Map(), "versus");
    const covers = snap.covers as Array<{ x: number; y: number; w: number; h: number }>;
    expect(covers).toHaveLength(44);
    expect(covers[0].x).toBeCloseTo(C0.x, 6);
    expect(covers[0].y).toBeCloseTo(C0.y, 6);
    expect(covers[0].w).toBeCloseTo(C0.w, 6);
    expect(covers[0].h).toBeCloseTo(C0.h, 6);
  });

  it("스냅에 knockouts 가 Godot parse_knockouts 필드명으로 실린다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const victim = sim.heroes.get(1);
    expect(victim).toBeDefined();
    if (!victim) {return;}
    sim.knockouts.push({ slot: 1, animal: victim.animal, x: 700, y: 800, time: 1.2, maxTime: KNOCKOUT_TIME });
    const snap = packAuthoritySnap(sim, new Map(), "versus");
    const knockouts = snap.knockouts as Array<Record<string, number>>;
    expect(knockouts).toHaveLength(1);
    expect(knockouts[0]).toEqual({ slot: 1, animal: victim.animal, x: 700, y: 800, time: 1.2, max_time: KNOCKOUT_TIME });
  });
});
