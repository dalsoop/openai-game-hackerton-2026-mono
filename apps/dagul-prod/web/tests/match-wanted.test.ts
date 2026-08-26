import { describe, expect, it } from "vitest";
import {
  BOUNTY_DECAY_PER_SEC, KILL_BOUNTY_GAIN, ROULETTE_B_CHANCE_ASSIST,
  ROULETTE_B_CHANCE_KILL, ROULETTE_B_CHANCE_WANTED, ROULETTE_BONUS_TIME,
  ROULETTE_LAND_TIME, ROULETTE_SPIN_TIME, ROULETTE_TURTLE_CHANCE, SHUTDOWN_BOUNTY_DROP,
  WANTED_ANNOUNCE_TICKS,
  absorbRouletteShield, apply, applyRouletteFace, applyShutdownBountyDrop, awardKillBounty,
  beginNextRoulette, clearRouletteBuffs, createWantedState, grantKillRoulettes,
  isBountyVictim, killRouletteRank, pack, packRouletteSnap, packWantedSnap,
  pickRouletteFace, queueRoulette, rouletteBChance, rouletteFaceDesc, rouletteFaceList, rouletteFaces,
  rouletteSeedFields, rouletteStat, seed, standingLeader, tick, tickRoulette,
  updateThreat, wantedSeedFields,
  type RouletteHero, type RouletteRng, type WantedHero,
} from "@/lib/hub/match-wanted";

const DT = 1 / 60;

function wantedHero(slot: number, over: Partial<WantedHero> = {}): WantedHero {
  return { slot, score: 0, kills: 0, eliminated: false, ...wantedSeedFields(), ...over };
}

function rouletteHero(slot: number, over: Partial<RouletteHero> = {}): RouletteHero {
  return {
    slot, alive: true, hp: 176, maxHp: 176, baseMaxHp: 176, ...rouletteSeedFields(), ...over,
  };
}

function seqRng(values: number[]): RouletteRng {
  let i = 0;
  const next = (): number => {
    const v = values[Math.min(i, values.length - 1)];
    i += 1;
    return v;
  };
  return {
    rangef: (min: number, max: number): number => min + (max - min) * next(),
    rangei: (min: number, max: number): number => min + Math.min(max - min, Math.floor(next() * (max - min + 1))),
  };
}

describe("WANTED 리더·감쇠", () => {
  it("seed/tick/apply/pack 별칭", () => {
    expect(seed()).toEqual({ wantedSlot: -1 });
    expect(pack(createWantedState())).toEqual({ wantedSlot: -1 });
    const a = { bounty: 0 };
    apply(a);
    expect(a.bounty).toBe(KILL_BOUNTY_GAIN);
    expect(tick).toBe(updateThreat);
  });

  it("standingLeader — score >0.01, 동점 kills, 동점 slot", () => {
    expect(standingLeader([wantedHero(0, { score: 10 }), wantedHero(1, { score: 20.02 })])).toBe(1);
    expect(standingLeader([
      wantedHero(2, { score: 100, kills: 1 }),
      wantedHero(0, { score: 100.005, kills: 2 }),
      wantedHero(1, { score: 100, kills: 3 }),
    ])).toBe(1);
    expect(standingLeader([wantedHero(2, { score: 50, kills: 4 }), wantedHero(1, { score: 50, kills: 4 })])).toBe(1);
    expect(standingLeader([wantedHero(0, { eliminated: true, score: 999 })])).toBe(-1);
  });

  it("updateThreat — 감쇠 0.22/2.3/0.05, WANTED P{n} 90틱", () => {
    const state = createWantedState();
    const heroes = [wantedHero(0, { score: 10, bounty: 1, threat: 10, grudge: 1 })];
    const ev = updateThreat(state, heroes, 1);
    expect(heroes[0].bounty).toBeCloseTo(1 - BOUNTY_DECAY_PER_SEC, 9);
    expect(heroes[0].threat).toBeCloseTo(7.7, 9);
    expect(heroes[0].grudge).toBeCloseTo(0.95, 9);
    expect(ev).toEqual({
      kind: "bountyMoved", slot: 0, score: 10, announce: "WANTED P1", announceTicks: 90,
    });
    expect(WANTED_ANNOUNCE_TICKS).toBe(90);
    expect(updateThreat(state, heroes, DT)).toBeNull();
  });

  it("킬 바운티 +12, 셧다운 -20 하한 0, WANTED 랭크", () => {
    const a = { bounty: 5 };
    awardKillBounty(a);
    expect(a.bounty).toBe(5 + KILL_BOUNTY_GAIN);
    applyShutdownBountyDrop(a);
    expect(a.bounty).toBe(Math.max(0, 5 + KILL_BOUNTY_GAIN - SHUTDOWN_BOUNTY_DROP));
    const low = { bounty: 3 };
    applyShutdownBountyDrop(low);
    expect(low.bounty).toBe(0);
    const st = createWantedState();
    st.wantedSlot = 2;
    expect(isBountyVictim(st, 2)).toBe(true);
    expect(killRouletteRank(true)).toBe("wanted");
    expect(killRouletteRank(false)).toBe("kill");
    expect(packWantedSnap(st)).toEqual({ wantedSlot: 2 });
  });
});

