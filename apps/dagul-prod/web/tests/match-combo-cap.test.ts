import { describe, expect, it } from "vitest";
import { ComboCap } from "@/lib/hub/match-combo-cap";
import { makeEquipment } from "@/lib/hub/match-equipment";

describe("ComboCap 객체 — original_game_world.gd:3780-3784", () => {
  it("한도는 maxHp * comboCapRatio 이고 remaining = limit - spent", () => {
    const cap = ComboCap.fromCareer(137, 0.27);
    expect(cap.limit).toBeCloseTo(36.99, 10);
    expect(cap.remaining()).toBeCloseTo(36.99, 10);
    expect(ComboCap.limitOf(155, 0.26)).toBeCloseTo(40.3, 10);
  });

  it("take 는 잔여만 넣고 spent 에 적립한다", () => {
    const cap = ComboCap.fromCareer(100, 0.26);
    expect(cap.take(50)).toBeCloseTo(26, 10);
    expect(cap.spent).toBeCloseTo(26, 10);
    expect(cap.take(10)).toBe(0);
    expect(cap.remaining()).toBe(0);
  });

  it("음수 후보는 0, 커리어를 모르면 한도 없이 통과", () => {
    const cap = ComboCap.fromCareer(100, 0.26);
    expect(cap.take(-8)).toBe(0);
    const open = ComboCap.of({}, 0);
    expect(open.take(999)).toBe(999);
  });

  it("히트 어댑터는 comboDamage 를 spent 로 쓴다", () => {
    const h = {
      maxHp: 137,
      equipment: { comboCapRatio: 0.27 },
      comboDamage: 0,
    };
    expect(ComboCap.takeHit(h, 142)).toBeCloseTo(36.99, 10);
    expect(h.comboDamage).toBeCloseTo(36.99, 10);
    expect(ComboCap.takeHit(h, 50)).toBe(0);
  });

  it("벽 어댑터는 launchWallDamage 를 spent 로 이어 받는다", () => {
    const h = {
      maxHp: 100,
      comboCapRatio: 0.26,
      launchWallDamage: 20,
    };
    expect(ComboCap.takeWall(h, 36)).toBeCloseTo(6, 10);
    expect(h.launchWallDamage).toBeCloseTo(26, 10);
    expect(ComboCap.takeWall(h, 15)).toBe(0);
  });

  it("버스트 몸 한 콤보는 풀피를 못 가져간다 (pjh 스모크 계약)", () => {
    const burst = makeEquipment("burst");
    const h = { maxHp: burst.maxHp, equipment: burst, comboDamage: 0 };
    let hp = burst.maxHp;
    for (let hit = 0; hit < 4; hit += 1) {
      hp -= ComboCap.takeHit(h, 50);
    }
    const floor = burst.maxHp * (1 - burst.comboCapRatio);
    expect(hp).toBeGreaterThanOrEqual(floor - 0.01);
    expect(h.comboDamage).toBeCloseTo(ComboCap.limitOf(burst.maxHp, burst.comboCapRatio), 10);
  });
});
