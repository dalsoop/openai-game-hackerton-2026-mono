import { describe, expect, it } from "vitest";
import { HUB_CONFIG } from "@/lib/hub/config";
import { fillMatchSeats } from "@/lib/hub/lobby-seats";

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
