import { describe, expect, it } from "vitest";
import {
  placeBounceWall,
  seedDeployables,
} from "@/lib/hub/match-deployable";
import type { DeployableHero } from "@/lib/hub/match-deployable";
import {
  WALL_BOUNCE_ORIGIN_BACK,
  WALL_TOUCH_MARGIN,
  applyWallContact,
  deployableWallHit,
  markWallHit,
  packDeployables,
  snapDeployables,
  tickWallHitCd,
  wallBounceOrigin,
} from "@/lib/hub/match-deployable-hit";
import { ARENA_CENTER, HERO_RADIUS } from "@/lib/hub/match-covers";

const COVERS: { x: number; y: number; w: number; h: number }[] = [];

function hero(slot: number, over: Partial<DeployableHero> = {}): DeployableHero {
  return { slot, x: ARENA_CENTER.x, y: ARENA_CENTER.y, alive: true, wallHitCd: 0, ...over };
}

describe("deployable_wall_hit", () => {
  it("세그먼트 교차 시 접촉 — normal=travel, origin back 32", () => {
    const state = seedDeployables();
    placeBounceWall(state, hero(0, { x: 2000, y: 2000 }), 2000, 2000, 0, -1, COVERS, {
      halfLength: 120, lifetime: 4, speed: 200, damage: 33, knockback: 70,
    });
    const wall = state.deployables[0];
    wall.armTime = 0;
    const contact = deployableWallHit(state, 1, 0, 2000, 2200, 2000, 1800);
    expect(contact).not.toBeNull();
    expect(contact?.owner).toBe(0);
    expect(contact?.damage).toBe(33);
    expect(contact?.knockback).toBe(70);
    expect(contact?.normalX).toBeCloseTo(0, 6);
    expect(contact?.normalY).toBeCloseTo(-1, 6);
    if (!contact) {throw new Error("expected wall contact");}
    const origin = wallBounceOrigin(2000, 2200, contact.normalX, contact.normalY);
    expect(origin.y).toBeCloseTo(2200 - (-1) * WALL_BOUNCE_ORIGIN_BACK);
    expect(WALL_BOUNCE_ORIGIN_BACK).toBe(32);
    expect(WALL_TOUCH_MARGIN).toBe(9);
    expect(HERO_RADIUS).toBe(20);
  });

  it("wallHitCd>0 이거나 자기 벽이면 null", () => {
    const state = seedDeployables();
    placeBounceWall(state, hero(1, { x: 2000, y: 2000 }), 2000, 2000, 1, 0, COVERS, {
      halfLength: 80, lifetime: 4, speed: 100, damage: 10, knockback: 10,
    });
    state.deployables[0].armTime = 0;
    expect(deployableWallHit(state, 1, 0, 1900, 2000, 2100, 2000)).toBeNull();
    expect(applyWallContact(state, 2, 0.5, 1900, 2000, 2100, 2000)).toBeNull();
  });

  it("mark_wall_hit 중복 없음, cd 틱 감소", () => {
    const state = seedDeployables();
    placeBounceWall(state, hero(0), ARENA_CENTER.x, ARENA_CENTER.y, 1, 0, COVERS, {
      halfLength: 40, lifetime: 2, speed: 100, damage: 1, knockback: 1,
    });
    const id = state.deployables[0].id;
    markWallHit(state, id, 3);
    markWallHit(state, id, 3);
    expect(state.deployables[0].type === "wall" && state.deployables[0].hitSlots).toEqual([3]);
    const h = { wallHitCd: 0.78 };
    tickWallHitCd([h], 0.18);
    expect(h.wallHitCd).toBeCloseTo(0.60, 9);
  });
});

describe("snap_deployables", () => {
  it("Godot parse_deployables 필드 — 지뢰 방향 기본 RIGHT, half_length 0", () => {
    const state = seedDeployables();
    placeBounceWall(state, hero(0), ARENA_CENTER.x, ARENA_CENTER.y, 1, 0, COVERS, {
      halfLength: 90, lifetime: 4, speed: 200, damage: 10, knockback: 10,
    });
    const snap = packDeployables(state.deployables);
    expect(snap[0]).toMatchObject({
      type: "wall", owner: 0, half_length: 90, triggered: false, trigger_radius: 0,
    });
    expect(snapDeployables(state.deployables)[0].tdx).toBeCloseTo(1);
  });
});
