import { describe, expect, it } from "vitest";
import {
  EFFECTS_SNAP_CAP,
  MOBILITY_DURATION_SCALE,
  addChargeBreakEffect,
  addControlEffect,
  addEffect,
  addEvadeEffect,
  addHeroHitEffect,
  addMobilityDashEffects,
  addMobilityEffect,
  createEffectStore,
  decayEffects,
  packEffects,
} from "@/lib/hub/match-effects";
import { applyControl, ccSeedFields } from "@/lib/hub/match-cc";
import { applyLaunchKnockout } from "@/lib/hub/match-launch-knockout";
import { packAuthoritySnap } from "@/lib/hub/match-authority-snap";
import { MatchSim } from "@/lib/hub/match-sim";
import { placeMine, seedDeployables } from "@/lib/hub/match-deployable";
import { hurtTower, resetMidTower, updateMidTower } from "@/lib/hub/match-tower";
import {
  beginDragonSmoke, beginSnakeShed, explodeRoosterEgg, popUltClone, popWoolShield,
  seedUltWorld, spawnMirageClones, ultHeroSeedFields,
  type UltHero,
} from "@/lib/hub/match-ultimate";
import { ARENA_CENTER } from "@/lib/hub/match-covers";
import type { EffectStore } from "@/lib/hub/match-effects";
import type { TowerHooks } from "@/lib/hub/match-tower";

const DT = 1 / 60;

function first(store: EffectStore): Record<string, unknown> {
  const packed = packEffects(store);
  expect(packed.length).toBeGreaterThan(0);
  return packed[0];
}

describe("이펙트 스토어 add/decay/cap", () => {
  it("add_effect 는 time=maxTime=duration, 기본 dx=1 follow=-1", () => {
    const store = createEffectStore();
    addEffect(store, {
      kind: "hit_spark", x: 10, y: 20, radius: 36, duration: 0.18, color: "#ff4f68",
    });
    expect(store.items[0]).toMatchObject({
      kind: "hit_spark", x: 10, y: 20, radius: 36, time: 0.18, maxTime: 0.18,
      color: "#ff4f68", label: "", dx: 1, dy: 0, follow: -1,
      startX: 10, startY: 20, drawDeparture: true,
    });
  });

  it("add_mobility_effect 는 duration*0.80 과 follow=slot, start=from", () => {
    const store = createEffectStore();
    addMobilityEffect(
      store, 3, "speed_streak", { x: 8, y: 9 }, { x: 40, y: 0 },
      40, 0.30, "#ffb45c", "SKIRMISH HOP", { x: -1, y: 0 },
    );
    expect(store.items[0].time).toBeCloseTo(0.30 * MOBILITY_DURATION_SCALE, 10);
    expect(store.items[0].follow).toBe(3);
    expect(store.items[0].x).toBe(40);
    expect(store.items[0].startX).toBe(8);
    expect(store.items[0].startY).toBe(9);
    expect(store.items[0].drawDeparture).toBe(true);
  });

  it("decay 는 time-=dt, 0 이하면 제거", () => {
    const store = createEffectStore();
    addEffect(store, { kind: "a", x: 0, y: 0, radius: 1, duration: DT * 1.5, color: "#fff" });
    decayEffects(store, DT);
    expect(store.items).toHaveLength(1);
    decayEffects(store, DT);
    expect(store.items).toHaveLength(0);
  });

  it("cap 48 — 49번째 add 는 가장 오래된 항목을 밀어낸다", () => {
    const store = createEffectStore();
    for (let i = 0; i < EFFECTS_SNAP_CAP + 1; i += 1) {
      addEffect(store, { kind: `k${i}`, x: i, y: 0, radius: 1, duration: 1, color: "#fff" });
    }
    expect(store.items).toHaveLength(EFFECTS_SNAP_CAP);
    expect(store.items[0].kind).toBe("k1");
    expect(store.items[47].kind).toBe("k48");
  });
});

