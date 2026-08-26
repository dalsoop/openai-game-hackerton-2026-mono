import { describe, expect, it } from "vitest";
import { FIXED_DT } from "@/lib/hub/match-sim";
import { LobbyState } from "@/lib/hub/lobby-state";
import { SNAP_DT, seed, tick, writeMatchSchema } from "@/lib/hub/match-authority";

describe("MatchAuthority 스냅 주기", () => {
  it("스냅은 20Hz (FIXED_DT × 3)", () => {
    expect(SNAP_DT).toBeCloseTo(FIXED_DT * 3, 10);
  });

  it("advance 는 매 틱 스키마를 쓰지 않는다", () => {
    const state = new LobbyState();
    const auth = seed([{ slot: 0, name: "호스트" }, { slot: 1, name: "게스트" }], "full");
    writeMatchSchema(state, auth.sim);
    const bootTick = state.matchTick;
    const bootX = state.heroes.get("0")?.x ?? 0;
    auth.pushInput(0, { mx: 1, my: 0, seq: 3, aimX: bootX + 80, aimY: 2380 });
    let snap: Record<string, unknown> | null = null;
    for (let i = 0; i < 80; i += 1) {
      snap = tick(auth, SNAP_DT, state).snap;
    }
    expect(state.matchTick).toBe(bootTick);
    expect(state.heroes.get("0")?.x).toBe(bootX);
    expect(snap).not.toBeNull();
    const me = (snap?.players as Array<{ slot: number; x: number; ack: number }> | undefined)
      ?.find((p) => p.slot === 0);
    expect(me?.ack).toBe(3);
    expect(me?.x).toBeGreaterThan(bootX);
  });
});
