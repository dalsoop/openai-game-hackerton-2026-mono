import { describe, expect, it } from "vitest";
import { packAuthoritySnap } from "@/lib/hub/match-authority-snap";
import { COMBO_TIME_FINISHER } from "@/lib/hub/match-cc";
import { HERO_RADIUS } from "@/lib/hub/match-covers";
import { makeEquipment } from "@/lib/hub/match-equipment";
import {
  ARC_BOMB_RADIUS, BOMB_ARC_BLAST, BOMB_ARC_DISTANCE, BOMB_ARC_FLIGHT, MORTAR_SPLASH,
  gunSeedFields, spawnArcBomb, tryNormalAttack, type GunHero,
} from "@/lib/hub/match-gun";
import { MatchStateSchema } from "@/lib/hub/match-schema";
import { writeMatchState } from "@/lib/hub/match-schema-write";
import { MatchSim, type SimBullet } from "@/lib/hub/match-sim";

const DT = 1 / 60;

function gunHero(id: string, over: Partial<GunHero> = {}): GunHero {
  const eq = makeEquipment(id);
  return {
    slot: 0, x: 4000, y: 2400, hp: eq.maxHp, maxHp: eq.maxHp, alive: true,
    stunTime: 0, launchTime: 0, rootTime: 0, facingX: 1, facingY: 0, aimX: 1, aimY: 0,
    ...gunSeedFields(eq), ...over, equipment: over.equipment ?? eq,
  };
}

function equipMortar(sim: MatchSim): NonNullable<ReturnType<MatchSim["heroes"]["get"]>> {
  const h = sim.heroes.get(0);
  if (!h) {throw new Error("hero 0");}
  const eq = makeEquipment("mortar");
  h.equipment = eq;
  h.equipmentId = "mortar";
  h.mag = eq.magSize;
  h.magMax = eq.magSize;
  return h;
}

describe("포물선 유탄 스폰", () => {
  it("mortar 일반공격은 직선 shell — max(radius*3,12), splash 120, arc 아님", () => {
    const h = gunHero("mortar");
    const r = tryNormalAttack(h, { x: 1, y: 0 });
    expect(r.projectiles).toHaveLength(1);
    const p = r.projectiles[0];
    expect(p.arc).toBeFalsy();
    expect(p.kind).toBe("shell");
    expect(p.radius).toBe(Math.max(9 * 3, 12));
    expect(p.splash).toBe(MORTAR_SPLASH);
    expect(p.vx).toBeCloseTo(h.equipment.speed, 8);
  });

  it("bomb 일반공격은 펠릿 6발. spawn_arc_bomb API 는 착탄 330·비행 0.50·폭 76", () => {
    const h = gunHero("bomb");
    const r = tryNormalAttack(h, { x: 1, y: 0 });
    expect(r.projectiles).toHaveLength(6);
    expect(r.projectiles[0]?.arc).toBeFalsy();
    const spawned = spawnArcBomb(
      h, { x: 1, y: 0 }, BOMB_ARC_DISTANCE, BOMB_ARC_FLIGHT, 27.4, BOMB_ARC_BLAST, 0, 28, false,
    );
    expect(spawned.arc).toBe(true);
    expect(spawned.kind).toBe("shell");
    expect(spawned.ttl).toBe(BOMB_ARC_FLIGHT);
    expect(spawned.splash).toBe(BOMB_ARC_BLAST);
    expect(spawned.landingX).toBeCloseTo(h.x + BOMB_ARC_DISTANCE, 8);
    expect(spawned.radius).toBe(ARC_BOMB_RADIUS);
  });
});

describe("착탄 폭발·비행 중 무충돌", () => {
  it("arc 탄은 비행 중 히어로를 스치지 않고 ttl 소진 시 landing 스플래시", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    if (!a || !b) {throw new Error("heroes");}
    a.x = 1200;
    a.y = 1200;
    b.x = 1300;
    b.y = 1200;
    const hpMid = b.hp;
    sim.bullets.set(9001, {
      id: 9001, x: a.x, y: a.y, vx: 80, vy: 0, owner: 0, ttl: 0.4, kind: "shell",
      damage: 80, radius: ARC_BOMB_RADIUS, splash: 120, pierce: 0, knockback: 42,
      source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [], homing: 0,
      arc: true, landingX: 1800, landingY: 1200, maxTtl: 0.4, comboFinisher: false,
      label: "", controlKind: "slow",
    });
    sim.step(DT);
    expect(sim.bullets.size).toBe(1);
    expect(b.hp).toBe(hpMid);
    b.x = 1800;
    b.y = 1200;
    const hpLand = b.hp;
    const flying = sim.bullets.get(9001);
    expect(flying).toBeDefined();
    if (!flying) {return;}
    flying.ttl = DT * 0.5;
    sim.step(DT);
    expect(sim.bullets.size).toBe(0);
    expect(b.hp).toBeCloseTo(hpLand - 80, 5);
    expect(Math.hypot(b.x - 1800, b.y - 1200)).toBeLessThanOrEqual(120 + HERO_RADIUS);
  });
});

describe("arc 방출", () => {
  it("packAuthoritySnap 은 arc true 만 싣고 스키마 row.arc 를 채운다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const h = equipMortar(sim);
    sim.bullets.set(42, {
      id: 42, x: h.x, y: h.y, vx: 10, vy: 0, owner: 0, ttl: 0.4, kind: "shell",
      damage: 80, radius: ARC_BOMB_RADIUS, splash: 120, pierce: 0, knockback: 42,
      source: "normal", heavy: false, leech: false, ccTime: 0, hitSlots: [], homing: 0,
      arc: true, landingX: h.x + 200, landingY: h.y, maxTtl: 0.4, comboFinisher: false,
      label: "", controlKind: "slow",
    });
    const snap = packAuthoritySnap(sim, new Map(), "full") as {
      bullets: Array<{ arc?: boolean; kind: string }>;
    };
    expect(snap.bullets.some((row) => row.arc === true)).toBe(true);
    const bolt = sim.bullets.get(42) as SimBullet;
    expect(bolt.arc).toBe(true);
    const match = new MatchStateSchema();
    writeMatchState(match, sim, new Map(), "full");
    const row = [...match.bullets.values()].find((item) => item.id === 42);
    expect(row?.arc).toBe(true);
    bolt.arc = false;
    const plain = packAuthoritySnap(sim, new Map(), "full") as { bullets: Array<{ id: number; arc?: boolean }> };
    expect(plain.bullets.find((item) => item.id === 42)?.arc).toBeUndefined();
  });
});

describe("피니셔 ctx", () => {
  it("탄 comboFinisher·label 이 hurtHero 로 전달되어 콤보 피니셔 타이머가 선다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    if (!a || !b) {throw new Error("heroes");}
    a.x = 2000;
    a.y = 2400;
    b.x = 2050;
    b.y = 2400;
    sim.bullets.set(7, {
      id: 7, x: b.x, y: b.y, vx: 0, vy: 0, owner: 0, ttl: 1, kind: "bolt",
      damage: 5, radius: 80, splash: 0, pierce: 0, knockback: 8,
      source: "normal", heavy: true, leech: false, ccTime: 0, hitSlots: [], homing: 0,
      arc: false, landingX: 0, landingY: 0, maxTtl: 1, comboFinisher: true,
      label: "HEAVY", controlKind: "slow",
    });
    sim.step(DT);
    expect(b.comboTime).toBeCloseTo(COMBO_TIME_FINISHER, 8);
    expect(b.comboHits).toBe(1);
    expect(sim.effects.items.some((e) => e.label === "HEAVY")).toBe(true);
  });
});
