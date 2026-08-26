import { describe, expect, it } from "vitest";
import { buildTiledCovers, pointInCover, ARENA_CENTER } from "@/lib/hub/match-covers";
import {
  CORE_MAX_HP,
  CORE_PLAYER_COUNT,
  CORE_RADIUS,
  ELIMINATE_SCORE,
  PROJECTILE_CORE_DAMAGE_MULT,
  ZONE_CORE_DAMAGE_MULT,
  coreExposed,
  coreSpawnPoint,
  damageCore,
  eliminatePlayer,
  packCoresSnap,
  projectileHitsCore,
  spawnCores,
  streakDamageMultiplier,
  zoneCoversCore,
  type CoreAttackerState,
  type CoreOwnerState,
  type SimCore,
} from "@/lib/hub/match-core";

const COVERS = buildTiledCovers();

function mkOwner(over: Partial<CoreOwnerState> = {}): CoreOwnerState {
  return { alive: true, ccTime: 0, rootTime: 0, stunTime: 0, ...over };
}

function mkAttacker(over: Partial<CoreAttackerState> = {}): CoreAttackerState {
  return { killStreak: 0, threat: 0, coreDamage: 0, score: 0, ...over };
}

function mkCore(over: Partial<SimCore> = {}): SimCore {
  return { slot: 0, x: 3920, y: 260, hp: CORE_MAX_HP, maxHp: CORE_MAX_HP, alive: true, ...over };
}

describe("match-core 스폰", () => {
  it("슬롯 8개 방사형 좌표가 원본 공식(-PI/2 + TAU*slot/8, 3600/2120 링)과 같다", () => {
    const cores = spawnCores(COVERS);
    expect(cores).toHaveLength(CORE_PLAYER_COUNT);
    // 원본 좌표: 중심(3920,2380) + dir * (3600,2120), 커버 간섭 없음(검증 완료)
    expect(cores[0].x).toBeCloseTo(3920, 6);
    expect(cores[0].y).toBeCloseTo(260, 6);
    expect(cores[1].x).toBeCloseTo(3920 + Math.cos(-Math.PI / 4) * 3600, 6);
    expect(cores[1].y).toBeCloseTo(2380 + Math.sin(-Math.PI / 4) * 2120, 6);
    expect(cores[2].x).toBeCloseTo(7520, 6);
    expect(cores[2].y).toBeCloseTo(2380, 6);
    expect(cores[4].x).toBeCloseTo(3920, 6);
    expect(cores[4].y).toBeCloseTo(4500, 6);
    expect(cores[6].x).toBeCloseTo(320, 6);
    expect(cores[6].y).toBeCloseTo(2380, 6);
    for (const c of cores) {
      expect(c.hp).toBe(CORE_MAX_HP);
      expect(c.maxHp).toBe(CORE_MAX_HP);
      expect(c.alive).toBe(true);
      expect(pointInCover(c.x, c.y, COVERS, CORE_RADIUS)).toBe(false);
    }
  });

  it("커버 위에 떨어지면 아레나 중심 방향으로 nudge 된다", () => {
    // 슬롯 0 스폰 지점(3920,260)을 덮는 합성 커버
    const cover = [{ x: 3920 - 100, y: 260 - 100, w: 200, h: 200 }];
    const p = coreSpawnPoint(0, CORE_PLAYER_COUNT, cover);
    expect(pointInCover(p.x, p.y, cover, CORE_RADIUS)).toBe(false);
    // 중심 방향(아래쪽)으로 밀렸다
    expect(p.y).toBeGreaterThan(260);
    const before = Math.hypot(3920 - ARENA_CENTER.x, 260 - ARENA_CENTER.y);
    expect(Math.hypot(p.x - ARENA_CENTER.x, p.y - ARENA_CENTER.y)).toBeLessThan(before);
  });
});

describe("match-core 노출 조건 (_core_exposed)", () => {
  it("주인이 살아 있고 CC 아님 → 비노출(보호막)", () => {
    expect(coreExposed(mkCore(), mkOwner())).toBe(false);
  });

  it("주인 사망 또는 cc/root/stun 중 하나면 노출", () => {
    expect(coreExposed(mkCore(), mkOwner({ alive: false }))).toBe(true);
    expect(coreExposed(mkCore(), mkOwner({ ccTime: 0.1 }))).toBe(true);
    expect(coreExposed(mkCore(), mkOwner({ rootTime: 0.1 }))).toBe(true);
    expect(coreExposed(mkCore(), mkOwner({ stunTime: 0.1 }))).toBe(true);
  });

  it("죽은 코어·주인 없음(슬롯 범위 밖)은 항상 비노출", () => {
    expect(coreExposed(mkCore({ alive: false }), mkOwner({ alive: false }))).toBe(false);
    expect(coreExposed(mkCore(), undefined)).toBe(false);
  });
});

