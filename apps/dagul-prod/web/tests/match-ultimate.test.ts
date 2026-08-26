/* eslint-disable max-lines -- 12지신 궁극기 + 차지 회귀 */
import { describe, expect, it } from "vitest";
import { ARENA_CENTER, HERO_RADIUS } from "@/lib/hub/match-covers";
import { MATCH_TIME_LIMIT } from "@/lib/hub/match-zone";
import {
  ANIMAL_COUNT,
  ANIMAL_DOG,
  ANIMAL_DRAGON,
  ANIMAL_HORSE,
  ANIMAL_MONKEY,
  ANIMAL_OX,
  ANIMAL_PIG,
  ANIMAL_RABBIT,
  ANIMAL_RAT,
  ANIMAL_ROOSTER,
  ANIMAL_SHEEP,
  ANIMAL_SNAKE,
  ANIMAL_TIGER,
  CRATE_ORB_ULT_RATIO,
  DRAGON_SMOKE_SPEED_MULT,
  FIGHT_SURGE_DELAY,
  FIGHT_SURGE_REMAINING,
  PIG_MUD_SPEED_MULT,
  SNAKE_SHED_GIANT,
  ULTIMATE_MAX,
  ULT_CHARGE_CRATE_ORB,
  ULT_CHARGE_KILL,
  ULT_CHARGE_PER_DAMAGE,
  ULT_CHARGE_PER_SEC,
  ULT_CHARGE_SHUTDOWN,
  ULT_CHARGE_TAKEN_RATIO,
  absorbWoolShield,
  addUltCharge,
  apply,
  applyCrateOrbUltCharge,
  applyFleeVel,
  applyHitUltCharge,
  applyKillUltCharge,
  applyShutdownUltCharge,
  applyUltimate,
  awardDealtCharge,
  awardTakenCharge,
  chargeFromDamage,
  deliverFightSurgeIfPending,
  grantFightSurge,
  heroHiddenInSmoke,
  heroInRatTide,
  heroMoveSpeed,
  hitSnakeSkin,
  hitUltClone,
  seed,
  seedUltWorld,
  tick,
  tickFightSurge,
  tickUltCharge,
  tickUltimates,
  ultHeroSeedFields,
  ultimateArmor,
  ultimateReady,
  type ChargeHero,
  type UltHero,
  type UltWorld,
} from "@/lib/hub/match-ultimate";

const DT = 1 / 60;

function makeHero(slot: number, over: Partial<UltHero> = {}): UltHero {
  return {
    slot,
    x: ARENA_CENTER.x + slot * 80,
    y: ARENA_CENTER.y,
    hp: 164,
    maxHp: 164,
    alive: true,
    ...ultHeroSeedFields(slot, over.animal ?? slot),
    ultimateCharge: ULTIMATE_MAX,
    ...over,
  };
}

function roster(...heroes: UltHero[]): Map<number, UltHero> {
  return new Map(heroes.map((h) => [h.slot, h]));
}

function usedId(w: UltWorld): string {
  return String(w.events.find((e) => e.type === "ultimate_used")?.data.id ?? "");
}

function chargeOf(over: Partial<ChargeHero> = {}): ChargeHero {
  return { alive: true, eliminated: false, ultimateCharge: 0, normalHits: 0, equipmentHits: 0, ...over };
}