describe("룰렛 면 테이블", () => {
  it("rouletteFaceDesc 는 원본 한국어 설명", () => {
    expect(rouletteFaceDesc({ id: "atk", name: "ATK +3" })).toBe("이번 목숨 동안 공격력이 올라갑니다");
    expect(rouletteFaceDesc({ id: "turtle", name: "TURTLE" })).toBe("2초 동안 공격과 대시를 쓸 수 없습니다");
    expect(rouletteFaceDesc({ id: "unknown", name: "X" })).toBe("X");
  });

  it("B 확률 0.25/0.55/0.40, turtle 0.03", () => {
    expect(rouletteBChance("assist")).toBe(ROULETTE_B_CHANCE_ASSIST);
    expect(rouletteBChance("wanted")).toBe(ROULETTE_B_CHANCE_WANTED);
    expect(rouletteBChance("kill")).toBe(ROULETTE_B_CHANCE_KILL);
    expect(ROULETTE_TURTLE_CHANCE).toBe(0.03);
    expect(ROULETTE_B_CHANCE_ASSIST).toBe(0.25);
    expect(ROULETTE_B_CHANCE_WANTED).toBe(0.55);
    expect(ROULETTE_B_CHANCE_KILL).toBe(0.40);
  });

  it("kill until 3/4/0.06/14/0.07/0.08", () => {
    const faces = rouletteFaces("kill", false);
    expect(faces.map((f) => [f.id, f.atk, f.spd, f.def, f.hp, f.rate, f.range])).toEqual([
      ["atk", 3, 0, 0, 0, 0, 0],
      ["spd", 0, 4, 0, 0, 0, 0],
      ["def", 0, 0, 0.06, 0, 0, 0],
      ["hp", 0, 0, 0, 14, 0, 0],
      ["rate", 0, 0, 0, 0, 0.07, 0],
      ["range", 0, 0, 0, 0, 0, 0.08],
    ]);
  });

  it("wanted timed giant 4.5/7.5/4.5/12, ATK 라벨 +5 값 4.5", () => {
    const timed = rouletteFaces("wanted", true);
    expect(timed[0]).toMatchObject({ id: "giant", atk: 4.5, spd: 7.5, hp: 4.5, dur: 12 });
    expect(timed[1]).toMatchObject({ shield: 60, dur: 3 });
    expect(timed[4]).toMatchObject({ id: "double_giant", atk: 6, spd: 10, hp: 6, dur: 12 });
    const atk = rouletteFaces("wanted", false)[0];
    expect(atk.name).toBe("ATK +5");
    expect(atk.atk).toBe(4.5);
  });

  it("assist timed 2/3/2/8, shield 24/2", () => {
    const faces = rouletteFaces("assist", true);
    expect(faces[0]).toMatchObject({ atk: 2, spd: 3, hp: 2, dur: 8 });
    expect(faces[1]).toMatchObject({ shield: 24, dur: 2 });
  });

  it("turtle rangef<0.03, 아니면 until atk", () => {
    expect(pickRouletteFace("kill", seqRng([0.02])).id).toBe("turtle");
    expect(pickRouletteFace("kill", seqRng([0.02])).dur).toBe(2);
    const until = pickRouletteFace("kill", seqRng([0.5, 0.9, 0]));
    expect(until.id).toBe("atk");
    expect(until.atk).toBe(3);
    expect(rouletteFaceList("kill")).toHaveLength(11);
  });
});

