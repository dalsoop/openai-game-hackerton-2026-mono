/**
 * WANTED + 킬 룰렛 — match_lifecycle.gd update_threat/_reward_attacker bounty
 * 와 roulette_buff.gd 결정론 포팅. 시계 없음. 면 선택은 RouletteRng.
 */
import {
  pickRouletteFace, rouletteBChance, rouletteFaceList, rouletteFaces,
} from "./match-wanted-faces.js";

export { pickRouletteFace, rouletteBChance, rouletteFaceList, rouletteFaces };

export const BOUNTY_DECAY_PER_SEC = 0.22;
export const THREAT_DECAY_PER_SEC = 2.3;
export const GRUDGE_DECAY_PER_SEC = 0.05;
export const KILL_BOUNTY_GAIN = 12;
export const SHUTDOWN_BOUNTY_DROP = 20;
export const SCORE_TIE_EPSILON = 0.01;
export const WANTED_ANNOUNCE_TICKS = 90;
export const ROULETTE_TURTLE_CHANCE = 0.03;
export const ROULETTE_BONUS_TIME = 0.25;
export const ROULETTE_SPIN_TIME = 0.9;
export const ROULETTE_LAND_TIME = 2.40;
export const ROULETTE_BONUS_ANNOUNCE_TICKS = 50;
export const ROULETTE_B_CHANCE_ASSIST = 0.25;
export const ROULETTE_B_CHANCE_WANTED = 0.55;
export const ROULETTE_B_CHANCE_KILL = 0.40;

export type RouletteRank = "assist" | "wanted" | "kill";
export type RouletteRng = { rangef(min: number, max: number): number; rangei(min: number, max: number): number };
export type RouletteFace = {
  id: string; name: string; kind: "timed" | "until";
  atk: number; spd: number; def: number; hp: number; rate: number; range: number; shield: number; dur: number;
};
export type RouletteUntil = { atk: number; spd: number; def: number; hp: number; rate: number; range: number };
export type RouletteTimedBuff = RouletteUntil & { id: string; name: string; time: number; shield: number };
export type RouletteQueueItem = { rank: string; face: RouletteFace };
export type RouletteHero = {
  slot: number; alive: boolean; hp: number; maxHp: number; baseMaxHp: number;
  rlUntil: RouletteUntil; rlTimed: RouletteTimedBuff[];
  rouletteTime: number; rouletteLabel: string; rouletteRank: string; roulettePhase: string;
  roulettePending: RouletteFace | Record<string, never>;
  rouletteQueue: RouletteQueueItem[];
  rouletteFaces: Array<{ id: string; name: string }>;
  rouletteSpinId: string; rouletteSpinDur: number; rouletteDesc: string;
};
export type WantedHero = {
  slot: number; score: number; kills: number; bounty: number; threat: number; grudge: number; eliminated: boolean;
};
export type WantedState = { wantedSlot: number };
export type WantedEvent = {
  kind: "bountyMoved"; slot: number; score: number; announce: string; announceTicks: number;
};

function emptyUntil(): RouletteUntil {
  return { atk: 0, spd: 0, def: 0, hp: 0, rate: 0, range: 0 };
}

export function createWantedState(): WantedState { return { wantedSlot: -1 }; }
export function wantedSeedFields(): Pick<WantedHero, "bounty" | "threat" | "grudge"> {
  return { bounty: 0, threat: 0, grudge: 0 };
}
export function rouletteSeedFields(): Omit<RouletteHero, "slot" | "alive" | "hp" | "maxHp" | "baseMaxHp"> {
  return {
    rlUntil: emptyUntil(), rlTimed: [], rouletteTime: 0, rouletteLabel: "", rouletteRank: "",
    roulettePhase: "", roulettePending: {}, rouletteQueue: [], rouletteFaces: [],
    rouletteSpinId: "", rouletteSpinDur: 0, rouletteDesc: "",
  };
}

