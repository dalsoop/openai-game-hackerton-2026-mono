import { describe, expect, it } from "vitest";
import {
  DOWN_BLEED_TIME, DOWN_MOVE_MULT, MAX_REVIVES, RESPAWN_BASE, RESPAWN_MAX, RESPAWN_RANK_STEP,
  SPAWN_PROTECT_RESPAWN, SPAWN_PROTECT_STAND_UP, STAND_UP_HP_RATIO,
  applyHeroDamage, downHero, respawnDelayFor, tickDowns, updateRespawns,
} from "@/lib/hub/match-life";
import type { LifeHero } from "@/lib/hub/match-life";
import { ARENA_CENTER, buildTiledCovers } from "@/lib/hub/match-covers";
import { createSafeZone } from "@/lib/hub/match-zone";
import { MOVE_SPEED, MatchSim } from "@/lib/hub/match-sim";
import { packAuthoritySnap } from "@/lib/hub/match-authority";

/** 다운·부활·리스폰·스폰 보호 — 사양(downs-revives.md) 수치 그대로의 회귀. */

function hero(slot: number, over: Partial<LifeHero> = {}): LifeHero {
  return {
    slot, x: ARENA_CENTER.x, y: ARENA_CENTER.y, hp: 176, maxHp: 176, alive: true,
    mag: 18, magMax: 18, reloadLeft: 0, fireCd: 0, kills: 0, deaths: 0,
    downed: false, downLeft: 0, downTaken: 0, revivesUsed: 0, eliminated: false,
    respawnLeft: 0, spawnProtect: 0, spawnX: ARENA_CENTER.x, spawnY: ARENA_CENTER.y,
    ...over,
  };
}

describe("다운·확인사살", () => {
  it("HP 0 은 즉사가 아니라 다운 — 출혈 5초 시작, 킬 크레딧 없음", () => {
    const shooter = hero(0);
    const target = hero(1, { hp: 10 });
    const map = new Map([[0, shooter], [1, target]]);
    expect(applyHeroDamage(map, 0, target, 13.26)).toBe("down");
    expect(target.downed).toBe(true);
    expect(target.alive).toBe(true);
    expect(target.hp).toBe(0);
    expect(target.downLeft).toBe(DOWN_BLEED_TIME);
    expect(shooter.kills).toBe(0);
  });

  it("다운 중 누적 48 이상이면 확정 킬 — 이 시점에 킬 크레딧 적립", () => {
    const shooter = hero(0);
    const target = hero(1, { hp: 10 });
    const map = new Map([[0, shooter], [1, target]]);
    applyHeroDamage(map, 0, target, 13.26);
    for (let i = 0; i < 3; i++) {
      expect(applyHeroDamage(map, 0, target, 13.26)).toBe("none");
    }
    // 4번째 누적 — 13.26*4 = 53.04 >= 48
    expect(applyHeroDamage(map, 0, target, 13.26)).toBe("dead");
    expect(target.alive).toBe(false);
    expect(target.downed).toBe(false);
    expect(target.deaths).toBe(1);
    expect(target.revivesUsed).toBe(1);
    expect(target.respawnLeft).toBe(RESPAWN_BASE);
    expect(shooter.kills).toBe(1);
  });

  it("출혈 소진 — 세이프존 밖이면 사망(크레딧 없음)", () => {
    const zone = createSafeZone();
    const h = hero(0, {
      x: ARENA_CENTER.x + zone.radius + 200, downed: true, downLeft: 0.01, hp: 0,
    });
    tickDowns(new Map([[0, h]]), zone, 1 / 60);
    expect(h.alive).toBe(false);
    expect(h.downed).toBe(false);
    expect(h.deaths).toBe(1);
    expect(h.revivesUsed).toBe(1);
  });

  it("출혈 소진 — 세이프존 안이면 50% HP 기상 + 1.2초 무적", () => {
    const zone = createSafeZone();
    const h = hero(0, { downed: true, downLeft: 0.01, hp: 0 });
    tickDowns(new Map([[0, h]]), zone, 1 / 60);
    expect(h.alive).toBe(true);
    expect(h.downed).toBe(false);
    expect(h.hp).toBe(176 * STAND_UP_HP_RATIO);
    expect(h.spawnProtect).toBe(SPAWN_PROTECT_STAND_UP);
    expect(h.deaths).toBe(0);
  });
});

describe("부활 소진·eliminated", () => {
  it("리바이브 3회 소진 뒤 네 번째 사망에서 영구 탈락", () => {
    const h = hero(0);
    const map = new Map([[0, h]]);
    for (let i = 0; i < MAX_REVIVES; i++) {
      downHero(map, -1, h);
      expect(h.eliminated).toBe(false);
      expect(h.revivesUsed).toBe(i + 1);
      h.alive = true; // 리스폰 대행
    }
    downHero(map, -1, h);
    expect(h.eliminated).toBe(true);
    expect(h.deaths).toBe(MAX_REVIVES + 1);
    expect(h.respawnLeft).toBe(0);
  });

  it("eliminated 는 리스폰 카운트다운을 타지 않는다", () => {
    const zone = createSafeZone();
    const h = hero(0, { alive: false, eliminated: true, respawnLeft: 0 });
    updateRespawns(new Map([[0, h]]), zone, buildTiledCovers(), 1);
    expect(h.alive).toBe(false);
  });
});

