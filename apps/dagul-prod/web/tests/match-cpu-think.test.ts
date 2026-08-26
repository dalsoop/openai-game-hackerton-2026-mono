import { describe, expect, it } from "vitest";
import {
  bestHealthPickup, cpuWantMedkit, hazardEscapeVector, type CpuBody, type CpuWorld,
} from "@/lib/hub/match-cpu";
import { applyCpu, seedCpu, tickCpu } from "@/lib/hub/match-cpu-think";
import { MatchRng } from "@/lib/hub/match-rng";

const DT = 1 / 60;

function hero(over: Partial<CpuBody> = {}): CpuBody {
  return {
    slot: 0, x: 0, y: 0, alive: true, hp: 100, maxHp: 100, medkits: 0, ...over,
  };
}

describe("회복 탐색", () => {
  it("HP 65% 초과면 픽업을 고르지 않는다", () => {
    const world: CpuWorld = { pickups: [{ x: 80, y: 0, active: true }] };
    expect(bestHealthPickup(hero({ hp: 80, maxHp: 100 }), world)).toBe(-1);
  });

  it("HP 가 낮으면 가까운 활성 픽업으로 SEEK_HEAL 한다", () => {
    const h = hero({ hp: 40, maxHp: 100 });
    const mind = seedCpu(0);
    mind.think = 0;
    const world: CpuWorld = { pickups: [{ x: 200, y: 0, active: true }] };
    const cmd = tickCpu(mind, h, [h], new MatchRng(1), DT, world);
    expect(mind.action).toBe("SEEK_HEAL");
    expect(cmd).toBeTruthy();
    expect(cmd?.mx ?? 0).toBeGreaterThan(0.5);
    expect(Math.abs(cmd?.my ?? 1)).toBeLessThan(0.2);
  });
});

describe("크레이트 사격", () => {
  it("SEEK_CRATE 이고 사거리 안이면 크레이트를 조준해 쏜다", () => {
    const h = hero({ fireCd: 0, normalReach: 400 });
    const mind = seedCpu(0);
    mind.ready = true;
    mind.action = "SEEK_CRATE";
    mind.crateTarget = 0;
    mind.aimX = 1;
    mind.aimY = 0;
    const world: CpuWorld = { crates: [{ x: 80, y: 0, alive: true }] };
    const cmd = applyCpu(mind, h, [h], new MatchRng(1), world);
    expect(cmd?.fire).toBe(true);
    expect(cmd?.aimX).toBe(80);
    expect(cmd?.aimY).toBe(0);
  });
});

describe("위험 회피", () => {
  it("존 경고 안이면 DODGE_WARNING 으로 중심에서 멀어진다", () => {
    const h = hero();
    const mind = seedCpu(0);
    mind.think = 0;
    const world: CpuWorld = {
      warnZones: [{ x: 40, y: 0, radius: 80, owner: 1, delay: 0.2, warningDuration: 0.4 }],
    };
    tickCpu(mind, h, [h], new MatchRng(1), DT, world);
    expect(mind.action).toBe("DODGE_WARNING");
    expect(mind.mx).toBeLessThan(0);
  });

  it("무장된 적 지뢰 트리거 반경 안이면 밖으로 민다", () => {
    const h = hero({ x: 10, y: 0 });
    const esc = hazardEscapeVector(h, {
      deployables: [{
        owner: 1, type: "mine", x: 0, y: 0, armTime: 0,
        triggerRadius: 80, blastRadius: 120, triggered: false,
      }],
    }, [h]);
    expect(esc.x).toBeGreaterThan(0.5);
  });
});

describe("메드킷", () => {
  it("HP 50% 이상이면 use 를 켜지 않는다", () => {
    const h = hero({ hp: 60, maxHp: 100, medkits: 2 });
    expect(cpuWantMedkit(h, new MatchRng(3))).toBe(false);
  });

  it("HP 50% 미만이고 메드킷이 있으면 일부 시드에서 use", () => {
    const h = hero({ hp: 40, maxHp: 100, medkits: 1 });
    let saw = false;
    for (let seed = 0; seed < 40; seed += 1) {
      const mind = seedCpu(0);
      mind.think = 1;
      mind.ready = true;
      const cmd = tickCpu(mind, h, [h], new MatchRng(seed), DT);
      if (cmd?.use) {saw = true;}
    }
    expect(saw).toBe(true);
  });
});
