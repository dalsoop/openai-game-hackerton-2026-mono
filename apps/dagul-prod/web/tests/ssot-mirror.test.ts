/**
 * TS 정본 vs GD 거울 표. 복제가 어긋나면 여기서 깨진다.
 * 권위 숫자는 web/lib/hub, Godot 은 같은 값을 복사만 한다.
 */
import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";
import {
  ANIMAL_SIGNATURE_EQUIPMENT, EQUIPMENT_DEFS, EQUIP_VISUAL, GUN_LOOT_CHAIN,
  MODE_START_EQUIPMENT, combatStatsFor, identityFor, makeEquipment, mobilityFor,
} from "@/lib/hub/match-equipment";
import { ARENA_CENTER, ARENA_MARGIN, ARENA_SIZE, HERO_RADIUS } from "@/lib/hub/match-covers";
import { HITSTUN_MOVE_MULT } from "@/lib/hub/match-cc";
import { MATCH_INPUT_SANITIZE } from "@/lib/hub/match-input-schema";
import { ITEM_WIRE_CASES, packItemStack } from "@/lib/hub/match-item-wire";

const GD = join(process.cwd(), "..", "project");
const readGd = (rel: string): string => readFileSync(join(GD, rel), "utf8");

function gdStringList(src: string, name: string): string[] {
  const block = src.match(new RegExp(`${name}\\s*:=\\s*\\[([^\\]]+)\\]`));
  if (!block) {throw new Error(`${name} 목록 없음`);}
  return [...block[1].matchAll(/"([^"]+)"/g)].map((m) => m[1]);
}

function gdStringMap(src: string, name: string): Record<string, string> {
  const block = src.match(new RegExp(`${name}\\s*:=\\s*\\{([^}]+)\\}`));
  if (!block) {throw new Error(`${name} 맵 없음`);}
  const out: Record<string, string> = {};
  for (const m of block[1].matchAll(/"([^"]+)"\s*:\s*"([^"]+)"/g)) {
    out[m[1]] = m[2];
  }
  return out;
}

function gdNumber(src: string, name: string): number {
  const m = src.match(new RegExp(`(?:^|\\n)(?:const|var)\\s+${name}\\s*:=\\s*([0-9.]+)`));
  if (!m) {throw new Error(`${name} 숫자 없음`);}
  return Number(m[1]);
}

function gdVec2(src: string, name: string): { x: number; y: number } {
  const m = src.match(new RegExp(`(?:^|\\n)(?:const|var)\\s+${name}\\s*:=\\s*Vector2\\(([0-9.]+)\\s*,\\s*([0-9.]+)\\)`));
  if (!m) {throw new Error(`${name} Vector2 없음`);}
  return { x: Number(m[1]), y: Number(m[2]) };
}

function gdReturnDicts(src: string, fn: string): Record<string, Record<string, string | number>> {
  const start = src.indexOf(`func ${fn}`);
  if (start < 0) {throw new Error(`${fn} 없음`);}
  const body = src.slice(start, src.indexOf("\nfunc ", start + 1));
  const out: Record<string, Record<string, string | number>> = {};
  for (const m of body.matchAll(/(?:\"([^\"]+)\"|_):\s*return\s*\{([^}]+)\}/g)) {
    const row: Record<string, string | number> = {};
    for (const f of m[2].matchAll(/"([^"]+)":\s*([^,}]+)/g)) {
      const raw = f[2].trim();
      row[f[1]] = raw.startsWith("\"") ? raw.slice(1, -1) : Number(raw);
    }
    out[m[1]] = row;
  }
  return out;
}

function gdEquipVisual(src: string): Record<string, { frame: number; family: string }> {
  const start = src.indexOf("const EQUIP_VISUAL");
  const end = src.indexOf("const GUN_FEEL", start);
  const body = src.slice(start, end);
  const out: Record<string, { frame: number; family: string }> = {};
  for (const m of body.matchAll(/"(\w+)":\s*\{([^}]+)\}/g)) {
    const frame = Number(m[2].match(/"frame":\s*(\d+)/)?.[1]);
    const family = m[2].match(/"family":\s*"([^"]+)"/)?.[1] ?? "";
    out[m[1]] = { frame, family };
  }
  return out;
}

function gdDefs(): Array<{ id: string; name: string; mag_size: number; damage: number; burst_shots: number }> {
  const src = readGd("games/dagul/sim/equipment_registry.gd");
  const start = src.indexOf("var defs :=");
  const end = src.indexOf("\nfunc ", start);
  const body = src.slice(start, end);
  return [...body.matchAll(/\{"id":"(\w+)"[^}]+\}/g)].map((m) => {
    const d = m[0];
    return {
      id: m[1],
      name: d.match(/"name":"([^"]+)"/)?.[1] ?? "",
      mag_size: Number(d.match(/"mag_size":([0-9.]+)/)?.[1]),
      damage: Number(d.match(/"damage":([0-9.]+)/)?.[1]),
      burst_shots: Number(d.match(/"burst_shots":([0-9.]+)/)?.[1]),
    };
  });
}

