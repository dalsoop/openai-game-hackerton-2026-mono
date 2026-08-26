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
  it("사람 랜덤 픽은 플레이어블 bind 로 풀고, CPU 빈 칸은 슬롯 나머지다", () => {
    const sim = new MatchSim([
      { slot: 0, name: "나", characterId: defaultCharacterId() },
      { slot: 1, name: "CPU2", cpu: true },
    ]);
    const human = sim.heroes.get(0);
    expect(human?.animal).toBeGreaterThanOrEqual(0);
    expect(human?.animal).toBeLessThan(12);
    expect(human?.characterId).not.toBe(defaultCharacterId());
    expect(sim.heroes.get(1)?.animal).toBe(1);
    expect(sim.heroes.get(1)?.characterId).toBe(sheetId(1));
  });

  it("시트 id 는 indexBind 숫자로 시드된다", () => {
    expect(sheet).toBeDefined();
    const id = sheetId(5);
    expect(characterBindNumber(id, "animal")).toBe(5);
    const sim = new MatchSim([{ slot: 0, characterId: id }]);
    expect(sim.heroes.get(0)?.animal).toBe(5);
  });

  it("미등재 id 는 랜덤 픽과 같이 플레이어블로 풀린다", () => {
    const sim = new MatchSim([{ slot: 0, characterId: "not-a-character" }]);
    const hero = sim.heroes.get(0);
    expect(hero?.animal).toBeGreaterThanOrEqual(0);
    expect(hero?.animal).toBeLessThan(12);
    expect(hero?.characterId).not.toBe("not-a-character");
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
      players: Array<{ slot: number; animal: number; characterId: string }>;
    };
    const host = snap.players.find((p) => p.slot === 0);
    const guest = snap.players.find((p) => p.slot === 1);
    expect(host).toEqual(expect.objectContaining({ animal: 3, characterId: id }));
    expect(guest).toBeDefined();
    expect(guest).toEqual(
      expect.objectContaining({
        characterId: expect.not.stringMatching(new RegExp(`^${defaultCharacterId()}$`)),
      }),
    );
    if (guest !== undefined) {
      expect(guest.animal).toBeGreaterThanOrEqual(0);
      expect(guest.animal).toBeLessThan(12);
    }
    expect(auth.sim.heroes.get(2)?.cpu).toBe(true);
    expect(auth.sim.heroes.get(2)?.animal).toBe(2);
  });
});
