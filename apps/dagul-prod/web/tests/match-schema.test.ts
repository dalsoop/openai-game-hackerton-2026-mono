import { describe, expect, it } from "vitest";
import { LobbyState } from "@/lib/hub/lobby-state";
import {
  packAuthoritySnap, SNAP_DT, seed as seedAuthority, tick as tickAuthority,
} from "@/lib/hub/match-authority";
import { MatchStateSchema, type MatchHeroSchema } from "@/lib/hub/match-schema";
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
  hero.pullTime = 0.55;
  hero.pocketTime = 5;
  hero.hopTime = 0.18;
  hero.hopMax = 0.3;
  hero.hopHeight = 19;
  hero.mobilityCd = 1.25;
  hero.eliminated = true;
  hero.reloadFlash = 0.55;
  hero.respawnLeft = 2.4;
  hero.sprayIndex = 3.2;
  hero.rouletteDesc = "이번 목숨 동안 공격력이 올라갑니다";
  hero.hitstunTime = 0.18;
  hero.comboCaptureTime = 0.4;
  sim.streakState.streakCallout = "TRIPLE";
  sim.streakState.streakSubtitle = "3";
  sim.streakState.streakCalloutTicks = 12;
  sim.streakState.streakCalloutShutdown = true;
}

function requireHero0(match: MatchStateSchema): MatchHeroSchema {
  const row = match.heroes.get("0");
  if (!row) {throw new Error("schema hero 0");}
  return row;
}

function requirePacked0(snap: { players: Array<Record<string, unknown>> }): Record<string, unknown> {
  const packed = snap.players.find((p) => p.slot === 0);
  if (!packed) {throw new Error("snap player 0");}
  return packed;
}

function assertV2SchemaRow(match: MatchStateSchema, weaponId: string): void {
  const row = requireHero0(match);
  expect(row.emote).toBe(-1);
  expect(row.weaponId).toBe(weaponId);
  expect(row.stunTime).toBeCloseTo(0.4);
  expect(row.action).toBe("STUNNED");
  expect(row.heldItem).toBe("spring");
  expect(row.springTime).toBeCloseTo(0.45);
  expect(row.slideTime).toBeCloseTo(0.2);
  expect(row.rouletteSpin).toBe("tiger");
  expect(row.timedBuffs.length).toBe(0);
  expect(row.clones.length).toBe(0);
  assertV2MotionRow(row);
  assertV2HudRow(row.hud);
  expect(row.hud.eliminated).toBe(true);
}

function assertV2MotionRow(row: {
  pullTime: number; pocketTime: number; hopTime: number; hopMax: number; hopHeight: number;
  mobilityCd: number;
}): void {
  expect(row.pullTime).toBeCloseTo(0.55);
  expect(row.pocketTime).toBeCloseTo(5);
  expect(row.hopTime).toBeCloseTo(0.18);
  expect(row.hopMax).toBeCloseTo(0.3);
  expect(row.hopHeight).toBeCloseTo(19);
  expect(row.mobilityCd).toBeCloseTo(1.25);
}

function assertV2HudRow(row: {
  reloadFlash: number; respawnLeft: number; sprayIndex: number; rouletteDesc: string;
  hitstunTime: number; comboCaptureTime: number;
}): void {
  expect(row.reloadFlash).toBeCloseTo(0.55);
  expect(row.respawnLeft).toBeCloseTo(2.4);
  expect(row.sprayIndex).toBeCloseTo(3.2);
  expect(row.rouletteDesc).toBe("이번 목숨 동안 공격력이 올라갑니다");
  expect(row.hitstunTime).toBeCloseTo(0.18);
  expect(row.comboCaptureTime).toBeCloseTo(0.4);
}

function assertV2SnapPlayer(
  snap: { players: Array<Record<string, unknown>> },
  weaponId: string,
): void {
  const packed = requirePacked0(snap);
  expect(packed.weaponId).toBe(weaponId);
  expect(packed.heldItem).toBe("spring");
  expect(packed.springTime).toBeCloseTo(0.45);
  expect(packed.rouletteSpin).toBe("tiger");
  expect(typeof packed.rouletteSpin).toBe("string");
  assertV2MotionRow(packed as unknown as {
    pullTime: number; pocketTime: number; hopTime: number; hopMax: number; hopHeight: number;
    mobilityCd: number;
  });
  expect(packed.eliminated).toBe(true);
  assertV2HudRow(packed as unknown as {
    reloadFlash: number; respawnLeft: number; sprayIndex: number; rouletteDesc: string;
    hitstunTime: number; comboCaptureTime: number;
  });
}