describe("차지 공식 — game_world.gd:46-49", () => {
  it("MAX 100, PER_DAMAGE 0.144, TAKEN 0.6666667, PER_SEC 0.24, kill 35, shutdown 20, orb 34", () => {
    expect(ULTIMATE_MAX).toBe(100);
    expect(ULT_CHARGE_PER_DAMAGE).toBe(0.144);
    expect(ULT_CHARGE_TAKEN_RATIO).toBe(0.6666667);
    expect(ULT_CHARGE_PER_SEC).toBe(0.24);
    expect(ULT_CHARGE_KILL).toBe(35);
    expect(ULT_CHARGE_SHUTDOWN).toBe(20);
    expect(CRATE_ORB_ULT_RATIO).toBe(0.34);
    expect(ULT_CHARGE_CRATE_ORB).toBeCloseTo(34, 10);
  });

  it("charge_from_damage = max(0, amount)*0.144", () => {
    expect(chargeFromDamage(10)).toBeCloseTo(1.44, 10);
    expect(chargeFromDamage(-4)).toBe(0);
  });

  it("가한 피해 차지, ultimate/mobility 스킵, equipmentHits", () => {
    const h = chargeOf();
    awardDealtCharge(h, 10, "normal");
    expect(h.ultimateCharge).toBeCloseTo(1.44, 10);
    expect(h.normalHits).toBe(1);
    awardDealtCharge(h, 100, "ultimate");
    awardDealtCharge(h, 100, "mobility");
    expect(h.ultimateCharge).toBeCloseTo(1.44, 10);
    awardDealtCharge(h, 10, "equipment");
    expect(h.equipmentHits).toBe(1);
  });

  it("피격 차지 = damage*0.144*0.6666667", () => {
    const h = chargeOf();
    awardTakenCharge(h, 10);
    expect(h.ultimateCharge).toBeCloseTo(10 * 0.144 * 0.6666667, 10);
  });

  it("히트 쌍: 자해·0.01 이하 스킵", () => {
    const a = chargeOf();
    const v = chargeOf();
    applyHitUltCharge(a, v, 10, "normal", true);
    expect(a.ultimateCharge).toBe(0);
    applyHitUltCharge(a, v, 0.01, "normal", false);
    expect(a.ultimateCharge).toBe(0);
    applyHitUltCharge(a, v, 10, "normal", false);
    expect(a.ultimateCharge).toBeCloseTo(1.44, 10);
    expect(v.ultimateCharge).toBeCloseTo(10 * 0.144 * 0.6666667, 10);
  });

  it("초당 0.24, 상한 100, 사망/탈락 미충전", () => {
    const a = chargeOf();
    const dead = chargeOf({ alive: false, ultimateCharge: 10 });
    tickUltCharge([a, dead], DT);
    expect(a.ultimateCharge).toBeCloseTo(0.24 * DT, 10);
    expect(dead.ultimateCharge).toBe(10);
    const full = chargeOf({ ultimateCharge: 99.99 });
    tickUltCharge([full], 1);
    expect(full.ultimateCharge).toBe(100);
  });

  it("킬 +35, 셧다운 +20(스트릭>=3), 오브 +34", () => {
    const h = chargeOf({ ultimateCharge: 10 });
    applyKillUltCharge(h);
    expect(h.ultimateCharge).toBe(45);
    applyShutdownUltCharge(h, 2);
    expect(h.ultimateCharge).toBe(45);
    applyShutdownUltCharge(h, 3);
    expect(h.ultimateCharge).toBe(65);
    applyCrateOrbUltCharge(h);
    expect(h.ultimateCharge).toBe(99);
    applyCrateOrbUltCharge(h);
    expect(h.ultimateCharge).toBe(100);
  });

  it("add_ult_charge 는 0.0001 이하를 건너뛴다", () => {
    const h = chargeOf({ ultimateCharge: 1 });
    addUltCharge(h, 0.0001);
    expect(h.ultimateCharge).toBe(1);
  });

  it("발동 임계 MAX-0.5", () => {
    expect(ultimateReady(99.499)).toBe(false);
    expect(ultimateReady(99.5)).toBe(true);
    const h = makeHero(0, { animal: ANIMAL_TIGER, ultimateCharge: 99.5 });
    const w = seed();
    expect(applyUltimate(w, roster(h), 0, ARENA_CENTER)).toBe(true);
    expect(h.ultimateCharge).toBe(0);
    expect(h.ultimates).toBe(1);
    expect(usedId(w)).toBe("tiger_roar");
  });
});

