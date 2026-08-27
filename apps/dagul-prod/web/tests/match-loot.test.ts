import { describe, expect, it } from "vitest";
import {
  HEALTH_PICKUP_MAGNET_SPEED, HEALTH_PICKUP_RESPAWN, HEALTH_PICKUP_RETURN_SPEED,
  MEDKIT_MAX, SLIDE_DURATION, SPRING_AIR, SPRING_BOOST, SPRING_EVADE, SPRING_LIFT,
  buildHealthPickups, handleUseInput, lootSeedFields, packItemField,
  packLootSnap, spawnGunLootPickup, tryCollectGunLoot, tryUseHeldItem, tryUseMedkit,
  updateHealthPickups,
} from "@/lib/hub/match-loot";
import type { LootHero } from "@/lib/hub/match-loot";
import { ARENA_CENTER } from "@/lib/hub/match-covers";
import { MatchSim } from "@/lib/hub/match-sim";
import { packAuthoritySnap } from "@/lib/hub/match-authority";
import { equipmentForAnimal, makeEquipment } from "@/lib/hub/match-equipment";

/** 회복 픽업·메드킷 — 사양(pickups-items.md) full 모드 수치 그대로의 회귀. */

const DT = 1 / 60;

function hero(slot: number, over: Partial<LootHero> = {}): LootHero {
  return {
    slot, x: ARENA_CENTER.x, y: ARENA_CENTER.y, hp: 176, maxHp: 176,
    alive: true, eliminated: false, ...lootSeedFields(), ...over,
  };
}

function heroMap(...list: LootHero[]): Map<number, LootHero> {
  return new Map(list.map((h) => [h.slot, h]));
}

describe("타일 전개 좌표", () => {
  it("4 소스점 x 2x2 타일 = 16개, home 좌표는 origin + source * 1.4", () => {
    const pickups = buildHealthPickups();
    expect(pickups).toHaveLength(16);
    // 타일 (0,0) — 소스 4점 그대로 1.4배
    expect(pickups[0].x).toBeCloseTo(1960);
    expect(pickups[0].y).toBeCloseTo(602);
    expect(pickups[1].x).toBeCloseTo(1960);
    expect(pickups[1].y).toBeCloseTo(1778);
    expect(pickups[2].x).toBeCloseTo(1064);
    expect(pickups[2].y).toBeCloseTo(1190);
    expect(pickups[3].x).toBeCloseTo(2856);
    expect(pickups[3].y).toBeCloseTo(1190);
    // 마지막 타일 (1,1) 의 마지막 소스 (2040,850) -> (6776,3570)
    expect(pickups[15].x).toBeCloseTo(6776);
    expect(pickups[15].y).toBeCloseTo(3570);
    for (const p of pickups) {
      expect(p.active).toBe(true);
      expect(p.magnetSlot).toBe(-1);
      expect(p.homeX).toBeCloseTo(p.x);
      expect(p.homeY).toBeCloseTo(p.y);
    }
  });
});