function assertSchemaSnapParity(
  row: { pullTime: number; pocketTime: number; hopTime: number; hopMax: number; hopHeight: number;
    mobilityCd: number; hud: { eliminated: boolean; moveSpeed: number; medkits: number; mobilityDist: number } },
  packed: Record<string, unknown>,
  moveSpeed: number,
): void {
  expect(row.hud.moveSpeed).toBe(moveSpeed);
  expect(packed.moveSpeed).toBe(moveSpeed);
  expect(row.pullTime).toBe(packed.pullTime);
  expect(row.pocketTime).toBe(packed.pocketTime);
  expect(row.hopTime).toBe(packed.hopTime);
  expect(row.hopMax).toBe(packed.hopMax);
  expect(row.hopHeight).toBe(packed.hopHeight);
  expect(row.mobilityCd).toBe(packed.mobilityCd);
  expect(row.hud.eliminated).toBe(packed.eliminated);
  expect(row.hud.medkits).toBe(packed.medkits ?? 0);
  expect(row.hud.mobilityDist).toBe(packed.mobilityDist);
}

function assertOmittedV2Keys(row: Record<string, unknown>, moveSpeed: number): void {
  expect(row.mobilityCd).toBeUndefined();
  expect(row.hopTime).toBeUndefined();
  expect(row.hopMax).toBeUndefined();
  expect(row.hopHeight).toBeUndefined();
  expect(row.eliminated).toBeUndefined();
  expect(row.pullTime).toBeUndefined();
  expect(row.pocketTime).toBeUndefined();
  expect(row.reloadFlash).toBeUndefined();
  expect(row.respawnLeft).toBeUndefined();
  expect(row.sprayIndex).toBeUndefined();
  expect(row.rouletteDesc).toBeUndefined();
  expect(row.hitstunTime).toBeUndefined();
  expect(row.comboCaptureTime).toBeUndefined();
  expect(row.moveSpeed).toBe(moveSpeed);
}