describe("파이널 서지 — remaining 60s + 1.65s", () => {
  it("matchTime 150 카운트다운, 151.65 서지", () => {
    const standing = makeHero(0, { ultimateCharge: 12 });
    const downed = makeHero(1, { downed: true, ultimateCharge: 0 });
    const gone = makeHero(2, { eliminated: true, ultimateCharge: 0 });
    const heroes = roster(standing, downed, gone);
    const w = seedUltWorld();
    tickFightSurge(w, heroes, MATCH_TIME_LIMIT - FIGHT_SURGE_REMAINING);
    expect(w.fightCountdownEmitted).toBe(true);
    expect(w.fightSurgeAt).toBeCloseTo(150 + FIGHT_SURGE_DELAY, 10);
    expect(w.events[0].type).toBe("fight_countdown");
    expect(w.events[0].data.remaining).toBe(60);

    tickFightSurge(w, heroes, 151.64);
    expect(w.fightSurgeEmitted).toBe(false);
    tickFightSurge(w, heroes, 151.65);
    expect(w.fightSurgeEmitted).toBe(true);
    expect(standing.ultimateCharge).toBe(100);
    expect(downed.ultimateCharge).toBe(100);
    expect(downed.fightSurgePending).toBe(true);
    expect(gone.ultimateCharge).toBe(0);
    const surge = w.events.find((e) => e.type === "fight_surge");
    expect(surge?.data).toEqual({ standing: 1, pending: 1 });
  });

  it("pending 서지 기상 후 전달", () => {
    const h = makeHero(0, { downed: true, ultimateCharge: 0 });
    const w = seed();
    grantFightSurge(w, roster(h));
    expect(h.fightSurgePending).toBe(true);
    h.downed = false;
    deliverFightSurgeIfPending(w, h);
    expect(h.fightSurgePending).toBe(false);
    expect(h.ultimateCharge).toBe(100);
  });
});