function sortedBySlot<T extends { slot: number }>(heroes: Iterable<T>): T[] {
  return [...heroes].sort((a, b) => a.slot - b.slot);
}

function beatsLeader(hero: WantedHero, best: WantedHero | null): boolean {
  if (best === null) {return true;}
  if (hero.score > best.score + SCORE_TIE_EPSILON) {return true;}
  if (Math.abs(hero.score - best.score) > SCORE_TIE_EPSILON) {return false;}
  if (hero.kills !== best.kills) {return hero.kills > best.kills;}
  return hero.slot < best.slot;
}

export function standingLeader(heroes: Iterable<WantedHero>): number {
  let best: WantedHero | null = null;
  for (const hero of sortedBySlot(heroes)) {
    if (hero.eliminated) {continue;}
    if (beatsLeader(hero, best)) {best = hero;}
  }
  return best === null ? -1 : best.slot;
}

export function updateThreat(state: WantedState, heroes: Iterable<WantedHero>, dt: number): WantedEvent | null {
  const list = sortedBySlot(heroes);
  for (const hero of list) {
    hero.threat = Math.max(0, hero.threat - dt * THREAT_DECAY_PER_SEC);
    hero.bounty = Math.max(0, hero.bounty - dt * BOUNTY_DECAY_PER_SEC);
    hero.grudge = Math.max(0, hero.grudge - dt * GRUDGE_DECAY_PER_SEC);
  }
  const newWanted = standingLeader(list);
  if (newWanted === state.wantedSlot || newWanted < 0) {return null;}
  state.wantedSlot = newWanted;
  const leader = list.find((h) => h.slot === newWanted);
  return {
    kind: "bountyMoved", slot: newWanted, score: leader ? leader.score : 0,
    announce: `WANTED P${newWanted + 1}`, announceTicks: WANTED_ANNOUNCE_TICKS,
  };
}

export function isBountyVictim(state: WantedState, targetSlot: number): boolean {
  return targetSlot >= 0 && targetSlot === state.wantedSlot;
}
export function killRouletteRank(bountyVictim: boolean): "wanted" | "kill" {
  return bountyVictim ? "wanted" : "kill";
}
export function awardKillBounty(attacker: { bounty: number }): void { attacker.bounty += KILL_BOUNTY_GAIN; }
export function applyShutdownBountyDrop(attacker: { bounty: number }): void {
  attacker.bounty = Math.max(0, attacker.bounty - SHUTDOWN_BOUNTY_DROP);
}
export function packWantedSnap(state: WantedState): { wantedSlot: number } {
  return { wantedSlot: state.wantedSlot };
}





export function rouletteStat(hero: RouletteHero, key: keyof RouletteUntil): number {
  let total = hero.rlUntil[key];
  for (const buff of hero.rlTimed) {total += buff[key];}
  return total;
}

export function clearRouletteBuffs(hero: RouletteHero): void {
  hero.maxHp = hero.baseMaxHp;
  if (hero.hp > hero.baseMaxHp) {hero.hp = hero.baseMaxHp;}
  hero.rlUntil = emptyUntil();
  hero.rlTimed = [];
  hero.rouletteTime = 0;
  hero.rouletteLabel = "";
  hero.rouletteRank = "";
  hero.roulettePhase = "";
  hero.roulettePending = {};
  hero.rouletteQueue = [];
  hero.rouletteFaces = [];
}

function addHp(hero: RouletteHero, hpAdd: number): void {
  if (hpAdd <= 0) {return;}
  hero.maxHp += hpAdd;
  hero.hp = Math.min(hero.maxHp, hero.hp + hpAdd);
}

function pendingFace(face: RouletteFace | Record<string, never>): RouletteFace | null {
  const rec = face as Partial<RouletteFace>;
  if (rec.kind !== "timed" && rec.kind !== "until") {return null;}
  return face as RouletteFace;
}

