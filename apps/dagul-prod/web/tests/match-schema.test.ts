import { describe, expect, it } from "vitest";
import { LobbyState } from "@/lib/hub/lobby-state";
import {
  packAuthoritySnap, SNAP_DT, seed as seedAuthority, tick as tickAuthority,
} from "@/lib/hub/match-authority";
import { MatchStateSchema } from "@/lib/hub/match-schema";
import { EVENT_RING, writeMatchState } from "@/lib/hub/match-schema-write";
import { FIXED_DT, MatchSim } from "@/lib/hub/match-sim";
import type { SnapEvent } from "@/lib/hub/match-authority-snap";

type Snap = {
  tick: number;
  zoneR: number;
  players: Array<{ slot: number; x: number; y: number; hp: number }>;
  bullets: Array<{ id: number; x: number; y: number }>;
};

function paintV2Hero(sim: MatchSim): void {
  const hero = sim.heroes.get(0);
  if (!hero) {throw new Error("hero 0");}
  hero.stunTime = 0.4;
  hero.action = "STUNNED";
  hero.heldItem = "spring";
  hero.springTime = 0.45;
  hero.slideTime = 0.2;
  hero.rouletteSpinId = "tiger";
  hero.woolHp = 8;
  sim.streakState.streakCallout = "TRIPLE";
  sim.streakState.streakSubtitle = "3";
  sim.streakState.streakCalloutTicks = 12;
  sim.streakState.streakCalloutShutdown = true;
}

function assertV2SchemaRow(match: MatchStateSchema, weaponId: string): void {
  const row = match.heroes.get("0");
  expect(row?.emote).toBe(-1);
  expect(row?.weaponId).toBe(weaponId);
  expect(row?.stunT).toBeCloseTo(0.4);
  expect(row?.action).toBe("STUNNED");
  expect(row?.heldItem).toBe("spring");
  expect(row?.springT).toBeCloseTo(0.45);
  expect(row?.slideT).toBeCloseTo(0.2);
  expect(row?.rouSpin).toBe("tiger");
  expect(JSON.parse(row?.rlTimed ?? "[]")).toEqual([]);
  expect(JSON.parse(row?.ultClones ?? "[]")).toEqual([]);
}

function assertV2SnapPlayer(
  snap: { players: Array<Record<string, unknown>> },
  weaponId: string,
): void {
  const packed = snap.players.find((p) => p.slot === 0);
  expect(packed?.weaponId).toBe(weaponId);
  expect(packed?.heldItem).toBe("spring");
  expect(packed?.springT).toBeCloseTo(0.45);
  expect(packed?.rouSpin).toBe("tiger");
  expect(typeof packed?.rouSpin).toBe("string");
}

