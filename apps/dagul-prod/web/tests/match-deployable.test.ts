import { describe, expect, it } from "vitest";
import {
  CORE_RADIUS,
  MINE_ARM_TIME,
  MINE_CC_TIME,
  MINE_CC_TIME_ULTIMATE,
  MINE_CLAMP_INSET,
  MINE_FIZZLE_RADIUS,
  MINE_FUSE_TIME,
  MINE_KNOCKBACK,
  MINE_KNOCKBACK_ULTIMATE,
  MINE_LIFETIME,
  MINE_MAX_PER_OWNER,
  MINE_TRIGGER_RADIUS_MAX,
  MINE_TRIGGER_RADIUS_RATIO,
  MINE_ZONE_DELAY,
  WALL_ARM_TIME,
  WALL_CLAMP_INSET,
  WALL_CORE_DAMAGE_RATIO,
  WALL_COVER_PADDING,
  WALL_HIT_CC_TIME,
  WALL_HIT_COOLDOWN,
  WALL_SLAM_ORIGIN_BACK,
  WALL_STOP_INSET,
  WALL_SWEEP_BACK_MARGIN,
  WALL_SWEEP_FRONT_MARGIN,
  applyBounceWall,
  applyMine,
  mineHasTarget,
  placeBounceWall,
  placeMine,
  seedDeployables,
  tickDeployables,
  updateDeployables,
} from "@/lib/hub/match-deployable";
import type { DeployableCore, DeployableHero, MineDeployable, WallDeployable } from "@/lib/hub/match-deployable";
import { ARENA_CENTER, ARENA_MARGIN, ARENA_SIZE, HERO_RADIUS } from "@/lib/hub/match-covers";

const DT = 1 / 60;
const COVERS: { x: number; y: number; w: number; h: number }[] = [];

function hero(slot: number, over: Partial<DeployableHero> = {}): DeployableHero {
  return { slot, x: ARENA_CENTER.x, y: ARENA_CENTER.y, alive: true, wallHitCd: 0, ...over };
}

function core(slot: number, over: Partial<DeployableCore> = {}): DeployableCore {
  return { slot, x: ARENA_CENTER.x + 400, y: ARENA_CENTER.y, alive: true, exposed: true, ...over };
}

describe("설치물 원본 상수 (deployable_system.gd)", () => {
  it("지뢰·벽 수치 원문", () => {
    expect(MINE_ARM_TIME).toBe(0.62);
    expect(MINE_LIFETIME).toBe(8.0);
    expect(MINE_FUSE_TIME).toBe(0.38);
    expect(MINE_TRIGGER_RADIUS_MAX).toBe(126);
    expect(MINE_TRIGGER_RADIUS_RATIO).toBe(0.72);
    expect(MINE_CC_TIME).toBe(0.40);
    expect(MINE_CC_TIME_ULTIMATE).toBe(0.55);
    expect(MINE_KNOCKBACK).toBe(140);
    expect(MINE_KNOCKBACK_ULTIMATE).toBe(175);
    expect(MINE_MAX_PER_OWNER).toBe(2);
    expect(MINE_CLAMP_INSET).toBe(18);
    expect(MINE_FIZZLE_RADIUS).toBe(42);
    expect(MINE_ZONE_DELAY).toBe(0.01);
    expect(WALL_CLAMP_INSET).toBe(26);
    expect(WALL_ARM_TIME).toBe(0.18);
    expect(WALL_STOP_INSET).toBe(24);
    expect(WALL_COVER_PADDING).toBe(34);
    expect(WALL_HIT_CC_TIME).toBe(0.32);
    expect(WALL_HIT_COOLDOWN).toBe(0.78);
    expect(WALL_CORE_DAMAGE_RATIO).toBe(0.62);
    expect(WALL_SLAM_ORIGIN_BACK).toBe(34);
    expect(WALL_SWEEP_BACK_MARGIN).toBe(10);
    expect(WALL_SWEEP_FRONT_MARGIN).toBe(14);
    expect(CORE_RADIUS).toBe(34);
  });
});

describe("place_mine", () => {
  it("trigger_radius = min(126, blast*0.72), 비궁극 cc 0.40 / knock 140", () => {
    const state = seedDeployables();
    const events = placeMine(state, hero(0), ARENA_CENTER.x, ARENA_CENTER.y, COVERS, {
      damage: 40, blastRadius: 200,
    });
    const mine = state.deployables[0] as MineDeployable;
    expect(mine.triggerRadius).toBe(Math.min(126, 200 * 0.72));
    expect(mine.triggerRadius).toBe(126);
    expect(mine.ccTime).toBe(0.40);
    expect(mine.knockback).toBe(140);
    expect(mine.armTime).toBe(0.62);
    expect(mine.lifetime).toBe(8);
    expect(events.some((e) => e.kind === "minePlaced")).toBe(true);
    expect(applyMine).toBe(placeMine);
  });

  it("궁극 지뢰는 cc 0.55 / knock 175, 상한 컷 없음", () => {
    const state = seedDeployables();
    const owner = hero(1);
    for (let i = 0; i < 3; i += 1) {
      placeMine(state, owner, ARENA_CENTER.x + i, ARENA_CENTER.y, COVERS, {
        damage: 50, blastRadius: 90, ultimate: true,
      });
    }
    expect(state.deployables).toHaveLength(3);
    expect((state.deployables[0] as MineDeployable).ccTime).toBe(0.55);
    expect((state.deployables[0] as MineDeployable).knockback).toBe(175);
  });

  it("비궁극 owner 당 2개 — 3번째 설치 시 가장 오래된 것 REPLACED", () => {
    const state = seedDeployables();
    const owner = hero(2);
    placeMine(state, owner, ARENA_CENTER.x, ARENA_CENTER.y, COVERS, { damage: 10, blastRadius: 80 });
    placeMine(state, owner, ARENA_CENTER.x + 10, ARENA_CENTER.y, COVERS, { damage: 10, blastRadius: 80 });
    const firstId = state.deployables[0].id;
    const events = placeMine(state, owner, ARENA_CENTER.x + 20, ARENA_CENTER.y, COVERS, {
      damage: 10, blastRadius: 80,
    });
    expect(state.deployables).toHaveLength(2);
    expect(state.deployables.some((d) => d.id === firstId)).toBe(false);
    expect(events[0]).toMatchObject({ kind: "fizzle", label: "REPLACED", radius: 42 });
  });

  it("마진+18 클램프", () => {
    const state = seedDeployables();
    placeMine(state, hero(0, { x: 0, y: 0 }), -100, -100, COVERS, { damage: 1, blastRadius: 50 });
    const lo = ARENA_MARGIN + MINE_CLAMP_INSET;
    expect(state.deployables[0].x).toBe(lo);
    expect(state.deployables[0].y).toBe(lo);
  });
});