describe("SSOT 거울: 장비 표", () => {
  const gd = readGd("games/dagul/sim/equipment_registry.gd");

  it("GUN_LOOT_CHAIN 이 같다", () => {
    expect(gdStringList(gd, "GUN_LOOT_CHAIN")).toEqual([...GUN_LOOT_CHAIN]);
  });

  it("MODE_START_EQUIPMENT 이 같다", () => {
    expect(gdStringMap(gd, "MODE_START_EQUIPMENT")).toEqual({ ...MODE_START_EQUIPMENT });
  });

  it("defs id·이름·탄창·데미지·버스트가 같다", () => {
    const rows = gdDefs();
    expect(rows.map((r) => r.id)).toEqual(EQUIPMENT_DEFS.map((d) => d.id));
    for (const row of rows) {
      const def = EQUIPMENT_DEFS.find((d) => d.id === row.id);
      expect(def, row.id).toBeDefined();
      if (!def) {continue;}
      expect(row.name, row.id).toBe(def.name);
      expect(row.mag_size, row.id).toBe(def.magSize);
      expect(row.damage, row.id).toBe(def.damage);
      expect(row.burst_shots, row.id).toBe(def.burstShots);
    }
  });

  it("combat move_speed·max_hp 가 같다", () => {
    const rows = gdReturnDicts(gd, "combat_stats_for");
    for (const def of EQUIPMENT_DEFS) {
      const row = rows[def.id] ?? rows._;
      expect(row.move_speed, def.id).toBe(combatStatsFor(def.id).moveSpeed);
      expect(row.max_hp, def.id).toBe(combatStatsFor(def.id).maxHp);
    }
  });

  it("mobility 거리·쿨다운이 같다", () => {
    const rows = gdReturnDicts(gd, "mobility_for");
    for (const def of EQUIPMENT_DEFS) {
      const row = rows[def.id] ?? rows._;
      expect(row.mobility_distance, def.id).toBe(mobilityFor(def.id).mobilityDistance);
      expect(row.mobility_cooldown, def.id).toBe(mobilityFor(def.id).mobilityCooldown);
    }
  });

  it("identity character_name 이 같다", () => {
    const rows = gdReturnDicts(gd, "identity_for");
    for (const def of EQUIPMENT_DEFS) {
      const row = rows[def.id] ?? rows._;
      expect(row.character_name, def.id).toBe(identityFor(def.id).characterName);
    }
  });
});

describe("SSOT 거울: 총 비주얼", () => {
  it("ANIMAL_SIGNATURE_EQUIPMENT 이 같다", () => {
    const gd = readGd("games/dagul/sim/gun_signature.gd");
    expect(gdStringList(gd, "ANIMAL_SIGNATURE_EQUIPMENT")).toEqual([...ANIMAL_SIGNATURE_EQUIPMENT]);
  });

  it("EQUIP_VISUAL frame·family 가 같다", () => {
    const rows = gdEquipVisual(readGd("games/dagul/sim/gun_signature.gd"));
    expect(Object.keys(rows).sort()).toEqual(Object.keys(EQUIP_VISUAL).sort());
    for (const id of Object.keys(EQUIP_VISUAL)) {
      expect(rows[id].frame, id).toBe(EQUIP_VISUAL[id].frame);
      expect(rows[id].family, id).toBe(EQUIP_VISUAL[id].family);
    }
  });
});

describe("SSOT 거울: 아레나·예측 상수", () => {
  it("arena_geometry 크기가 match-covers 와 같다", () => {
    const gd = readGd("games/dagul/sim/arena_geometry.gd");
    expect(gdVec2(gd, "ARENA_SIZE")).toEqual(ARENA_SIZE);
    expect(gdVec2(gd, "ARENA_CENTER")).toEqual(ARENA_CENTER);
    expect(gdNumber(gd, "ARENA_MARGIN")).toBe(ARENA_MARGIN);
    expect(gdNumber(gd, "HERO_RADIUS")).toBe(HERO_RADIUS);
  });

  it("net_pred HITSTUN_MOVE_MULT 가 match-cc 와 같다", () => {
    const gd = readGd("games/dagul/net/net_pred.gd");
    expect(gdNumber(gd, "HITSTUN_MOVE_MULT")).toBe(HITSTUN_MOVE_MULT);
  });
});

describe("SSOT 거울: 입력 칸·아이템 와이어", () => {
  it("peer 패킷 키가 MatchInputSchema sanitize 칸을 덮는다", () => {
    const src = readGd("games/dagul/game.gd");
    const block = src.slice(src.indexOf("func _peer_input_packet"), src.indexOf("func _check_tutorial"));
    const keys = [...block.matchAll(/"(\w+)":/g)].map((m) => m[1]).filter((k) => k !== "seq");
    const schemaKeys = Object.keys(MATCH_INPUT_SANITIZE);
    for (const key of keys) {
      expect(schemaKeys, key).toContain(key);
    }
  });

  it("ITEM_WIRE_CASES 가 packItemStack 과 같다", () => {
    for (const row of ITEM_WIRE_CASES) {
      expect(packItemStack(row.kind, row.count)).toBe(row.wire);
    }
  });

  it("makeEquipment 이 GD mag_size 와 같은 탄창을 낸다", () => {
    for (const row of gdDefs()) {
      expect(makeEquipment(row.id).magSize).toBe(row.mag_size);
    }
  });
});
