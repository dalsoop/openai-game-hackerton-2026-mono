import { describe, expect, it } from "vitest";
import {
  ANIMAL_SIGNATURE_EQUIPMENT, EQUIPMENT_DEFS, EQUIP_VISUAL, FALLBACK_COMBAT, FALLBACK_IDENTITY,
  FALLBACK_MOBILITY, GUN_FEEL, GUN_FX, GUN_LOOT_CHAIN, GUN_LOOT_MODES, GUN_TSCN_SCALE, MODE_START_EQUIPMENT,
  combatStatsFor, equipmentForAnimal, equipmentReach, familyOf, feelForEquipment, fxForEquipment,
  gunMountPos, gunWorldScale, identityFor, isSignature, makeEquipment, mobilityFor, muzzleWorldPos,
  nextGunLootId, sprayKick, sprayRecoverRate, sprayStep, startEquipmentId, visualForEquipment,
} from "@/lib/hub/match-equipment";

describe("equipment_registry 12무기", () => {
  it("defs 12행과 loot chain·모드 시작 장비가 원본과 같다", () => {
    expect(EQUIPMENT_DEFS).toHaveLength(12);
    expect(EQUIPMENT_DEFS.map((d) => d.id)).toEqual([
      "scatter", "rail", "mortar", "leech", "breaker", "burst",
      "blade", "brawler", "bomb", "spear", "chain", "shield",
    ]);
    expect(GUN_LOOT_CHAIN).toEqual([
      "rail", "burst", "scatter", "mortar", "breaker", "bomb",
      "leech", "blade", "spear", "chain", "shield", "brawler",
    ]);
    expect(MODE_START_EQUIPMENT).toEqual({ "gun-semi": "rail", "gun-auto": "burst", item: "scatter" });
    expect(GUN_LOOT_MODES).toEqual(["gun-semi", "gun-auto", "full", "classic"]);
    expect(MODE_START_EQUIPMENT).not.toHaveProperty("classic");
  });

  it("핵심 수치: scatter 펠릿5, rail pierce3, mortar splash120, bomb burst2/펠릿6", () => {
    const byId = new Map(EQUIPMENT_DEFS.map((d) => [d.id, d]));
    const need = (id: string): (typeof EQUIPMENT_DEFS)[number] => {
      const row = byId.get(id);
      if (!row) {throw new Error(id);}
      return row;
    };
    expect(need("scatter").projectiles).toBe(5);
    expect(need("scatter").spread).toBe(0.12);
    expect(need("scatter").damage).toBe(33.6);
    expect(need("rail").pierce).toBe(3);
    expect(need("rail").damage).toBe(142.0);
    expect(need("rail").fireMode).toBe("bolt");
    expect(need("mortar").splash).toBe(120.0);
    expect(need("mortar").fireMode).toBe("gl");
    expect(need("bomb").burstShots).toBe(2);
    expect(need("bomb").projectiles).toBe(6);
    expect(need("bomb").magSize).toBe(2);
    expect(need("burst").interval).toBe(0.105);
    expect(need("burst").damage).toBe(13.26);
    expect(need("shield").fireMode).toBe("lever");
    expect(need("shield").damage).toBe(70.2);
    expect(need("leech").interval).toBe(0.095);
    expect(need("chain").speed).toBe(1100.0);
    expect(need("scatter").skillName).toBe("BACKBLAST");
    expect(need("scatter").cooldown).toBe(3.10);
    expect(need("scatter").skillDamage).toBe(7.0);
    expect(need("rail").skillName).toBe("ANCHOR BREAK");
    expect(need("rail").cooldown).toBe(3.50);
    expect(need("shield").skillName).toBe("BULLDOZER WALL");
    expect(need("shield").cooldown).toBe(5.60);
    for (const d of EQUIPMENT_DEFS) {
      expect(d.ultimateName).toBe("");
      expect(d.cooldown).toBeLessThan(10);
      expect(d.skillName.length).toBeGreaterThan(0);
    }
  });

  it("identity/combat/mobility `_` 분기는 WARD HEAVY/BRACE, make 미등재는 scatter", () => {
    expect(identityFor("nope")).toEqual(FALLBACK_IDENTITY);
    expect(identityFor("shield")).toEqual(FALLBACK_IDENTITY);
    expect(combatStatsFor("nope")).toEqual(FALLBACK_COMBAT);
    expect(mobilityFor("nope")).toEqual(FALLBACK_MOBILITY);
    expect(makeEquipment("nope").id).toBe("scatter");
    expect(makeEquipment("nope").characterName).toBe("REX");
    const brawler = makeEquipment("brawler");
    expect(brawler.specialName).toBe("COMEBACK");
    expect(brawler.moveSpeed).toBe(440.0);
    expect(brawler.maxHp).toBe(176.0);
    expect(brawler.weight).toBe(1.12);
    expect(makeEquipment("blade").moveSpeed).toBe(478.0);
    expect(makeEquipment("mortar").mobilityName).toBe("BLAST HOP");
    expect(makeEquipment("mortar").mobilityDistance).toBe(201.0);
  });

  it("12지신 슬롯·posmod 순환·모드 시작 장비", () => {
    expect(ANIMAL_SIGNATURE_EQUIPMENT).toEqual([
      "burst", "breaker", "spear", "brawler", "mortar", "leech",
      "chain", "shield", "blade", "rail", "scatter", "bomb",
    ]);
    expect(equipmentForAnimal(0)).toBe("burst");
    expect(equipmentForAnimal(11)).toBe("bomb");
    expect(equipmentForAnimal(12)).toBe("burst");
    expect(equipmentForAnimal(-1)).toBe("bomb");
    expect(isSignature(9, "rail")).toBe(true);
    expect(isSignature(9, "burst")).toBe(false);
    expect(startEquipmentId("gun-semi", 8)).toBe("rail");
    expect(startEquipmentId("gun-auto", 8)).toBe("burst");
    expect(startEquipmentId("item", 0)).toBe("scatter");
    expect(startEquipmentId("full", 2)).toBe("spear");
    // classic 은 GUN_LOOT_MODES 에 있어도 MODE_START_EQUIPMENT 가 없어 동물 시그니처를 유지한다.
    expect(startEquipmentId("classic", 0)).toBe("burst");
    expect(startEquipmentId("classic", 2)).toBe("spear");
    expect(startEquipmentId("classic", 8)).toBe("blade");
    expect(startEquipmentId("classic", 11)).toBe("bomb");
  });

  it("loot chain: 미등재→rail, 마지막 brawler는 빈 문자열", () => {
    expect(nextGunLootId("unknown")).toBe("rail");
    expect(nextGunLootId("rail")).toBe("burst");
    expect(nextGunLootId("shield")).toBe("brawler");
    expect(nextGunLootId("brawler")).toBe("");
  });

  it("normal_reach = speed * range * 0.92", () => {
    const burst = makeEquipment("burst");
    expect(equipmentReach(burst)).toBeCloseTo(1000.0 * 0.44 * 0.92, 10);
    expect(equipmentReach(burst, 0.5)).toBeCloseTo(1000.0 * 0.44 * 0.92 * 1.5, 10);
  });
});