describe("writeMatchState", () => {
  it("스키마 값이 packAuthoritySnap 의 대표 필드와 같다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    sim.countdown = 0;
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const hero0 = sim.heroes.get(0);
    const aimX = (hero0?.x ?? 0) + 80;
    sim.pushInput(0, {
      mx: 1, my: 0, fire: true, firePressed: true, seq: 1, aimX, aimY: 2380,
    });
    for (let i = 0; i < 12; i += 1) {sim.step(FIXED_DT);}
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    const snap = packAuthoritySnap(sim, names, "full") as Snap;
    expect(match.tick).toBe(snap.tick);
    expect(match.zoneR).toBe(snap.zoneR);
    const p0 = snap.players.find((p) => p.slot === 0);
    const row = match.heroes.get("0");
    expect(row?.x).toBe(p0?.x);
    expect(row?.y).toBe(p0?.y);
    expect(row?.hp).toBe(p0?.hp);
    expect(snap.bullets.length).toBeGreaterThan(0);
    expect(match.bullets.size).toBe(snap.bullets.length);
    const b = snap.bullets[0];
    const bullet = match.bullets.get(String(b.id));
    expect(bullet?.x).toBe(b.x);
    expect(bullet?.y).toBe(b.y);
  });

  it("스키마 events 가 JSON 스냅 events 와 같다", () => {
    const auth = seedAuthority(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      "full",
    );
    auth.sim.countdown = 0;
    const hero0 = auth.sim.heroes.get(0);
    const aimX = (hero0?.x ?? 0) + 80;
    auth.pushInput(0, {
      mx: 1, my: 0, fire: true, firePressed: true, seq: 1, aimX, aimY: 2380,
    });
    const state = new LobbyState();
    const packed: SnapEvent[] = [];
    for (let i = 0; i < 12; i += 1) {
      const out = tickAuthority(auth, SNAP_DT, state);
      if (!out.snap) {continue;}
      expect(out.snap.events).toEqual(out.events);
      packed.push(...out.events);
      writeMatchState(state.match, auth.sim, auth.names, "full", out.events);
    }
    const fire = packed.find((ev) => ev.k === "gun_fire");
    expect(fire).toBeDefined();
    const row = [...state.match.events].find((ev) => ev.k === "gun_fire");
    expect(row).toBeDefined();
    expect(row?.t).toBe(fire?.t);
    expect(row?.a).toBe(fire?.a);
    expect(row?.b).toBe(fire?.b);
    expect(JSON.parse(row?.d ?? "{}")).toEqual(fire?.d);
  });

  it("events 링버퍼는 상한을 넘기면 앞에서 제거한다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const match = new MatchStateSchema();
    const batch: SnapEvent[] = [];
    for (let i = 0; i < EVENT_RING + 8; i += 1) {
      batch.push({ t: i, k: "gun_fire", a: 0, b: -1, d: { i } });
    }
    writeMatchState(match, sim, names, "full", batch);
    expect(match.events.length).toBe(EVENT_RING);
    expect(match.eventSeq).toBe(EVENT_RING + 8);
    expect(match.events[0].seq).toBe(9);
    expect(JSON.parse(match.events[0].d)).toEqual({ i: 8 });
    expect(match.events[EVENT_RING - 1].seq).toBe(EVENT_RING + 8);
  });

  it("v2 연출·weaponId·스트릭이 JSON 스냅과 같다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    paintV2Hero(sim);
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    const snap = packAuthoritySnap(sim, names, "full") as {
      players: Array<Record<string, unknown>>;
      effects: unknown[];
      streakCallout: string;
    };
    const weaponId = sim.heroes.get(0)?.equipmentId ?? "";
    assertV2SchemaRow(match, weaponId);
    assertV2SnapPlayer(snap, weaponId);
    expect(match.streakCallout).toBe("TRIPLE");
    expect(match.streakSubtitle).toBe("3");
    expect(match.streakCalloutTicks).toBe(12);
    expect(match.streakCalloutShutdown).toBe(true);
    expect(snap.streakCallout).toBe("TRIPLE");
    expect(Array.isArray(snap.effects)).toBe(true);
    expect(match.effects.length).toBe(snap.effects.length);
    expect(typeof match.finishCine.fly).toBe("number");
  });

  it("탄 schema 가 radius·arc·heavy·src 를 싣는다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    sim.countdown = 0;
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const hero0 = sim.heroes.get(0);
    const aimX = (hero0?.x ?? 0) + 80;
    sim.pushInput(0, {
      mx: 1, my: 0, fire: true, firePressed: true, seq: 1, aimX, aimY: 2380,
    });
    for (let i = 0; i < 12; i += 1) {sim.step(FIXED_DT);}
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    expect(match.bullets.size).toBeGreaterThan(0);
    const b = [...match.bullets.values()][0];
    expect(b.radius).toBeGreaterThan(0);
    expect(typeof b.arc).toBe("boolean");
    expect(typeof b.heavy).toBe("boolean");
    expect(typeof b.src).toBe("string");
  });
});
