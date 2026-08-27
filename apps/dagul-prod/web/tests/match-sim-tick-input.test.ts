// Colyseus 0.18 defineInput 서버 플러밍 — 고정 틱이 준 명령(setTickInput)이
// 그 스텝의 유일한 명령이 되고, 레거시 큐(pushInput)보다 우선한다.
import { describe, expect, it } from "vitest";
import { MatchSim } from "@/lib/hub/match-sim";

describe("MatchSim.setTickInput — defineInput 고정 틱 명령", () => {
  it("setTickInput 한 명령이 그 스텝에 적용된다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    sim.setTickInput(0, { dash: true, seq: 1 });
    sim.step(1 / 60);
    const hero = sim.heroes.get(0);
    expect(hero?.mobilityCd ?? 0).toBeGreaterThan(0);
  });

  it("setTickInput 은 한 번 소비되면 다음 스텝엔 적용되지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    sim.setTickInput(0, { dash: true, seq: 1 });
    sim.step(1 / 60);
    const hero = sim.heroes.get(0);
    const cdAfterDash = hero?.mobilityCd ?? 0;
    expect(cdAfterDash).toBeGreaterThan(0);
    sim.step(1 / 60);
    expect(hero?.mobilityCd ?? 0).toBeLessThan(cdAfterDash);
  });

  it("존재하지 않는 슬롯의 setTickInput 은 조용히 무시된다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    expect(() => sim.setTickInput(9, { dash: true, seq: 1 })).not.toThrow();
  });

  it("setTickInput 이 있으면 레거시 큐(pushInput)보다 우선한다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    const hero = sim.heroes.get(0);
    if (!hero) {throw new Error("hero 0");}
    sim.pushInput(0, { mx: -1, my: 0, seq: 1 }); // 큐: 왼쪽
    sim.setTickInput(0, { mx: 1, my: 0, seq: 1 }); // 고정 틱: 오른쪽
    const x0 = hero.x;
    sim.step(1 / 60);
    expect(hero.x).toBeGreaterThan(x0); // 오른쪽이 이겼다
  });

  it("hasQueuedInput 은 큐에 남은 프레임 유무를 그대로 알린다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    expect(sim.hasQueuedInput(0)).toBe(false);
    sim.pushInput(0, { mx: 1, seq: 1 });
    expect(sim.hasQueuedInput(0)).toBe(true);
    sim.countdown = 0;
    sim.step(1 / 60);
    expect(sim.hasQueuedInput(0)).toBe(false);
  });
});