describe("place_bounce_wall", () => {
  it("owner 당 1개, orthogonal=(ty,-tx), arm 0.18", () => {
    const state = seedDeployables();
    const owner = hero(0);
    placeBounceWall(state, owner, ARENA_CENTER.x, ARENA_CENTER.y, 1, 0, COVERS, {
      halfLength: 90, lifetime: 4, speed: 220, damage: 30, knockback: 80,
    });
    const wall = state.deployables[0] as WallDeployable;
    expect(wall.travelX).toBeCloseTo(1);
    expect(wall.travelY).toBeCloseTo(0);
    expect(wall.dirX).toBeCloseTo(0);
    expect(wall.dirY).toBeCloseTo(-1);
    expect(wall.armTime).toBe(0.18);
    const events = applyBounceWall(state, owner, ARENA_CENTER.x + 5, ARENA_CENTER.y, 0, 1, COVERS, {
      halfLength: 70, lifetime: 3, speed: 180, damage: 20, knockback: 60,
    });
    expect(state.deployables).toHaveLength(1);
    expect(events[0]).toMatchObject({ kind: "fizzle", label: "REPLACED", radius: 58 });
    expect(ARENA_SIZE.x).toBe(7840);
  });
});

describe("update_deployables 지뢰", () => {
  it("적 히어로가 트리거 반경 안이면 도화선 후 폭발", () => {
    const state = seedDeployables();
    placeMine(state, hero(0, { x: 2000, y: 2000 }), 2000, 2000, COVERS, {
      damage: 40, blastRadius: 100, armTime: 0, lifetime: 8, fuseTime: 0.38,
    });
    const mine = state.deployables[0] as MineDeployable;
    const enemy = hero(1, { x: mine.x + 10, y: mine.y });
    const heroes = new Map([[0, hero(0, { x: 2000, y: 2000 })], [1, enemy]]);
    expect(mineHasTarget(mine, heroes, new Map())).toBe(true);
    const armed = updateDeployables(state, heroes, new Map(), COVERS, DT);
    expect(armed.some((e) => e.kind === "mineTriggered")).toBe(true);
    expect((state.deployables[0] as MineDeployable).triggered).toBe(true);
    for (let i = 0; i < 30; i += 1) {tickDeployables(state, heroes, new Map(), COVERS, DT);}
    expect(state.deployables).toHaveLength(0);
  });

  it("수명 소진은 EXPIRED fizzle (폭발 없음)", () => {
    const state = seedDeployables();
    placeMine(state, hero(0), ARENA_CENTER.x, ARENA_CENTER.y, COVERS, {
      damage: 10, blastRadius: 50, lifetime: DT / 2,
    });
    const events = updateDeployables(state, new Map(), new Map(), COVERS, DT);
    expect(events).toEqual([
      expect.objectContaining({ kind: "fizzle", label: "EXPIRED", radius: 42 }),
    ]);
    expect(state.deployables).toHaveLength(0);
  });
});

describe("update_deployables 벽 스윕", () => {
  it("무장 해제 후 전방 스윕 — 히어로 1회, 코어는 damage*0.62", () => {
    const state = seedDeployables();
    placeBounceWall(state, hero(0, { x: 2000, y: 2000 }), 2000, 2000, 1, 0, COVERS, {
      halfLength: 80, lifetime: 4, speed: 600, damage: 50, knockback: 90,
    });
    const wall = state.deployables[0] as WallDeployable;
    wall.armTime = 0;
    const target = hero(1, { x: wall.x + 8, y: wall.y });
    const coreT = core(1, { x: wall.x + 8, y: wall.y, exposed: true });
    const heroes = new Map([[0, hero(0, { x: 2000, y: 2000 })], [1, target]]);
    const cores = new Map([[1, coreT]]);
    const events = updateDeployables(state, heroes, cores, COVERS, DT);
    const heroHit = events.find((e) => e.kind === "wallHitHero");
    const coreHit = events.find((e) => e.kind === "wallHitCore");
    expect(heroHit).toMatchObject({ kind: "wallHitHero", owner: 0, target: 1, damage: 50, ccTime: 0.32 });
    expect(coreHit).toMatchObject({ kind: "wallHitCore", damage: 50 * 0.62 });
    expect(target.wallHitCd).toBe(0.78);
    expect(HERO_RADIUS).toBe(20);
  });
});