describe("룰렛 적용·틱", () => {
  it("until HP +14, timed giant 만료 시 baseMaxHp", () => {
    const h = rouletteHero(0, { hp: 170 });
    applyRouletteFace(h, rouletteFaces("kill", false)[3]);
    expect(h.maxHp).toBe(190);
    expect(h.hp).toBe(184);
    const g = rouletteHero(1);
    applyRouletteFace(g, rouletteFaces("kill", true)[0]);
    expect(rouletteStat(g, "atk")).toBe(3);
    g.rlTimed[0].time = DT;
    tickRoulette(g, DT);
    expect(g.rlTimed).toHaveLength(0);
    expect(g.maxHp).toBe(176);
  });

  it("queue bonus 0.25 → spin 0.9 → land 2.40", () => {
    const h = rouletteHero(0);
    queueRoulette(h, "kill", seqRng([0.5, 0.9, 0]));
    expect(h.roulettePhase).toBe("bonus");
    expect(h.rouletteTime).toBe(ROULETTE_BONUS_TIME);
    tickRoulette(h, ROULETTE_BONUS_TIME);
    expect(h.roulettePhase).toBe("spin");
    expect(h.rouletteTime).toBe(ROULETTE_SPIN_TIME);
    tickRoulette(h, ROULETTE_SPIN_TIME);
    expect(h.roulettePhase).toBe("land");
    expect(h.rouletteTime).toBe(ROULETTE_LAND_TIME);
    expect(h.rlUntil.atk).toBe(3);
    expect(h.rouletteDesc).toBe("이번 목숨 동안 공격력이 올라갑니다");
    tickRoulette(h, ROULETTE_LAND_TIME);
    expect(h.roulettePhase).toBe("");
  });

  it("grantKillRoulettes wanted + assist", () => {
    const killer = rouletteHero(0);
    const assist = rouletteHero(2);
    const dead = rouletteHero(1, { alive: false });
    grantKillRoulettes(
      new Map([[0, killer], [1, dead], [2, assist]]),
      0, 1, true, [2], seqRng([0.5, 0.9, 0, 0.5, 0.9, 0]),
    );
    expect(killer.rouletteRank).toBe("wanted");
    expect(assist.rouletteRank).toBe("assist");
  });

  it("shield 흡수, clear, pack", () => {
    const h = rouletteHero(0);
    applyRouletteFace(h, rouletteFaces("assist", true)[1]);
    expect(absorbRouletteShield(h, 10)).toBe(0);
    expect(h.rlTimed[0].shield).toBe(14);
    expect(absorbRouletteShield(h, 20)).toBe(6);
    applyRouletteFace(h, rouletteFaces("kill", false)[3]);
    clearRouletteBuffs(h);
    expect(h.maxHp).toBe(176);
    expect(h.rouletteQueue).toHaveLength(0);
    h.roulettePhase = "land";
    h.rouletteTime = 2.4;
    h.rouletteLabel = "ATK +3";
    h.rouletteRank = "kill";
    h.rouletteSpinId = "atk";
    expect(packRouletteSnap(h)).toMatchObject({
      roulette_phase: "land", roulette_time: 2.4, roulette_label: "ATK +3",
      roulette_rank: "kill", roulette_spin_id: "atk",
    });
    beginNextRoulette(h);
    expect(h.roulettePhase).toBe("");
  });
});