describe("스냅 패킹 omit-empty", () => {
  it("pack 키는 k,x,y,r,t,maxT,color,label,dx,dy,follow,sx,sy,dep", () => {
    const store = createEffectStore();
    addEvadeEffect(store, 100, 200);
    expect(first(store)).toEqual({
      k: "afterimage", x: 100, y: 200, r: 105, t: 0.38, maxT: 0.38,
      color: "#b9f3ff", label: "EVADE", dx: 1, dy: 0, follow: -1,
      sx: 100, sy: 200, dep: true,
    });
  });

  it("W15 — 빈 스토어도 packAuthoritySnap 이 effects=[] 를 항상 싣는다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    const snap = packAuthoritySnap(sim, new Map(), "full") as { effects: unknown[] };
    expect(snap.effects).toEqual([]);
  });

  it("스토어가 있으면 effects 배열을 싣고 비어도 키는 남긴다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    const store = createEffectStore();
    (sim as MatchSim & { effects: EffectStore }).effects = store;
    addChargeBreakEffect(store, 1, 2);
    const snap = packAuthoritySnap(sim, new Map(), "full") as { effects: Array<{ k: string; sx: number; sy: number; dep: boolean }> };
    expect(snap.effects).toHaveLength(1);
    expect(snap.effects[0].k).toBe("charge_break");
    expect(snap.effects[0].sx).toBe(1);
    expect(snap.effects[0].sy).toBe(2);
    expect(snap.effects[0].dep).toBe(true);
    decayEffects(store, 1);
    const empty = packAuthoritySnap(sim, new Map(), "full") as { effects: unknown[] };
    expect(empty.effects).toEqual([]);
  });
});

describe("원본 수치 — CC·대시·히트", () => {
  it("root/stun 이펙트 반경·지속·색", () => {
    const store = createEffectStore();
    addControlEffect(store, "root", 8, 9, 1.2);
    addControlEffect(store, "stun", 8, 9, 0.2);
    expect(store.items[0]).toMatchObject({
      kind: "chain_bind", radius: 48, time: 0.48, color: "#b78cff", label: "ROOTED",
    });
    expect(store.items[1]).toMatchObject({
      kind: "stun_burst", radius: 58, time: 0.2, color: "#ffe27a", label: "STUNNED",
    });
  });

  it("applyControl 이 fx 스토어에 chain_bind 를 남긴다", () => {
    const store = createEffectStore();
    const h = ccSeedFields();
    applyControl(h, 0.4, "root", { store, x: 11, y: 12 });
    expect(store.items[0].kind).toBe("chain_bind");
    expect(store.items[0].x).toBe(11);
  });

  it("addChargeBreakEffect 는 charge_break 54/0.22 를 남긴다", () => {
    const store = createEffectStore();
    addChargeBreakEffect(store, 3, 4);
    expect(store.items[0]).toMatchObject({
      kind: "charge_break", x: 3, y: 4, radius: 54, time: 0.22, color: "#8ca0b8",
      startX: 3, startY: 4, drawDeparture: true,
    });
  });

  it("히트 임팩트 반경 clamp 32~125, normal 0.22 / 그 외 0.42", () => {
    const store = createEffectStore();
    addHeroHitEffect(store, {
      x: 0, y: 0, amount: 1, knockback: 0, source: "normal",
      kind: "hit_spark", label: "", launchX: 0, launchY: 0, fromX: -10, fromY: 0,
    });
    expect(store.items[0].radius).toBe(32);
    expect(store.items[0].time).toBe(0.22);
    addHeroHitEffect(store, {
      x: 0, y: 0, amount: 200, knockback: 400, source: "equipment",
      kind: "explosion", label: "SPLASH", launchX: 1, launchY: 0, fromX: 0, fromY: 0,
    });
    expect(store.items[1].radius).toBe(125);
    expect(store.items[1].time).toBe(0.42);
  });

  it("대시 12종 kind·색 — scatter/rail/mortar/leech/breaker/burst/blade/brawler/bomb/spear/chain/default", () => {
    const cases: Array<[string, string, string]> = [
      ["scatter", "speed_streak", "#ffb45c"],
      ["rail", "beam_step", "#71e7ff"],
      ["leech", "drain", "#d45cff"],
      ["breaker", "guard", "#ffe066"],
      ["burst", "speed_streak", "#ff5ca8"],
      ["blade", "slash_dash", "#b9f3ff"],
      ["brawler", "speed_streak", "#ff9466"],
      ["bomb", "fuse", "#ff5d4f"],
      ["spear", "spear_line", "#ffe27a"],
      ["chain", "chain_arc", "#b78cff"],
      ["shield", "guard", "#8de1ff"],
    ];
    for (const [id, kind, color] of cases) {
      const store = createEffectStore();
      addMobilityDashEffects(store, {
        equipmentId: id, slot: 0, oldX: 0, oldY: 0, x: 50, y: 0, dirX: 1, dirY: 0,
        comboKind: "none",
      });
      expect(store.items.some((e) => e.kind === kind && e.color === color), id).toBe(true);
    }
    const mortar = createEffectStore();
    addMobilityDashEffects(mortar, {
      equipmentId: "mortar", slot: 1, oldX: 0, oldY: 0, x: 40, y: 0, dirX: 1, dirY: 0,
      comboKind: "combo_break",
    });
    expect(mortar.items.map((e) => e.kind)).toEqual(["combo_break", "explosion", "blast_hop"]);
    expect(mortar.items[0].label).toBe("COMBO BREAK");
    expect(mortar.items[2].follow).toBe(1);
    expect(mortar.items[2].time).toBeCloseTo(0.32 * MOBILITY_DURATION_SCALE, 10);
    expect(mortar.items[2].startX).toBe(0);
    expect(mortar.items[2].startY).toBe(0);
    expect(mortar.items[2].drawDeparture).toBe(false);
    expect(packEffects(mortar)[2]).toMatchObject({ sx: 0, sy: 0, dep: false, follow: 1 });
  });
});