describe("습득 → 회복 → 16초 재생성", () => {
  it("메드킷 슬롯이 비면 적재, 픽업은 비활성 + respawn 16", () => {
    const pickups = buildHealthPickups();
    const h = hero(0, { x: pickups[0].homeX, y: pickups[0].homeY });
    updateHealthPickups(pickups, heroMap(h), DT);
    expect(h.medkits).toBe(1);
    expect(h.hp).toBe(176);
    expect(pickups[0].active).toBe(false);
    expect(pickups[0].respawn).toBe(HEALTH_PICKUP_RESPAWN);
  });

  it("메드킷 3개 가득이면 즉시 회복 — max_hp * 0.30, 결손과 min", () => {
    const pickups = buildHealthPickups();
    const h = hero(0, {
      x: pickups[0].homeX, y: pickups[0].homeY, hp: 100, medkits: MEDKIT_MAX,
    });
    updateHealthPickups(pickups, heroMap(h), DT);
    expect(h.medkits).toBe(MEDKIT_MAX);
    expect(h.hp).toBeCloseTo(100 + 176 * 0.30);
  });

  it("가득 + 결손이 30% 미만이면 max_hp 에서 클램프", () => {
    const pickups = buildHealthPickups();
    const h = hero(0, {
      x: pickups[0].homeX, y: pickups[0].homeY, hp: 170, medkits: MEDKIT_MAX,
    });
    updateHealthPickups(pickups, heroMap(h), DT);
    expect(h.hp).toBe(176);
  });

  it("습득 16초 뒤 home 에서 재활성", () => {
    const pickups = buildHealthPickups();
    const h = hero(0, { x: pickups[0].homeX, y: pickups[0].homeY });
    updateHealthPickups(pickups, heroMap(h), DT);
    expect(pickups[0].active).toBe(false);
    const empty = heroMap();
    // 15초 시점 — 아직 비활성
    for (let i = 0; i < 900; i++) {updateHealthPickups(pickups, empty, DT);}
    expect(pickups[0].active).toBe(false);
    // 16초 초과 — 재활성, 위치는 home
    for (let i = 0; i < 65; i++) {updateHealthPickups(pickups, empty, DT);}
    expect(pickups[0].active).toBe(true);
    expect(pickups[0].x).toBeCloseTo(pickups[0].homeX);
    expect(pickups[0].y).toBeCloseTo(pickups[0].homeY);
    expect(pickups[0].magnetSlot).toBe(-1);
  });
});

describe("자석 끌림", () => {
  it("반경 217 안의 히어로에게 760px/s 로 끌린다", () => {
    const pickups = buildHealthPickups();
    const p = pickups[0];
    const h = hero(0, { x: p.homeX + 200, y: p.homeY });
    updateHealthPickups(pickups, heroMap(h), DT);
    expect(p.magnetSlot).toBe(0);
    expect(p.x).toBeCloseTo(p.homeX + HEALTH_PICKUP_MAGNET_SPEED * DT);
    expect(p.y).toBeCloseTo(p.homeY);
  });

  it("반경 밖(217 초과) 히어로는 무시하고 그대로", () => {
    const pickups = buildHealthPickups();
    const p = pickups[0];
    const h = hero(0, { x: p.homeX + 400, y: p.homeY });
    updateHealthPickups(pickups, heroMap(h), DT);
    expect(p.magnetSlot).toBe(-1);
    expect(p.x).toBeCloseTo(p.homeX);
  });

  it("끌리다 접촉 반경(47) 안이면 습득된다", () => {
    const pickups = buildHealthPickups();
    const p = pickups[0];
    const h = hero(0, { x: p.homeX + 50, y: p.homeY });
    // 1틱 이동 12.67px -> 거리 37.3 <= 47 습득
    updateHealthPickups(pickups, heroMap(h), DT);
    expect(p.active).toBe(false);
    expect(h.medkits).toBe(1);
  });

  it("대상을 잃으면 280px/s 로 home 복귀", () => {
    const pickups = buildHealthPickups();
    const p = pickups[0];
    const h = hero(0, { x: p.homeX + 200, y: p.homeY });
    const map = heroMap(h);
    for (let i = 0; i < 5; i++) {updateHealthPickups(pickups, map, DT);}
    const dragged = p.x;
    expect(dragged).toBeGreaterThan(p.homeX);
    // 유지 반경(217*1.65=358.05) 밖으로 이탈 — 자석 해제 후 복귀
    h.x = p.homeX + 2000;
    updateHealthPickups(pickups, map, DT);
    expect(p.magnetSlot).toBe(-1);
    expect(p.x).toBeCloseTo(dragged - HEALTH_PICKUP_RETURN_SPEED * DT);
    // 사망자도 자석 대상이 아니다
    h.x = p.homeX + 100;
    h.alive = false;
    updateHealthPickups(pickups, map, DT);
    expect(p.magnetSlot).toBe(-1);
  });
});