describe("match-core 피격 (damage_core)", () => {
  it("비노출이면 blocked — 데미지 0, HP 불변", () => {
    const core = mkCore();
    const atk = mkAttacker();
    const r = damageCore(core, mkOwner(), atk, 100);
    expect(r.outcome).toBe("blocked");
    expect(r.damage).toBe(0);
    expect(r.chargeAward).toBe(0);
    expect(core.hp).toBe(CORE_MAX_HP);
    expect(atk.score).toBe(0);
  });

  it("노출 시 amount x streak x1.15, 충전 55%, threat x0.52, score x1.5", () => {
    const core = mkCore();
    const atk = mkAttacker();
    const r = damageCore(core, mkOwner({ stunTime: 0.5 }), atk, 100);
    expect(r.outcome).toBe("hit");
    expect(r.damage).toBeCloseTo(115, 9); // 100 * 1.0(streak) * 1.15
    expect(core.hp).toBeCloseTo(CORE_MAX_HP - 115, 9);
    expect(r.remaining).toBeCloseTo(95, 9);
    expect(r.chargeAward).toBeCloseTo(115 * 0.55, 9);
    expect(atk.threat).toBeCloseTo(115 * 0.52, 9);
    expect(atk.coreDamage).toBeCloseTo(115, 9);
    expect(atk.score).toBeCloseTo(115 * 1.5, 9);
  });

  it("스트릭 배율 1 + min(0.10, streak*0.025)", () => {
    expect(streakDamageMultiplier(0)).toBeCloseTo(1.0, 12);
    expect(streakDamageMultiplier(2)).toBeCloseTo(1.05, 12);
    expect(streakDamageMultiplier(4)).toBeCloseTo(1.10, 12);
    expect(streakDamageMultiplier(10)).toBeCloseTo(1.10, 12); // 상한 0.10
    const core = mkCore();
    const r = damageCore(core, mkOwner({ alive: false }), mkAttacker({ killStreak: 2 }), 100);
    expect(r.damage).toBeCloseTo(100 * 1.05 * 1.15, 9);
  });

  it("HP 0 이하 → destroyed(alive=false), 이후 피격은 dead", () => {
    const core = mkCore({ hp: 50 });
    const dead = mkOwner({ alive: false });
    const r = damageCore(core, dead, mkAttacker(), 100);
    expect(r.outcome).toBe("destroyed");
    expect(core.hp).toBe(0);
    expect(core.alive).toBe(false);
    expect(r.remaining).toBe(0);
    const r2 = damageCore(core, dead, mkAttacker(), 100);
    expect(r2.outcome).toBe("dead");
    expect(r2.damage).toBe(0);
  });
});

describe("match-core 히트 판정·배율", () => {
  it("투사체는 dist < r+34 (미만), 존은 dist <= r+34 (이하)", () => {
    const core = mkCore({ x: 1000, y: 1000 });
    const exact = 1000 + 10 + CORE_RADIUS; // 경계 거리
    expect(projectileHitsCore(exact, 1000, 10, core)).toBe(false);
    expect(projectileHitsCore(exact - 0.001, 1000, 10, core)).toBe(true);
    expect(zoneCoversCore(exact, 1000, 10, core)).toBe(true);
    expect(zoneCoversCore(exact + 0.001, 1000, 10, core)).toBe(false);
    const deadCore = mkCore({ x: 1000, y: 1000, alive: false });
    expect(projectileHitsCore(1000, 1000, 10, deadCore)).toBe(false);
    expect(zoneCoversCore(1000, 1000, 10, deadCore)).toBe(false);
  });

  it("코어행 데미지 배율 상수 — 투사체 0.78 · 존 0.72", () => {
    expect(PROJECTILE_CORE_DAMAGE_MULT).toBe(0.78);
    expect(ZONE_CORE_DAMAGE_MULT).toBe(0.72);
  });
});

describe("match-core 탈락 (eliminate)", () => {
  it("코어 파괴 + 히어로 즉시 탈락 + 공격자 score+300·bounty-15(하한 0)", () => {
    const core = mkCore();
    const target = { alive: true, eliminated: false };
    const attacker = { bounty: 10, eliminations: 0, score: 0 };
    eliminatePlayer(core, target, attacker);
    expect(core.alive).toBe(false);
    expect(core.hp).toBe(0);
    expect(target.alive).toBe(false);
    expect(target.eliminated).toBe(true);
    expect(attacker.bounty).toBe(0); // max(0, 10-15)
    expect(attacker.eliminations).toBe(1);
    expect(attacker.score).toBe(ELIMINATE_SCORE);
  });
});

describe("match-core 스냅 직렬화", () => {
  it("Godot parse_cores 필드명(slot·x·y·hp·max_hp·alive)으로 죽은 코어까지 싣는다", () => {
    const cores = [mkCore({ slot: 0, hp: 95.5 }), mkCore({ slot: 1, hp: 0, alive: false })];
    const snap = packCoresSnap(cores);
    expect(snap).toEqual([
      { slot: 0, x: 3920, y: 260, hp: 95.5, max_hp: CORE_MAX_HP, alive: true },
      { slot: 1, x: 3920, y: 260, hp: 0, max_hp: CORE_MAX_HP, alive: false },
    ]);
  });
});