describe("발생점 — deployable·tower·ultimate·knockout", () => {
  it("placeMine 은 mine_place 48/0.28/#ff765f", () => {
    const store = createEffectStore();
    const state = seedDeployables();
    placeMine(
      state, { slot: 0, x: ARENA_CENTER.x, y: ARENA_CENTER.y },
      ARENA_CENTER.x + 40, ARENA_CENTER.y, [], { damage: 20, blastRadius: 80 }, store,
    );
    expect(store.items[0]).toMatchObject({
      kind: "mine_place", radius: 48, time: 0.28, color: "#ff765f", label: "MINE",
    });
  });

  it("타워 스폰 TOWER 90/0.45, 파괴 BOUNTY 110/0.55", () => {
    const store = createEffectStore();
    const t = resetMidTower();
    const hooks: TowerHooks = {
      damageHeroEnvironment: () => undefined,
      pushHero: () => undefined,
      spawnShell: () => undefined,
      spawnZone: () => undefined,
    };
    const heroes = new Map([[0, { slot: 0, x: ARENA_CENTER.x + 400, y: ARENA_CENTER.y, alive: true, eliminated: false }]]);
    updateMidTower(t, heroes, true, 75, hooks, DT, store);
    expect(store.items[0]).toMatchObject({
      kind: "explosion", radius: 90, time: 0.45, color: "#ffb347", label: "TOWER",
    });
    t.hp = 1;
    hurtTower(t, 0, 10, 1, heroes, store);
    expect(store.items[1]).toMatchObject({
      kind: "explosion", radius: 110, time: 0.55, color: "#ff5a4a", label: "BOUNTY",
    });
  });

  it("궁극 이펙트: SMOKE·SHED·sheep_pop·monkey_pop·EGG", () => {
    const store = createEffectStore();
    const w = seedUltWorld();
    w.effects = store;
    const h: UltHero = {
      ...ultHeroSeedFields(0, 4),
      slot: 0, x: 100, y: 200, hp: 100, maxHp: 100, alive: true,
    };
    const heroes = new Map([[0, h]]);
    beginDragonSmoke(w, heroes, 0);
    expect(store.items.some((e) => e.kind === "afterimage" && e.label === "SMOKE")).toBe(true);
    h.animal = 5;
    beginSnakeShed(w, heroes, 0);
    expect(store.items.some((e) => e.label === "SHED" && e.kind === "afterimage")).toBe(true);
    popWoolShield(w, heroes, 0);
    expect(store.items.some((e) => e.kind === "sheep_pop" && e.radius === 150)).toBe(true);
    spawnMirageClones(w, h, 0);
    popUltClone(w, heroes, 0, 0);
    expect(store.items.some((e) => e.kind === "monkey_pop" && e.radius === 54)).toBe(true);
    explodeRoosterEgg(w, heroes, { owner: 0, pos: { x: 1, y: 2 }, ttl: 0, arm: 0, trigger: 150, alive: true });
    expect(store.items.some((e) => e.kind === "rooster_burst" && e.label === "EGG")).toBe(true);
  });

  it("applyLaunchKnockout 는 death_burst 260/0.80/#ff3349", () => {
    const store = createEffectStore();
    applyLaunchKnockout(0, { x: 5, y: 6 }, { x: 0, y: 0 }, { x: 1, y: 0 }, store);
    expect(store.items[0]).toMatchObject({
      kind: "death_burst", x: 5, y: 6, radius: 260, time: 0.80, color: "#ff3349", dx: 1, dy: 0,
    });
  });
});
