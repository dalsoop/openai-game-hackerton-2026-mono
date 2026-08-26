import { describe, expect, it } from "vitest";
import {
  ARENA_CENTER,
  MATCH_TIME_LIMIT,
  MAX_REVIVES,
  MatchSim,
  SAFE_ZONE_INITIAL_RADIUS,
  SAFE_ZONE_PHASES,
  createSafeZone,
  pickTimeLimitWinner,
  smoothstep01,
  updateSafeZone,
} from "@/lib/hub/match-sim";
import { packAuthoritySnap } from "@/lib/hub/match-authority";

const DT = 1 / 60;

describe("SafeZone", () => {
  it("smoothstep 중간값 — 1단계 축소 절반 지점에서 radius 3027", () => {
    const zone = createSafeZone();
    expect(zone.radius).toBe(SAFE_ZONE_INITIAL_RADIUS);
    updateSafeZone(zone, SAFE_ZONE_PHASES[0].wait); // 대기 20초 소진 → 축소 진입
    expect(zone.shrinking).toBe(true);
    updateSafeZone(zone, SAFE_ZONE_PHASES[0].shrink / 2); // 축소 22초의 절반
    expect(smoothstep01(0.5)).toBeCloseTo(0.5, 10);
    // lerp(3304, 2750, 0.5) = 3027
    expect(zone.radius).toBeCloseTo(3027, 6);
  });

  it("60Hz 루프로 42초에 1단계 축소 완료 — 2750 도달·phase 1", () => {
    const zone = createSafeZone();
    const ticks = Math.ceil(42 / DT) + 3; // 20s wait + 22s shrink + 전이 틱 여유
    for (let i = 0; i < ticks; i++) {updateSafeZone(zone, DT);}
    expect(zone.radius).toBe(SAFE_ZONE_PHASES[0].radius);
    expect(zone.phase).toBe(1);
    expect(zone.shrinking).toBe(false);
    expect(zone.complete).toBe(false);
  });

  it("5단계 전부 끝나면 complete — 최종 반지름 900 유지", () => {
    const zone = createSafeZone();
    for (const phase of SAFE_ZONE_PHASES) {
      updateSafeZone(zone, phase.wait);
      updateSafeZone(zone, phase.shrink);
    }
    updateSafeZone(zone, 10);
    expect(zone.complete).toBe(true);
    expect(zone.phase).toBe(SAFE_ZONE_PHASES.length - 1);
    expect(zone.radius).toBe(900);
  });

  it("장외 히어로는 16/s 연속 피해로 다운 뒤 죽고 킬 크레딧이 없다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    expect(a && b).toBeTruthy();
    if (!a || !b) {return;}
    a.x = ARENA_CENTER.x;
    a.y = ARENA_CENTER.y;
    b.x = 150; // 중심까지 약 4380 > 3304 — 개전부터 장외
    b.y = 150;
    b.revivesUsed = MAX_REVIVES; // 마지막 목숨 — 사망 즉시 탈락(승패는 eliminated 기준)
    const hp0 = b.hp;
    sim.step(DT);
    expect(b.hp).toBeCloseTo(hp0 - 16 * DT, 6);
    let guard = 0;
    while (b.alive && guard < 800) {
      sim.step(DT);
      guard += 1;
    }
    expect(b.alive).toBe(false);
    expect(sim.knockouts.some((k) => k.slot === 1)).toBe(true); // 다운 전이 시 연출
    expect(a.kills).toBe(0); // 환경 사망 — 킬 미적립
    expect(b.eliminated).toBe(true);
    expect(sim.result).toBe("won");
    expect(sim.winner).toBe(0);
  });

  it("210초 도달 시 HP 비율 우위 슬롯이 승자다 (카운트다운 제외)", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    expect(a && b).toBeTruthy();
    if (!a || !b) {return;}
    a.x = ARENA_CENTER.x;
    a.y = ARENA_CENTER.y;
    b.x = ARENA_CENTER.x + 100;
    b.y = ARENA_CENTER.y;
    a.hp = 100;
    b.hp = 50;
    // 카운트다운 3초 동안은 매치 시간이 흐르지 않는다.
    for (let i = 0; i < 180; i++) {sim.step(DT);}
    expect(sim.matchTime).toBe(0);
    const ticks = Math.ceil(MATCH_TIME_LIMIT / DT) + 2;
    for (let i = 0; i < ticks && sim.result === "playing"; i++) {sim.step(DT);}
    expect(sim.matchTime).toBe(MATCH_TIME_LIMIT);
    expect(sim.result).toBe("won");
    expect(sim.winner).toBe(0);
  });

  it("시간 판정 우선순위 — HP비율 > 점수 > 낮은 슬롯", () => {
    const hero = (slot: number, hp: number, kills: number): {
      slot: number; hp: number; maxHp: number; alive: boolean; kills: number;
    } => ({ slot, hp, maxHp: 176, alive: true, kills });
    expect(pickTimeLimitWinner([hero(0, 50, 5), hero(1, 100, 0)])).toBe(1);
    expect(pickTimeLimitWinner([hero(0, 100, 0), hero(1, 100, 2)])).toBe(1);
    expect(pickTimeLimitWinner([hero(1, 100, 1), hero(0, 100, 1)])).toBe(0);
    expect(pickTimeLimitWinner([])).toBe(-1);
  });

  it("packAuthoritySnap 은 시뮬 자기장 상태와 matchTime 을 실어 보낸다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    for (const h of sim.heroes.values()) {
      h.x = ARENA_CENTER.x;
      h.y = ARENA_CENTER.y;
    }
    const ticks = Math.ceil(42 / DT) + 3;
    for (let i = 0; i < ticks; i++) {sim.step(DT);}
    const snap = packAuthoritySnap(sim, new Map(), "full");
    expect(snap.zoneR).toBe(SAFE_ZONE_PHASES[0].radius);
    expect(snap.zonePhase).toBe(1);
    expect(snap.shrinking).toBe(false);
    expect(snap.zoneCX).toBe(ARENA_CENTER.x);
    expect(snap.zoneCY).toBe(ARENA_CENTER.y);
    expect(snap.time).toBe(sim.matchTime);
    expect(sim.matchTime).toBeGreaterThan(42);
  });
});
