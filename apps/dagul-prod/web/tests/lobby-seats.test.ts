import { describe, expect, it } from "vitest";
import { HUB_CONFIG } from "@/lib/hub/config";
import { compactLobbySlots, fillMatchSeats, pickHostSessionId } from "@/lib/hub/lobby-seats";
import type { PlayerSchema } from "@/lib/hub/lobby-state";

function seat(sessionId: string, slot: number, connected = true): PlayerSchema {
  return { sessionId, slot, connected } as PlayerSchema;
}

describe("compactLobbySlots", () => {
  it("빈 칸을 메워 0부터 다시 붙인다", () => {
    const players = [{ slot: 2 }, { slot: 0 }, { slot: 5 }];
    compactLobbySlots(players);
    expect(players.map((p) => p.slot).sort((a, b) => a - b)).toEqual([0, 1, 2]);
  });

  it("이미 붙어 있으면 그대로다", () => {
    const players = [{ slot: 0 }, { slot: 1 }];
    compactLobbySlots(players);
    expect(players.map((p) => p.slot)).toEqual([0, 1]);
  });
});

describe("pickHostSessionId", () => {
  it("접속 중인 가장 앞 좌석이 방장이다", () => {
    expect(pickHostSessionId([seat("b", 1), seat("a", 0)])).toBe("a");
  });

  it("끊긴 앞 좌석은 건너뛰고 다음 접속자가 방장이다", () => {
    expect(pickHostSessionId([seat("a", 0, false), seat("b", 1), seat("c", 2)])).toBe("b");
  });

  it("접속자가 없으면 빈 문자열이다", () => {
    expect(pickHostSessionId([seat("a", 0, false)])).toBe("");
    expect(pickHostSessionId([])).toBe("");
  });
});

describe("fillMatchSeats", () => {
  it("혼자 시작해도 8칸을 채우고 빈 자리는 CPU 다", () => {
    const seats = fillMatchSeats([{ slot: 0, name: "호스트", characterId: "animal" }]);
    expect(seats).toHaveLength(HUB_CONFIG.maxPlayers);
    expect(seats[0]).toMatchObject({ slot: 0, name: "호스트", cpu: false });
    expect(seats.filter((s) => s.cpu)).toHaveLength(HUB_CONFIG.maxPlayers - 1);
    expect(seats[1]?.name).toBe("CPU2");
  });

  it("사람 좌석 characterId 는 그대로 두고 슬롯 순으로 정렬한다", () => {
    const seats = fillMatchSeats([
      { slot: 3, name: "셋", characterId: "a3" },
      { slot: 0, name: "영", characterId: "unknown" },
    ]);
    expect(seats[0]).toMatchObject({ slot: 0, characterId: "unknown", cpu: false });
    expect(seats[3]).toMatchObject({ slot: 3, characterId: "a3", cpu: false });
    expect(seats.filter((s) => !s.cpu).map((s) => s.slot)).toEqual([0, 3]);
  });
});
