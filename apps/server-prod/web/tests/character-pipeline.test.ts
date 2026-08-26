import { describe, expect, it } from "vitest";
import { characterBindNumber, defaultCharacterId } from "@/lib/characters";
import data from "@/lib/characters/characters.json";
import type { CharacterCatalogData } from "@/lib/characters/sheet-source";
import { HUB_CONFIG } from "@/lib/hub/config";
import { fillMatchSeats } from "@/lib/hub/lobby-seats";
import { MatchAuthority, packAuthoritySnap } from "@/lib/hub/match-authority";
import { MatchSim } from "@/lib/hub/match-sim";

const sheet = (data as CharacterCatalogData).sheets?.[0];

function sheetId(index: number): string {
  if (!sheet) {throw new Error("catalog sheet missing");}
  return `${sheet.idPrefix}${index}`;
}

describe("대기실 id → 권위 animal", () => {
  it("사람 좌석은 bind 가 없으면 -1, CPU 는 슬롯 나머지다", () => {
    const sim = new MatchSim([
      { slot: 0, name: "나", characterId: defaultCharacterId() },
      { slot: 1, name: "CPU2", cpu: true },
    ]);
    expect(sim.heroes.get(0)?.animal).toBe(-1);
    expect(sim.heroes.get(1)?.animal).toBe(1);
  });

  it("시트 id 는 indexBind 숫자로 시드된다", () => {
    expect(sheet).toBeDefined();
    const id = sheetId(5);
    expect(characterBindNumber(id, "animal")).toBe(5);
    const sim = new MatchSim([{ slot: 0, characterId: id }]);
    expect(sim.heroes.get(0)?.animal).toBe(5);
  });

  it("미등재 id 는 기본 캐릭터와 같다", () => {
    const sim = new MatchSim([{ slot: 0, characterId: "not-a-character" }]);
    expect(sim.heroes.get(0)?.animal).toBe(-1);
  });

  it("fillMatchSeats 는 사람 characterId 를 유지하고 빈 칸만 CPU 다", () => {
    const id = sheetId(2);
    const seats = fillMatchSeats([{ slot: 0, name: "호스트", characterId: id }]);
    expect(seats).toHaveLength(HUB_CONFIG.maxPlayers);
    expect(seats[0]).toMatchObject({ characterId: id, cpu: false });
    expect(seats.filter((s) => s.cpu).every((s) => s.characterId === undefined)).toBe(true);
  });

  it("권위 스냅과 스키마에 같은 animal 이 실린다", () => {
    const id = sheetId(3);
    const seats = fillMatchSeats([
      { slot: 0, name: "호스트", characterId: id },
      { slot: 1, name: "게스트", characterId: defaultCharacterId() },
    ]);
    const auth = new MatchAuthority(seats, "full");
    const snap = packAuthoritySnap(auth.sim, auth.names, "full") as {
      players: Array<{ slot: number; animal: number }>;
    };
    const bySlot = Object.fromEntries(snap.players.map((p) => [p.slot, p.animal]));
    expect(bySlot[0]).toBe(3);
    expect(bySlot[1]).toBe(-1);
    expect(auth.sim.heroes.get(2)?.cpu).toBe(true);
    expect(auth.sim.heroes.get(2)?.animal).toBe(2);
  });
});