export function applyRouletteFace(hero: RouletteHero, face: RouletteFace | Record<string, never>): void {
  if (!hero.alive) {return;}
  const pending = pendingFace(face);
  if (!pending) {return;}
  const hpAdd = pending.hp;
  if (pending.kind === "until") {
    hero.rlUntil.atk += pending.atk;
    hero.rlUntil.spd += pending.spd;
    hero.rlUntil.def += pending.def;
    hero.rlUntil.hp += hpAdd;
    hero.rlUntil.rate += pending.rate;
    hero.rlUntil.range += pending.range;
    addHp(hero, hpAdd);
    return;
  }
  hero.rlTimed.push({
    id: pending.id, name: pending.name, time: pending.dur,
    atk: pending.atk, spd: pending.spd, def: pending.def, hp: hpAdd,
    rate: pending.rate, range: pending.range, shield: pending.shield,
  });
  addHp(hero, hpAdd);
}

function expireTimedBuff(hero: RouletteHero, buff: RouletteTimedBuff): void {
  if (buff.hp <= 0) {return;}
  hero.maxHp = Math.max(hero.baseMaxHp, hero.maxHp - buff.hp);
  hero.hp = Math.min(hero.hp, hero.maxHp);
}

export function beginNextRoulette(hero: RouletteHero): void {
  if (hero.rouletteQueue.length === 0 || !hero.alive) {
    hero.roulettePhase = "";
    hero.rouletteTime = 0;
    hero.roulettePending = {};
    return;
  }
  const item = hero.rouletteQueue.shift();
  if (item === undefined) {
    hero.roulettePhase = "";
    hero.rouletteTime = 0;
    hero.roulettePending = {};
    return;
  }
  const rank = String(item.rank);
  hero.roulettePending = item.face;
  hero.rouletteRank = rank;
  hero.roulettePhase = "bonus";
  hero.rouletteTime = ROULETTE_BONUS_TIME;
  hero.rouletteLabel = "KILL BONUS!";
  hero.rouletteFaces = rouletteFaceList(rank);
  hero.rouletteSpinId = "";
}

export function queueRoulette(hero: RouletteHero, rank: string, rng: RouletteRng): void {
  if (!hero.alive) {return;}
  hero.rouletteQueue.push({ rank, face: pickRouletteFace(rank, rng) });
  if (hero.roulettePhase === "") {beginNextRoulette(hero);}
}

export function grantKillRoulettes(
  heroes: ReadonlyMap<number, RouletteHero>,
  owner: number, target: number, bountyKill: boolean, assistSlots: readonly number[], rng: RouletteRng,
): void {
  const killer = heroes.get(owner);
  if (killer && owner !== target && killer.alive) {
    queueRoulette(killer, bountyKill ? "wanted" : "kill", rng);
  }
  for (const slot of assistSlots) {
    const assist = heroes.get(slot);
    if (assist) {queueRoulette(assist, "assist", rng);}
  }
}

function tickTimedBuffs(hero: RouletteHero, dt: number): void {
  const kept: RouletteTimedBuff[] = [];
  for (const buff of hero.rlTimed) {
    const left = Math.max(0, buff.time - dt);
    if (left <= 0) {expireTimedBuff(hero, buff); continue;}
    buff.time = left;
    kept.push(buff);
  }
  hero.rlTimed = kept;
}

function tickBonusPhase(hero: RouletteHero): void {
  hero.rouletteLabel = "KILL BONUS!";
  if (hero.rouletteTime > 0) {return;}
  hero.roulettePhase = "spin";
  hero.rouletteTime = ROULETTE_SPIN_TIME;
  hero.rouletteSpinDur = ROULETTE_SPIN_TIME;
}