describe("gun_signature 테이블", () => {
  it("12무기 visual/feel/fx 키와 family 기본", () => {
    expect(Object.keys(EQUIP_VISUAL)).toHaveLength(12);
    expect(Object.keys(GUN_FEEL)).toHaveLength(12);
    expect(Object.keys(GUN_FX)).toHaveLength(12);
    expect(visualForEquipment("rail").frame).toBe(7);
    expect(visualForEquipment("rail").mx).toBe(151.0);
    expect(visualForEquipment("nope").gun).toBe("Glock 18");
    expect(familyOf("burst")).toBe("pistol");
    expect(familyOf("spear")).toBe("rifle");
    expect(feelForEquipment("scatter").kick).toBe(20.0);
    expect(fxForEquipment("bomb").shake).toBe(14);
    expect(fxForEquipment("spear").scale).toBe(1.28);
  });

  it("스프레이 킥·스텝·회복률이 원본 배열과 같다", () => {
    expect(sprayKick("burst", 0)).toEqual({ x: 1, y: -9 });
    expect(sprayKick("burst", 17)).toEqual({ x: -4, y: 0 });
    expect(sprayKick("burst", 99)).toEqual({ x: -4, y: 0 });
    expect(sprayKick("burst", -1)).toEqual({ x: 0, y: 0 });
    expect(sprayKick("bomb", 0)).toEqual({ x: 5, y: -34 });
    expect(sprayKick("mortar", 0)).toEqual({ x: 2, y: -26 });
    expect(sprayKick("spear", 11)).toEqual({ x: 12, y: 1 });
    expect(sprayStep("bomb", 1)).toEqual({ x: -1, y: -56 });
    expect(sprayRecoverRate("spear")).toBe(10.0);
    expect(sprayRecoverRate("rail")).toBe(6.0);
    expect(sprayRecoverRate("nope")).toBe(12.0);
  });

  it("거치·머즐 월드 좌표 공식", () => {
    expect(gunWorldScale()).toBeCloseTo(72.0 / (256.0 * GUN_TSCN_SCALE), 12);
    const mount = gunMountPos(100, 200, 1, 0, 0);
    expect(mount.x).toBeCloseTo(100 + 6 + 18, 10);
    expect(mount.y).toBeCloseTo(200 + 4, 10);
    const left = gunMountPos(100, 200, -1, 0, 2);
    expect(left.x).toBeCloseTo(100 - 6 + -1 * (18 - 2), 10);
    const muzzle = muzzleWorldPos(0, 0, 1, 0, "burst", 0);
    const s = gunWorldScale();
    expect(muzzle.x).toBeCloseTo(6 + 18 + 93.0 * s, 8);
    expect(muzzle.y).toBeCloseTo(4 + -22.000305 * s, 8);
  });
});