describe("메드킷 사용·소진", () => {
  it("사용 — medkits 1 감소, max_hp * 0.30 회복(클램프)", () => {
    const h = hero(0, { hp: 100, medkits: 2 });
    expect(tryUseMedkit(h)).toBe(true);
    expect(h.medkits).toBe(1);
    expect(h.hp).toBeCloseTo(100 + 176 * 0.30);
  });

  it("가드 — 만피(hp >= max_hp - 0.5)·소진·사망이면 불가", () => {
    expect(tryUseMedkit(hero(0, { hp: 175.6, medkits: 1 }))).toBe(false);
    expect(tryUseMedkit(hero(0, { hp: 100, medkits: 0 }))).toBe(false);
    expect(tryUseMedkit(hero(0, { hp: 100, medkits: 1, alive: false }))).toBe(false);
    const h = hero(0, { hp: 175.4, medkits: 1 });
    expect(tryUseMedkit(h)).toBe(true);
    expect(h.hp).toBe(176);
  });

  it("use 홀드는 1회만 — 에지에서만 소비, 뗐다 누르면 다시 사용", () => {
    const h = hero(0, { hp: 10, medkits: 3 });
    handleUseInput(h, true);
    expect(h.medkits).toBe(2);
    for (let i = 0; i < 10; i++) {handleUseInput(h, true);}
    expect(h.medkits).toBe(2);
    handleUseInput(h, false);
    handleUseInput(h, true);
    expect(h.medkits).toBe(1);
  });

  it("다운이면 메드킷을 쓰지 않는다", () => {
    const h = hero(0, { hp: 0, medkits: 2, downed: true });
    handleUseInput(h, true);
    expect(h.medkits).toBe(2);
    expect(h.hp).toBe(0);
    expect(tryUseMedkit(h)).toBe(false);
  });
});

