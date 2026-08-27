import { describe, expect, it } from "vitest";
import { MatchSim, START_COUNTDOWN } from "@/lib/hub/match-sim";
import { makeEquipment } from "@/lib/hub/match-equipment";
import type { SlotInputBuffer } from "@/lib/hub/match-input-queue";

function queued(sim: MatchSim, slot: number): number {
  const bufs = (sim as unknown as { inputBufs: Map<number, SlotInputBuffer> }).inputBufs;
  return bufs.get(slot)?.q.length ?? 0;
}

describe("에지 입력 — 큐가 패킷을 덮어쓰지 않는다", () => {
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

  it("dash 패킷 다음 이동 패킷은 두 틱에 둘 다 적용된다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    const hero = sim.heroes.get(0);
    if (!hero) {return;}
    sim.pushInput(0, { dash: true, seq: 1 });
    sim.pushInput(0, { mx: 1, my: 0, dash: false, seq: 2 });
    sim.step(1 / 60);
    expect(hero.mobilityCd).toBeGreaterThan(0);
    const x = hero.x;
    sim.step(1 / 60);
    expect(hero.x).toBeGreaterThan(x);
  });
});

describe("이동+사격 — 틱당 한 프레임", () => {
  it("틱마다 도착한 firePressed 는 틱마다 한 발이다 — 같은 틱 두 패킷은 접혀 한 발", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    if (!a) {return;}
    a.equipment = makeEquipment("brawler");
    a.mag = a.equipment.magSize;
    sim.pushInput(0, { fire: true, firePressed: true, mx: 1, aimX: a.x + 200, aimY: a.y, seq: 1 });
    sim.pushInput(0, { fire: true, firePressed: true, mx: 1, aimX: a.x + 200, aimY: a.y, seq: 2 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
    a.fireCd = 0;
    sim.pushInput(0, { fire: true, firePressed: true, mx: 1, aimX: a.x + 200, aimY: a.y, seq: 3 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(2);
  });

  it("발사 다음 이동 패킷은 세미를 두 발 만들지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    if (!a) {return;}
    a.equipment = makeEquipment("brawler");
    a.mag = a.equipment.magSize;
    sim.pushInput(0, { fire: true, firePressed: true, mx: 1, aimX: a.x + 200, aimY: a.y, seq: 1 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
    a.fireCd = 0;
    sim.pushInput(0, { fire: true, mx: 1, aimX: a.x + 200, aimY: a.y, seq: 2 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
  });

  it("빈 틱은 mx 를 홀드하고 firePressed 는 다시 켜지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    if (!a) {return;}
    a.equipment = makeEquipment("brawler");
    a.mag = a.equipment.magSize;
    const x0 = a.x;
    sim.pushInput(0, { mx: 1, my: 0, fire: true, firePressed: true, aimX: a.x + 200, aimY: a.y, seq: 1 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(1);
    const x1 = a.x;
    expect(x1).toBeGreaterThan(x0);
    a.fireCd = 0;
    sim.step(1 / 60);
    expect(a.x).toBeGreaterThan(x1);
    expect(sim.bullets.size).toBe(1);
  });

  it("카운트다운 장벽 틱마다 큐를 비운다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdownHeld = true;
    for (let i = 0; i < 8; i += 1) {
      sim.pushInput(0, { mx: 1, dash: true, firePressed: true, seq: i + 1 });
      sim.step(1 / 60);
      expect(queued(sim, 0)).toBe(0);
    }
    expect(sim.countdown).toBe(START_COUNTDOWN);
  });

  it("죽은 동안의 fire 홀드는 부활 직후 세미를 합성하지 않는다", () => {
    const sim = new MatchSim([{ slot: 0, name: "호스트" }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    if (!a) {return;}
    a.equipment = makeEquipment("brawler");
    a.mag = a.equipment.magSize;
    a.alive = false;
    sim.pushInput(0, { fire: true, firePressed: true, aimX: a.x + 200, aimY: a.y, seq: 1 });
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(0);
    a.alive = true;
    a.fireCd = 0;
    sim.step(1 / 60);
    expect(sim.bullets.size).toBe(0);
  });
});
