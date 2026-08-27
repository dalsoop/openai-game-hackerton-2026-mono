import { describe, expect, it } from "vitest";
import {
  DECOY_DAMAGE, DECOY_KNOCK, ITEM_POOL_MODE, NO_LOOT_MODES, POCKET_DURATION, PULL_DURATION,
  PULL_LAUNCH, PULL_PICKUP_SPEED, PULL_RADIUS, rollPickupKind, tryUseActiveItem,
  type ItemEvent,
} from "@/lib/hub/match-item";
import {
  handleUseInput, lootSeedFields, seedHealthPickups, updateHealthPickups,
} from "@/lib/hub/match-loot";
import type { LootHero } from "@/lib/hub/match-loot";
import { MatchRng } from "@/lib/hub/match-rng";
import { LAUNCH_SPEED_BASE, LAUNCH_SPEED_KB_MUL } from "@/lib/hub/match-launch";
import { MatchSim } from "@/lib/hub/match-sim";
import { packAuthoritySnap } from "@/lib/hub/match-authority";

const DT = 1 / 60;
const POOL = ["medkit", "spring", "slide", "pull", "pocket", "decoy"] as const;

function pickupFromRoll(rng: MatchRng): string {
  const p = {
    id: 0, x: 0, y: 0, homeX: 0, homeY: 0, magnetSlot: -1, active: true, respawn: 0,
    kind: "item" as const, itemKind: "", disguise: "", ephemeral: false, ignoreSlot: -1, ignoreTime: 0,
  };
  rollPickupKind(p, rng);
  return p.itemKind;
}

function itemHero(slot: number, over: Partial<LootHero> = {}): LootHero {
  return {
    slot, x: 2000, y: 2000, hp: 176, maxHp: 176, alive: true, eliminated: false,
    facingX: 1, facingY: 0, vx: 0, vy: 0, ...lootSeedFields(), ...over,
  };
}

describe("roll_pickup_kind 원본 확률", () => {
  it("같은 시드는 같은 종류 열을 낸다", () => {
    const a = new MatchRng(7);
    const b = new MatchRng(7);
    const left = Array.from({ length: 24 }, () => pickupFromRoll(a));
    const right = Array.from({ length: 24 }, () => pickupFromRoll(b));
    expect(left).toEqual(right);
    for (const kind of left) {expect(POOL).toContain(kind);}
  });

  it("임계값 0.30/0.48/0.66/0.80/0.90 이 종류를 가른다", () => {
    const table: Array<[number, string]> = [
      [0.00, "medkit"], [0.29, "medkit"],
      [0.30, "spring"], [0.47, "spring"],
      [0.48, "slide"], [0.65, "slide"],
      [0.66, "pull"], [0.79, "pull"],
      [0.80, "pocket"], [0.89, "pocket"],
      [0.90, "decoy"], [0.99, "decoy"],
    ];
    for (const [roll, kind] of table) {
      const rng = { rangef: (): number => roll, rangei: (): number => 0 } as unknown as MatchRng;
      expect(pickupFromRoll(rng)).toBe(kind);
    }
  });

  it("item 모드 스폰은 16칸을 풀에서 굴리고 classic 은 medkit 고정이다", () => {
    const item = seedHealthPickups("item", new MatchRng(11));
    expect(item).toHaveLength(16);
    expect(item.every((p) => p.active)).toBe(true);
    expect(item.every((p) => POOL.includes(p.itemKind as typeof POOL[number]))).toBe(true);
    expect(item.some((p) => p.itemKind !== "medkit")).toBe(true);
    const classic = seedHealthPickups("classic", new MatchRng(11));
    expect(classic.every((p) => p.itemKind === "medkit" && p.active)).toBe(true);
    const full = seedHealthPickups("full", new MatchRng(11));
    expect(full.every((p) => p.itemKind === "medkit" && p.active)).toBe(true);
  });
});

describe("NO_LOOT_MODES", () => {
  it("gun-semi·gun-auto 는 헬스 픽업을 끈다 — game_world.gd:246-248", () => {
    expect([...NO_LOOT_MODES]).toEqual(["gun-semi", "gun-auto"]);
    for (const mode of NO_LOOT_MODES) {
      const pickups = seedHealthPickups(mode, new MatchRng(3));
      expect(pickups.every((p) => !p.active && p.respawn === 99999)).toBe(true);
    }
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 3, "gun-semi");
    expect(sim.loot.every((p) => !p.active)).toBe(true);
  });
});

