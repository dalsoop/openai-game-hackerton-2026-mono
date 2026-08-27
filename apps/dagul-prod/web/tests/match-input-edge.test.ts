import { describe, expect, it } from "vitest";
import { MatchSim } from "@/lib/hub/match-sim";

describe("에지 입력 유실 방지 — pushInput 병합", () => {
  it("서버 틱 사이에 패킷이 겹쳐도 dash 에지는 유실되지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    sim.pushInput(0, { dash: true, seq: 1 });
    sim.pushInput(0, { mx: 1, my: 0, dash: false, seq: 2 });
    sim.step(1 / 60);
    const hero = sim.heroes.get(0);
    expect(hero?.mobilityCd ?? 0).toBeGreaterThan(0);
  });

  it("dash 에지는 소비 후 서버 틱마다 반복 적용되지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    sim.pushInput(0, { dash: true, seq: 1 });
    sim.step(1 / 60);
    const hero = sim.heroes.get(0);
    const cdAfterDash = hero?.mobilityCd ?? 0;
    expect(cdAfterDash).toBeGreaterThan(0);
    sim.step(1 / 60);
    expect(hero?.mobilityCd ?? 0).toBeLessThan(cdAfterDash);
  });

  it("use(메드킷)·ultimate 에지도 덮어쓰기에 지지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    sim.pushInput(0, { use: true, ultimate: true, seq: 1 });
    sim.pushInput(0, { use: false, ultimate: false, seq: 2 });
    const stored = (sim as unknown as { inputs: Map<number, Record<string, unknown>> })
      .inputs.get(0);
    expect(stored?.use).toBe(true);
    expect(stored?.ultimate).toBe(true);
  });
});