describe("스냅 계약", () => {
  it("packLootSnap — active 만, Godot parse_loot 필드 id·kind·x·y·n", () => {
    const pickups = buildHealthPickups();
    pickups[1].active = false;
    const arr = packLootSnap(pickups);
    expect(arr).toHaveLength(15);
    expect(arr[0]).toEqual({
      id: "0", kind: "item", x: pickups[0].x, y: pickups[0].y, n: "",
      itemKind: "medkit", disguise: "medkit",
    });
  });

  it("P_ITEM — 0은 빈 문자열, 1은 medkit, 2 이상은 medkit:N", () => {
    expect(packItemField(0)).toBe("");
    expect(packItemField(1)).toBe("medkit");
    expect(packItemField(2)).toBe("medkit:2");
    expect(packItemField(3)).toBe("medkit:3");
  });

  it("MatchSim 스냅 — loot 16개 + players.item 전달", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 7);
    const snap = packAuthoritySnap(sim, new Map(), "full");
    const loot = snap.loot as Array<Record<string, unknown>>;
    expect(loot).toHaveLength(16);
    const players = snap.players as Array<Record<string, unknown>>;
    expect(players[0].item).toBe("");
    const h = sim.heroes.get(0);
    if (h) {h.medkits = 1;}
    const again = packAuthoritySnap(sim, new Map(), "full");
    const players2 = again.players as Array<Record<string, unknown>>;
    expect(players2[0].item).toBe("medkit");
    if (h) {h.medkits = 3;}
    const stacked = packAuthoritySnap(sim, new Map(), "full");
    const players3 = stacked.players as Array<Record<string, unknown>>;
    expect(players3[0].item).toBe("medkit:3");
  });

  it("총 루팅 드랍 습득은 applyGunLoot 를 호출해 체인 다음 총으로 교체한다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 7, "gun-semi");
    sim.countdown = 0;
    const h = sim.heroes.get(0);
    expect(h).toBeDefined();
    if (!h) {return;}
    expect(h.equipment.id).toBe("rail");
    const drop = spawnGunLootPickup(sim.loot, h.x, h.y);
    expect(drop.kind).toBe("gun");
    updateHealthPickups(sim.loot, sim.heroes, DT, "gun-semi");
    expect(drop.active).toBe(false);
    expect(h.equipment.id).toBe("burst");
    expect(h.equipmentId).toBe("burst");
    expect(h.mag).toBe(h.equipment.magSize);
    expect(tryCollectGunLoot(h, "item")).toBe(false);
  });

  it("classic 모드도 총 드랍을 습득하고 시작 무기는 동물 시그니처를 유지한다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 7, "classic");
    sim.countdown = 0;
    const h = sim.heroes.get(0);
    expect(h).toBeDefined();
    if (!h) {return;}
    expect(h.equipment.id).toBe(equipmentForAnimal(h.animal));
    h.equipment = makeEquipment("rail");
    h.equipmentId = "rail";
    const drop = spawnGunLootPickup(sim.loot, h.x, h.y);
    updateHealthPickups(sim.loot, sim.heroes, DT, "classic");
    expect(drop.active).toBe(false);
    expect(h.equipment.id).toBe("burst");
    expect(h.equipmentId).toBe("burst");
  });

  it("총 드랍 스냅 n 은 장비 이름, 아이템은 itemKind·disguise 를 싣는다", () => {
    const guns = spawnGunLootPickup([], 10, 20, "bomb");
    const packed = packLootSnap([guns]);
    expect(packed[0]).toMatchObject({ kind: "gun", n: "DOUBLE BARREL", x: 10, y: 20 });
  });

  it("use 입력 통합 — 카운트다운 뒤 use 로 메드킷을 소비한다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }], 7);
    for (let i = 0; i < 181; i++) {sim.step();}
    expect(sim.countdown).toBe(0);
    const h = sim.heroes.get(0);
    expect(h).toBeDefined();
    if (!h) {return;}
    h.x = ARENA_CENTER.x;
    h.y = ARENA_CENTER.y;
    h.hp = 50;
    h.medkits = 2;
    sim.pushInput(0, { use: true, seq: 1 });
    sim.step();
    expect(h.medkits).toBe(1);
    expect(h.hp).toBeCloseTo(50 + h.maxHp * 0.30, 1);
    // 같은 입력 유지 — 에지 검출로 추가 소비 없음
    sim.step();
    expect(h.medkits).toBe(1);
  });
});

describe("spring/slide 아이템 사용", () => {
  it("heldItem spring 은 hop 0.45·높이 36·evade 0.22·부스트 220 을 건다", () => {
    const h = {
      ...hero(0, { heldItem: "spring" }),
      vx: 10, vy: 0, vel: { x: 10, y: 0 }, facingX: 1, facingY: 0,
      slideTime: 0, springTime: 0, evadeTime: 0, hopTime: 0, hopMax: 0, hopHeight: 0,
    };
    expect(tryUseHeldItem(h)).toBe(true);
    expect(h.heldItem).toBe("");
    expect(h.hopTime).toBe(SPRING_AIR);
    expect(h.hopMax).toBe(SPRING_AIR);
    expect(h.hopHeight).toBe(SPRING_LIFT);
    expect(h.evadeTime).toBe(SPRING_EVADE);
    expect(h.springTime).toBe(SPRING_AIR);
    expect(h.vx).toBeCloseTo(10 + SPRING_BOOST, 8);
  });

  it("heldItem slide 는 slideTime 2.2 를 넣고 메드킷을 건너뛴다", () => {
    const h = {
      ...hero(0, { heldItem: "slide", medkits: 2, hp: 10 }),
      vx: 0, vy: 0, vel: { x: 0, y: 0 }, facingX: 1, facingY: 0,
      slideTime: 0, springTime: 0, evadeTime: 0, hopTime: 0, hopMax: 0, hopHeight: 0,
    };
    handleUseInput(h, true);
    expect(h.slideTime).toBe(SLIDE_DURATION);
    expect(h.medkits).toBe(2);
  });
});