describe("12지신 디스패치", () => {
  it("0..11 원본 id", () => {
    const ids = [
      "rat_tide", "ox_gore", "tiger_roar", "rabbit_burrow", "dragon_smoke", "snake_shed",
      "horse_kick", "wool_shield", "mirage", "rooster_egg", "dog_fetch", "pig_mud",
    ];
    expect(ANIMAL_COUNT).toBe(12);
    for (let animal = 0; animal < 12; animal += 1) {
      const h = makeHero(0, { animal, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
      const w = seed();
      apply(w, roster(h), 0, { x: ARENA_CENTER.x + 400, y: ARENA_CENTER.y });
      expect(usedId(w)).toBe(ids[animal]);
      if (animal === ANIMAL_MONKEY) {
        expect(h.ultClones).toHaveLength(7);
        expect(w.events[0].data.clones).toBe(7);
      }
    }
  });

  it("로컬만 포커스", () => {
    const me = makeHero(0, { animal: ANIMAL_TIGER });
    const foe = makeHero(1, { animal: ANIMAL_TIGER });
    const w = seed();
    w.localSlot = 0;
    applyUltimate(w, roster(me, foe), 1, ARENA_CENTER);
    expect(w.ultimateFocusSlot).toBe(-1);
    applyUltimate(w, roster(me, foe), 0, ARENA_CENTER);
    expect(w.ultimateFocusSlot).toBe(0);
    expect(w.ultimateFocusTime).toBeCloseTo(0.24, 10);
  });
});

describe("쥐 조류", () => {
  it("lead 70 / life 1.70 / travel 720 / half 118 / length 360, 박스 안 860", () => {
    const caster = makeHero(0, {
      animal: ANIMAL_RAT, x: ARENA_CENTER.x, y: ARENA_CENTER.y, facing: { x: 1, y: 0 },
    });
    const foe = makeHero(1, {
      x: ARENA_CENTER.x + 70, y: ARENA_CENTER.y, vel: { x: 0, y: 100 }, ultimateCharge: 0,
    });
    const w = seed();
    applyUltimate(w, roster(caster, foe), 0, { x: ARENA_CENTER.x + 100, y: ARENA_CENTER.y });
    const tide = w.ratTides[0];
    expect(tide.pos.x).toBeCloseTo(ARENA_CENTER.x + 70, 8);
    expect(tide.life).toBe(1.7);
    expect(tide.travel).toBe(720);
    expect(tide.halfW).toBe(118);
    expect(tide.length).toBe(360);
    expect(heroInRatTide({ x: tide.pos.x, y: tide.pos.y }, tide)).toBe(true);
    tick(w, roster(caster, foe), DT);
    expect(foe.vel.x).toBeCloseTo(860, 6);
    expect(foe.vel.y).toBeCloseTo(50, 6);
  });
});

describe("소 돌진", () => {
  it("back 0.18@380 후 rush 1100, 히트 62 스턴 1.35", () => {
    const ox = makeHero(0, { animal: ANIMAL_OX, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const foe = makeHero(1, { x: ARENA_CENTER.x + 40, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const heroes = roster(ox, foe);
    const w = seed();
    applyUltimate(w, heroes, 0, { x: ARENA_CENTER.x + 400, y: ARENA_CENTER.y });
    expect(ox.oxPhase).toBe("back");
    tickUltimates(w, heroes, DT);
    expect(ox.vel.x).toBeCloseTo(-380, 8);
    tickUltimates(w, heroes, 0.18);
    expect(ox.oxPhase).toBe("rush");
    tickUltimates(w, heroes, DT);
    expect(ox.vel.x).toBeCloseTo(1100, 8);
    expect(foe.stunTime).toBe(1.35);
  });
});

describe("호랑이 포효", () => {
  it("반경 300, flee 1.5, 속도 *1.12", () => {
    const t = makeHero(0, { animal: ANIMAL_TIGER, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const near = makeHero(1, { x: ARENA_CENTER.x + 200, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const far = makeHero(2, { x: ARENA_CENTER.x + 301, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const w = seed();
    applyUltimate(w, roster(t, near, far), 0, ARENA_CENTER);
    expect(near.fleeTime).toBe(1.5);
    expect(far.fleeTime).toBe(0);
    applyFleeVel(near, 419);
    expect(near.vel.x).toBeCloseTo(419 * 1.12, 6);
  });
});

describe("토끼 굴", () => {
  it("2초 잠수 후 출구·무적 0.25, 재잠수는 차지 환급", () => {
    const r = makeHero(0, { animal: ANIMAL_RABBIT, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const heroes = roster(r);
    const w = seed();
    const exit = { x: ARENA_CENTER.x + 500, y: ARENA_CENTER.y + 80 };
    applyUltimate(w, heroes, 0, exit);
    expect(r.burrowed).toBe(true);
    expect(r.burrowLeft).toBe(2);
    tickUltimates(w, heroes, 2);
    expect(r.burrowed).toBe(false);
    expect(r.x).toBeCloseTo(exit.x, 5);
    expect(r.spawnProtect).toBe(0.25);
    expect(w.events.some((e) => e.type === "rabbit_emerge")).toBe(true);
    r.ultimateCharge = ULTIMATE_MAX;
    r.burrowed = true;
    applyUltimate(w, heroes, 0, exit);
    expect(r.ultimateCharge).toBe(ULTIMATE_MAX);
  });
});

describe("용 연기", () => {
  it("반경 300 ttl 15, 로컬 용이 아니면 은신, 연기 속 1.30배", () => {
    const d = makeHero(0, { animal: ANIMAL_DRAGON, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const o = makeHero(1, { animal: ANIMAL_RAT, x: ARENA_CENTER.x, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const heroes = roster(d, o);
    const w = seed();
    w.localSlot = 1;
    applyUltimate(w, heroes, 0, ARENA_CENTER);
    expect(w.dragonSmokes[0].radius).toBe(300);
    expect(w.dragonSmokes[0].ttl).toBe(15);
    expect(heroHiddenInSmoke(w, heroes, 0)).toBe(true);
    w.localSlot = 0;
    expect(heroHiddenInSmoke(w, heroes, 0)).toBe(false);
    expect(heroMoveSpeed(w, heroes, 0)).toBeCloseTo(419 * DRAGON_SMOKE_SPEED_MULT, 10);
  });
});

describe("뱀 허물", () => {
  it("scale 1.5 ttl 18, 거인 atk3 spd5 hp3 dur12", () => {
    const s = makeHero(0, { animal: ANIMAL_SNAKE, hp: 164, maxHp: 164 });
    const w = seed();
    const heroes = roster(s);
    applyUltimate(w, heroes, 0, ARENA_CENTER);
    const skin = w.snakeSkins[0];
    expect(skin.scale).toBe(1.5);
    expect(skin.ttl).toBe(18);
    expect(skin.hp).toBe(164);
    expect(s.maxHp).toBe(167);
    expect(s.hp).toBe(167);
    expect(s.rlTimed[0]).toMatchObject({
      id: SNAKE_SHED_GIANT.id, atk: 3, spd: 5, hp: 3, time: 12,
    });
    expect(hitSnakeSkin(w, 1, { x: s.x, y: s.y }, 4, 20)).toBe(true);
    expect(skin.hp).toBe(144);
    expect(skin.flash).toBeCloseTo(0.11, 10);
  });
});

describe("말 뒷차기", () => {
  it("뒤쪽 부채 400 / 1.15rad, 스턴 1.15", () => {
    const h = makeHero(0, {
      animal: ANIMAL_HORSE, x: ARENA_CENTER.x, y: ARENA_CENTER.y, facing: { x: 1, y: 0 },
    });
    const behind = makeHero(1, { x: ARENA_CENTER.x - 120, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const ahead = makeHero(2, { x: ARENA_CENTER.x + 120, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const w = seed();
    applyUltimate(w, roster(h, behind, ahead), 0, { x: ARENA_CENTER.x + 200, y: ARENA_CENTER.y });
    expect(behind.stunTime).toBe(1.15);
    expect(ahead.stunTime).toBe(0);
    expect(w.horseKicks[0].life).toBeCloseTo(0.42, 10);
  });
});

describe("양 털방패", () => {
  it("5초 5HP, pad 58, 5히트 팝 스턴 0.55", () => {
    const s = makeHero(0, { animal: ANIMAL_SHEEP, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const foe = makeHero(1, { x: ARENA_CENTER.x + 40, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const heroes = roster(s, foe);
    const w = seed();
    applyUltimate(w, heroes, 0, ARENA_CENTER);
    expect(s.woolTime).toBe(5);
    expect(s.woolHp).toBe(5);
    expect(absorbWoolShield(w, heroes, 1, 0, { x: s.x, y: s.y }, 0)).toBe(true);
    expect(s.woolHp).toBe(4);
    expect(absorbWoolShield(w, heroes, 0, 0, { x: s.x, y: s.y }, 0)).toBe(false);
    expect(absorbWoolShield(w, heroes, 1, 0, { x: s.x + 59, y: s.y }, 0)).toBe(false);
    for (let i = 0; i < 4; i += 1) {
      absorbWoolShield(w, heroes, 1, 0, { x: s.x, y: s.y }, 0);
    }
    expect(s.woolHp).toBe(0);
    expect(foe.stunTime).toBe(0.55);
  });
});

describe("원숭이 분신", () => {
  it("7분신 8초, 탄 히트 팝", () => {
    const m = makeHero(0, { animal: ANIMAL_MONKEY, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const heroes = roster(m);
    const w = seed();
    applyUltimate(w, heroes, 0, ARENA_CENTER);
    expect(m.ultClones).toHaveLength(7);
    expect(m.ultCloneTime).toBe(8);
    expect(m.ultClones[0].ang).toBeCloseTo(Math.PI * 2 * 0.125, 10);
    expect(hitUltClone(w, heroes, 1, { x: m.x, y: m.y }, 1)).toBe(true);
    expect(m.ultClones).toHaveLength(6);
    tickUltimates(w, heroes, 8);
    expect(m.ultClones).toHaveLength(0);
  });
});

describe("닭 알", () => {
  it("arm 0.55 후 트리거 150+R, 폭발 170 스턴 1.20, 주인 면역", () => {
    const r = makeHero(0, { animal: ANIMAL_ROOSTER, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const foe = makeHero(1, { x: ARENA_CENTER.x + 80, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const heroes = roster(r, foe);
    const w = seed();
    applyUltimate(w, heroes, 0, ARENA_CENTER);
    expect(w.roosterEggs[0].arm).toBe(0.55);
    expect(w.roosterEggs[0].trigger).toBe(150);
    tickUltimates(w, heroes, 0.55 - DT);
    expect(w.roosterEggs).toHaveLength(1);
    tickUltimates(w, heroes, DT);
    expect(w.events.some((e) => e.type === "rooster_egg_boom")).toBe(true);
    expect(r.stunTime).toBe(0);
    expect(foe.stunTime).toBe(1.2);
    expect(HERO_RADIUS + 150).toBe(170);
  });
});

describe("개 뼈다귀", () => {
  it("윈드업 1.0 후 아머 2.2·속도 1020, 도착 36 정지", () => {
    const d = makeHero(0, { animal: ANIMAL_DOG, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const bone = { x: ARENA_CENTER.x + 400, y: ARENA_CENTER.y };
    const foe = makeHero(1, { x: ARENA_CENTER.x + 30, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const heroes = roster(d, foe);
    const w = seed();
    applyUltimate(w, heroes, 0, bone);
    expect(d.dogWindup).toBe(1);
    expect(w.dogBones[0].ttl).toBe(5);
    tickUltimates(w, heroes, 1 - DT);
    expect(d.dogRush).toBe(false);
    tickUltimates(w, heroes, DT);
    expect(d.dogRush).toBe(true);
    expect(d.superArmorTime).toBe(2.2);
    expect(d.vel.x).toBeCloseTo(1020, 6);
    expect(foe.stunTime).toBe(1.25);
    d.x = bone.x - 36;
    d.y = bone.y;
    tickUltimates(w, heroes, DT);
    expect(d.dogRush).toBe(false);
    expect(d.superArmorTime).toBe(0);
  });
});

describe("돼지 진흙", () => {
  it("반경 200 ttl 6, 적만 *0.48", () => {
    const p = makeHero(0, { animal: ANIMAL_PIG, x: ARENA_CENTER.x, y: ARENA_CENTER.y });
    const foe = makeHero(1, { x: ARENA_CENTER.x, y: ARENA_CENTER.y, ultimateCharge: 0 });
    const heroes = roster(p, foe);
    const w = seed();
    applyUltimate(w, heroes, 0, ARENA_CENTER);
    expect(w.pigMuds[0].radius).toBe(200);
    expect(w.pigMuds[0].ttl).toBe(6);
    expect(heroMoveSpeed(w, heroes, 0)).toBe(419);
    expect(heroMoveSpeed(w, heroes, 1)).toBeCloseTo(419 * PIG_MUD_SPEED_MULT, 10);
    tick(w, heroes, DT);
    expect(w.pigMuds[0].ttl).toBeCloseTo(6 - DT, 10);
  });
});

describe("아머·포커스", () => {
  it("ultimate_armor 는 duration 0", () => {
    expect(ultimateArmor("scatter")).toEqual({ duration: 0, strength: 0 });
  });

  it("포커스 만료 시 슬롯 -1", () => {
    const h = makeHero(0, { animal: ANIMAL_TIGER });
    const w = seed();
    w.localSlot = 0;
    const heroes = roster(h);
    applyUltimate(w, heroes, 0, ARENA_CENTER);
    tickUltimates(w, heroes, 0.24);
    expect(w.ultimateFocusSlot).toBe(-1);
  });
});
