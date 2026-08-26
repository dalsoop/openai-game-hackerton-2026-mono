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
});