function collectGunFireSchema(): { packed: SnapEvent[]; row: { tick: number; actor: number; target: number; data: { equipment: string; x: number; y: number } } } {
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
  const row = [...state.match.events.values()].find((ev) => ev.kind === "gun_fire");
  if (!row) {throw new Error("gun_fire schema row");}
  return { packed, row };
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

  it("직선탄도 JSON 스냅과 스키마가 ttl·maxTtl·lx·ly·splash 를 같이 싣는다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    sim.countdown = 0;
    sim.bullets.set(42, {
      id: 42, x: 1800, y: 2100, vx: 400, vy: -50, owner: 0, ttl: 0.7, kind: "bolt",
      damage: 12, radius: 9, splash: 33, pierce: 0, knockback: 0,
      source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [],
      homing: 0, arc: false, landingX: 111, landingY: 222, maxTtl: 1.2,
      comboFinisher: false, label: "", controlKind: "slow",
    });
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    const snap = packAuthoritySnap(sim, names, "full") as {
      bullets: Array<{
        id: number; ttl?: number; maxTtl?: number; lx?: number; ly?: number; splash?: number;
      }>;
    };
    const packed = snap.bullets.find((row) => row.id === 42);
    const schemaRow = match.bullets.get("42");
    expect(packed).toBeDefined();
    expect(schemaRow).toBeDefined();
    if (!packed || !schemaRow) {return;}
    expect(packed.ttl).toBe(0.7);
    expect(packed.maxTtl).toBe(1.2);
    expect(packed.lx).toBe(111);
    expect(packed.ly).toBe(222);
    expect(packed.splash).toBe(33);
    expect(schemaRow.ttl).toBe(packed.ttl);
    expect(schemaRow.maxTtl).toBe(packed.maxTtl);
    expect(schemaRow.lx).toBe(packed.lx);
    expect(schemaRow.ly).toBe(packed.ly);
    expect(schemaRow.splash).toBe(packed.splash);
  });

  it("row.item 과 JSON 스냅 item 이 메드킷 개수를 같이 싣는다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const hero0 = sim.heroes.get(0);
    if (hero0) {hero0.medkits = 3;}
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    const snap = packAuthoritySnap(sim, names, "full") as {
      players: Array<{ slot: number; item?: string }>;
    };
    const p0 = snap.players.find((p) => p.slot === 0) as
      | { slot: number; item?: string; medkits?: number; mobilityDist?: number }
      | undefined;
    expect(p0?.item).toBe("medkit:3");
    expect(p0?.medkits).toBe(3);
    expect(match.heroes.get("0")?.item).toBe("medkit:3");
    expect(match.heroes.get("0")?.hud.medkits).toBe(3);
    expect(match.heroes.get("0")?.hud.mobilityDist).toBe(hero0?.equipment.mobilityDistance);
  });

  it("스키마 timedBuffs·clones 가 배열 칸이다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const hero0 = sim.heroes.get(0);
    if (!hero0) {throw new Error("hero 0");}
    hero0.timedBuffs.push({
      id: "turtle", name: "TURTLE", time: 1.5,
      atk: 0, spd: 0, def: 0, hp: 0, rate: 0, range: 0, shield: 8,
    });
    hero0.clones.push({
      alive: true, ang: 0, pos: { x: 3, y: 4 }, facing: { x: 1, y: 0 },
      aim: { x: 1, y: 0 }, hopTime: 0, hopHeight: 0, animal: 0, owner: 0,
    });
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    const row = requireHero0(match);
    expect(row.timedBuffs.length).toBe(1);
    const buff0 = row.timedBuffs[0];
    const clone0 = row.clones[0];
    expect(buff0.id).toBe("turtle");
    expect(buff0.name).toBe("TURTLE");
    expect(buff0.time).toBeCloseTo(1.5);
    expect(buff0.shield).toBe(8);
    expect(row.clones.length).toBe(1);
    expect(clone0.x).toBe(3);
    expect(clone0.y).toBe(4);
  });

  it("스키마 events 가 JSON 스냅 events 와 같다", () => {
    const { packed, row } = collectGunFireSchema();
    const fire = packed.find((ev) => ev.kind === "gun_fire");
    expect(fire).toBeDefined();
    expect(row).toBeDefined();
    expect(row.tick).toBe(fire?.tick);
    expect(row.actor).toBe(fire?.actor);
    expect(row.target).toBe(fire?.target);
    expect(row.data.equipment).toBe(String(fire?.data.equipment ?? ""));
    expect(row.data.x).toBe(fire?.data.x);
    expect(row.data.y).toBe(fire?.data.y);
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
      batch.push({ tick: i, kind: "gun_fire", actor: 0, target: -1, data: { amount: i } });
    }
    writeMatchState(match, sim, names, "full", batch);
    expect(match.events.size).toBe(EVENT_RING);
    expect(match.eventSeq).toBe(EVENT_RING + 8);
    const rows = [...match.events.values()].sort((a, b) => a.seq - b.seq);
    expect(rows[0].seq).toBe(9);
    expect(rows[0].data.amount).toBe(8);
    expect(rows[EVENT_RING - 1].seq).toBe(EVENT_RING + 8);
    expect(match.events.has("8")).toBe(false);
    expect(match.events.has(String(EVENT_RING + 8))).toBe(true);
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
    const hero = sim.heroes.get(0);
    if (!hero) {throw new Error("hero 0");}
    assertSchemaSnapParity(requireHero0(match), requirePacked0(snap), hero.equipment.moveSpeed);
  });

  it("JSON V2 는 mobilityCd·hopTime·eliminated 을 omit-default 하고 moveSpeed 는 싣는다", () => {
    const sim = new MatchSim(
      [{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }],
      7,
      "full",
    );
    const names = new Map([[0, "호스트"], [1, "게스트"]]);
    const hero = sim.heroes.get(0);
    if (!hero) {throw new Error("hero 0");}
    const empty = packAuthoritySnap(sim, names, "full") as {
      players: Array<Record<string, unknown>>;
    };
    assertOmittedV2Keys(requirePacked0(empty), hero.equipment.moveSpeed);
    const match = new MatchStateSchema();
    writeMatchState(match, sim, names, "full");
    const schema = requireHero0(match);
    expect(schema.mobilityCd).toBe(0);
    expect(schema.hopTime).toBe(0);
    expect(schema.hud.eliminated).toBe(false);
    expect(schema.hud.reloadFlash).toBe(0);
    expect(schema.hud.respawnLeft).toBe(0);
    expect(schema.hud.sprayIndex).toBe(0);
    expect(schema.hud.rouletteDesc).toBe("");
    expect(schema.hud.hitstunTime).toBe(0);
    expect(schema.hud.comboCaptureTime).toBe(0);
    expect(schema.hud.moveSpeed).toBe(hero.equipment.moveSpeed);
    expect(schema.hud.medkits).toBe(hero.medkits);
    expect(schema.hud.mobilityDist).toBe(hero.equipment.mobilityDistance);
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