describe("리스폰 딜레이·실행·스폰 보호", () => {
  it("딜레이 공식 min(5.5, 3.0 + 0.5*from_last) — 1등 최장, 꼴등 3.0", () => {
    const heroes = new Map<number, LifeHero>();
    for (let s = 0; s < 8; s++) {heroes.set(s, hero(s, { kills: 7 - s }));}
    expect(respawnDelayFor(heroes, 0)).toBe(RESPAWN_MAX); // from_last=7 → 캡 5.5
    expect(respawnDelayFor(heroes, 7)).toBe(RESPAWN_BASE); // from_last=0 → 3.0
    expect(respawnDelayFor(heroes, 5)).toBeCloseTo(RESPAWN_BASE + 0.5 * 2, 10);
  });

  it("리스폰 순위는 실제 score 이지 kills*100 이 아니다", () => {
    const heroes = new Map<number, LifeHero>([
      [0, hero(0, { score: 10, kills: 0 })],
      [1, hero(1, { score: 0, kills: 99 })],
    ]);
    expect(respawnDelayFor(heroes, 0)).toBe(RESPAWN_BASE + RESPAWN_RANK_STEP);
    expect(respawnDelayFor(heroes, 1)).toBe(RESPAWN_BASE);
  });

  it("리스폰 실행 — 풀 HP·풀 탄창·3.0초 무적", () => {
    const zone = createSafeZone();
    const h = hero(0, { alive: false, respawnLeft: 0.01, hp: 0, mag: 0, downed: false });
    updateRespawns(new Map([[0, h]]), zone, buildTiledCovers(), 1 / 60);
    expect(h.alive).toBe(true);
    expect(h.hp).toBe(h.maxHp);
    expect(h.mag).toBe(h.magMax);
    expect(h.spawnProtect).toBe(SPAWN_PROTECT_RESPAWN);
    expect(Number.isFinite(h.x) && Number.isFinite(h.y)).toBe(true);
  });

  it("스폰 보호 중에는 어떤 플레이어 피해도 무시된다", () => {
    const shooter = hero(0);
    const guarded = hero(1, { spawnProtect: 1 });
    const map = new Map([[0, shooter], [1, guarded]]);
    expect(applyHeroDamage(map, 0, guarded, 999)).toBe("none");
    expect(guarded.hp).toBe(guarded.maxHp);
    expect(guarded.downed).toBe(false);
  });
});

describe("MatchSim 통합", () => {
  it("탄 피해 경로 — 다운(연출 유지)→확인사살→리스폰, 스냅에 downed·downLeft·deaths", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const a = sim.heroes.get(0);
    const b = sim.heroes.get(1);
    expect(a && b).toBeTruthy();
    if (!a || !b) {return;}
    b.x = a.x + 90;
    b.y = a.y;
    b.hp = 10;
    sim.pushInput(0, { fire: true, aimX: b.x, aimY: b.y, seq: 1 });
    sim.step(1 / 60);
    expect(b.downed).toBe(true);
    expect(b.alive).toBe(true);
    expect(a.kills).toBe(0);
    expect(sim.knockouts.length).toBe(1); // 다운 전이 시 기존 knockout 연출 유지
    let steps = 0;
    while (b.alive && steps < 300) {
      steps += 1;
      sim.pushInput(0, { fire: true, aimX: b.x, aimY: b.y, seq: steps + 1 });
      sim.step(1 / 60);
    }
    expect(b.alive).toBe(false);
    expect(a.kills).toBe(1);
    expect(b.deaths).toBe(1);
    expect(b.revivesUsed).toBe(1);
    for (let i = 0; i < Math.ceil(RESPAWN_BASE * 60) + 2; i++) {sim.step(1 / 60);}
    expect(b.alive).toBe(true);
    expect(b.hp).toBe(b.maxHp);
    expect(b.spawnProtect).toBeGreaterThan(0);
    const before = b.hp;
    expect(applyHeroDamage(sim.heroes, 0, b, 50)).toBe("none");
    expect(b.hp).toBe(before);
    const snap = packAuthoritySnap(sim, new Map(), "battle");
    const players = snap.players as Array<{
      slot: number; downed: boolean; downLeft: number; deaths: number;
    }>;
    const row = players.find((p) => p.slot === 1);
    expect(row?.downed).toBe(false);
    expect(row?.deaths).toBe(1);
    expect(typeof row?.downLeft).toBe("number");
  });

  it("다운 중 이동은 정상 속도의 16% 로 기어간다", () => {
    const sim = new MatchSim([{ slot: 0 }, { slot: 1 }]);
    sim.countdown = 0;
    const b = sim.heroes.get(1);
    expect(b).toBeDefined();
    if (!b) {return;}
    b.hp = 5;
    applyHeroDamage(sim.heroes, 0, b, 10);
    expect(b.downed).toBe(true);
    const x0 = b.x;
    sim.pushInput(1, { mx: 1, my: 0, seq: 1 });
    sim.step(1 / 60);
    expect(b.x - x0).toBeCloseTo((MOVE_SPEED * DOWN_MOVE_MULT) / 60, 5);
  });
});