describe("heldItem 습득", () => {
  it("픽업 시 heldItem 을 넣고 item_collected 를 남긴다", () => {
    const pickups = seedHealthPickups("classic", new MatchRng(1));
    pickups[0].itemKind = "pull";
    pickups[0].disguise = "pull";
    const h = itemHero(0, { x: pickups[0].homeX, y: pickups[0].homeY });
    const events: ItemEvent[] = [];
    updateHealthPickups(pickups, new Map([[0, h]]), DT, ITEM_POOL_MODE, { tick: 4, events });
    expect(h.heldItem).toBe("pull");
    expect(pickups[0].active).toBe(false);
    expect(events.some((e) => e.type === "item_collected" && e.data.kind === "pull")).toBe(true);
  });

  it("이미 든 아이템은 뒤쪽으로 드랍한다", () => {
    const pickups = seedHealthPickups("classic", new MatchRng(1));
    pickups[0].itemKind = "spring";
    const h = itemHero(0, {
      x: pickups[0].homeX, y: pickups[0].homeY, heldItem: "slide", facingX: 1, facingY: 0,
    });
    updateHealthPickups(pickups, new Map([[0, h]]), DT, ITEM_POOL_MODE, { tick: 1, events: [] });
    expect(h.heldItem).toBe("spring");
    const dropped = pickups.find((p) => p.ephemeral && p.active && p.itemKind === "slide");
    expect(dropped).toBeDefined();
    expect(dropped?.ignoreSlot).toBe(0);
    expect(dropped?.ignoreTime).toBeCloseTo(0.45 - DT, 6);
  });

  it("decoy 픽업은 들고 있지 않고 18 피해·런치를 건다", () => {
    const pickups = seedHealthPickups("classic", new MatchRng(1));
    pickups[0].itemKind = "decoy";
    const h = itemHero(0, { x: pickups[0].homeX, y: pickups[0].homeY });
    const asSim = h as LootHero & { launchTime: number; launchVel: { x: number; y: number }; weight: number };
    asSim.launchTime = 0;
    asSim.launchVel = { x: 0, y: 0 };
    asSim.weight = 1;
    updateHealthPickups(pickups, new Map([[0, asSim]]), DT, ITEM_POOL_MODE, { tick: 1, events: [] });
    expect(asSim.heldItem).toBe("");
    expect(asSim.hp).toBeCloseTo(176 - DECOY_DAMAGE);
    expect(asSim.launchTime).toBe(0.28);
    const speed = (LAUNCH_SPEED_BASE + DECOY_KNOCK * LAUNCH_SPEED_KB_MUL) / 1;
    expect(Math.hypot(asSim.launchVel.x, asSim.launchVel.y)).toBeCloseTo(speed, 6);
  });
});

describe("pull/pocket 발동", () => {
  it("pull 은 0.55초·반경 300·런치 380 으로 당긴다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 5, ITEM_POOL_MODE);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    expect(a && b).toBeTruthy();
    if (!a || !b) {return;}
    a.x = 2000;
    a.y = 2000;
    b.x = 2000 + 120;
    b.y = 2000;
    a.heldItem = "pull";
    const used = tryUseActiveItem(a, {
      mode: ITEM_POOL_MODE, tick: sim.tick, dt: DT, heroes: sim.heroes, pickups: sim.loot,
      events: sim.ultWorld.events,
    });
    expect(used).toBe(true);
    expect(a.heldItem).toBe("");
    expect(a.pullTime).toBe(PULL_DURATION);
    expect(b.launchTime).toBeGreaterThanOrEqual(0.20);
    expect(b.launchVel.x).toBeCloseTo(-PULL_LAUNCH, 6);
    expect(b.launchVel.y).toBe(0);
    expect(sim.ultWorld.events.some((e) => e.type === "item_used" && e.data.kind === "pull")).toBe(true);
    expect(PULL_RADIUS).toBe(300);
  });

  it("pull 펄스는 픽업을 520px/s 로 끌어온다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 5, ITEM_POOL_MODE);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    if (!a) {return;}
    a.x = 2000;
    a.y = 2000;
    a.heldItem = "pull";
    const p = sim.loot.find((row) => row.active);
    expect(p).toBeDefined();
    if (!p) {return;}
    p.x = 2000 + 80;
    p.y = 2000;
    tryUseActiveItem(a, {
      mode: ITEM_POOL_MODE, tick: 0, dt: DT, heroes: sim.heroes, pickups: sim.loot,
    });
    expect(p.x).toBeCloseTo(2000 + 80 - PULL_PICKUP_SPEED * DT, 5);
  });

  it("pocket 은 5초 무적 버블을 켠다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 5, ITEM_POOL_MODE);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    if (!a) {return;}
    a.heldItem = "pocket";
    a.hp = 50;
    handleUseInput(a, true, {
      mode: ITEM_POOL_MODE, tick: 1, dt: DT, heroes: sim.heroes, pickups: sim.loot,
      events: sim.ultWorld.events,
    });
    expect(a.pocketTime).toBe(POCKET_DURATION);
    expect(a.heldItem).toBe("");
    const hp0 = a.hp;
    sim.zone.radius = 1;
    sim.step(DT);
    expect(a.hp).toBe(hp0);
    expect(a.pocketTime).toBeCloseTo(POCKET_DURATION - DT, 6);
  });

  it("packPlayerV2 는 pullTime·pocketTime 를 omit-default 로 싣는다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 5, ITEM_POOL_MODE);
    const h = sim.heroes.get(0);
    if (!h) {return;}
    const empty = packAuthoritySnap(sim, new Map(), ITEM_POOL_MODE);
    const row0 = (empty.players as Array<Record<string, unknown>>)[0];
    expect(row0.pullTime).toBeUndefined();
    expect(row0.pocketTime).toBeUndefined();
    h.pullTime = 0.55;
    h.pocketTime = 5;
    const packed = packAuthoritySnap(sim, new Map(), ITEM_POOL_MODE);
    const row = (packed.players as Array<Record<string, unknown>>)[0];
    expect(row.pullTime).toBeCloseTo(0.55);
    expect(row.pocketTime).toBeCloseTo(5);
  });
});