function tickSpinFlicker(hero: RouletteHero): void {
  const faces = hero.rouletteFaces;
  if (faces.length === 0) {return;}
  const dur = Math.max(0.001, hero.rouletteSpinDur);
  const u = Math.max(0, Math.min(1, 1 - hero.rouletteTime / dur));
  const eased = 1 - (1 - u) * (1 - u);
  const flicker = Math.floor(eased * 1.65 * faces.length) % faces.length;
  hero.rouletteSpinId = faces[flicker].id;
  hero.rouletteLabel = faces[flicker].name;
}

function tickSpinPhase(hero: RouletteHero): void {
  tickSpinFlicker(hero);
  if (hero.rouletteTime > 0) {return;}
  const face = pendingFace(hero.roulettePending);
  applyRouletteFace(hero, hero.roulettePending);
  hero.roulettePhase = "land";
  hero.rouletteTime = ROULETTE_LAND_TIME;
  hero.rouletteLabel = face ? face.name : "";
  hero.rouletteSpinId = face ? face.id : "";
  hero.rouletteDesc = face ? rouletteFaceDesc(face) : "";
  hero.roulettePending = {};
}

/* eslint-disable no-restricted-syntax -- 원본 roulette_buff.gd:151-179 face 한국어 설명 정본 */
const ROULETTE_FACE_DESC: Record<string, string> = {
  atk: "이번 목숨 동안 공격력이 올라갑니다",
  spd: "이번 목숨 동안 이동속도가 빨라집니다",
  def: "받는 피해가 줄어듭니다",
  hp: "최대 체력과 현재 체력이 늘어납니다",
  rate: "연사 속도가 빨라집니다",
  range: "총알이 더 멀리 나갑니다",
  giant: "몸이 커지고 공격과 이동이 세집니다",
  double_giant: "더 크게 변하고 능력치가 크게 오릅니다",
  shield: "잠시 보호막이 생깁니다",
  berserk: "공격과 연사가 잠깐 폭주합니다",
  sniper: "사거리가 늘어나고 한 방이 세집니다",
  turtle: "2초 동안 공격과 대시를 쓸 수 없습니다",
};
/* eslint-enable no-restricted-syntax */

/** roulette_face_desc — face.id 로 한국어 설명, 미지 id 는 name. */
export function rouletteFaceDesc(face: { id: string; name: string }): string {
  return ROULETTE_FACE_DESC[face.id] ?? face.name;
}

export function tickRoulette(hero: RouletteHero, dt: number): void {
  tickTimedBuffs(hero, dt);
  if (hero.roulettePhase === "") {return;}
  hero.rouletteTime = Math.max(0, hero.rouletteTime - dt);
  if (hero.roulettePhase === "bonus") {tickBonusPhase(hero); return;}
  if (hero.roulettePhase === "spin") {tickSpinPhase(hero); return;}
  if (hero.roulettePhase === "land" && hero.rouletteTime <= 0) {beginNextRoulette(hero);}
}

export function tickRoulettes(heroes: Iterable<RouletteHero>, dt: number): void {
  for (const hero of heroes) {tickRoulette(hero, dt);}
}

export function absorbRouletteShield(hero: RouletteHero, amount: number): number {
  let left = amount;
  for (const buff of hero.rlTimed) {
    if (buff.shield <= 0 || left <= 0) {continue;}
    const take = Math.min(buff.shield, left);
    buff.shield -= take;
    left -= take;
  }
  return left;
}

export function packRouletteSnap(hero: RouletteHero): Record<string, unknown> {
  return {
    roulette_phase: hero.roulettePhase, roulette_time: hero.rouletteTime,
    roulette_label: hero.rouletteLabel, roulette_rank: hero.rouletteRank,
    roulette_spin_id: hero.rouletteSpinId, roulette_desc: hero.rouletteDesc,
  };
}

export const seedWanted = createWantedState;
export const tickWanted = updateThreat;
export const applyKillBounty = awardKillBounty;
export const applyRoulette = applyRouletteFace;
export const tickRouletteBuffs = tickRoulettes;
export const seed = createWantedState;
export const tick = updateThreat;
export const apply = awardKillBounty;
export const pack = packWantedSnap;
