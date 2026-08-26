/**
 * WANTED + 킬 룰렛 — match_lifecycle.gd update_threat/_reward_attacker bounty
 * 와 roulette_buff.gd 결정론 포팅. 시계 없음. 면 선택은 RouletteRng.
 */
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

type FaceRow = [string, string, "timed" | "until", number, number, number, number, number, number, number, number];

function emptyUntil(): RouletteUntil {
  return { atk: 0, spd: 0, def: 0, hp: 0, rate: 0, range: 0 };
}

function mkFace(row: FaceRow): RouletteFace {
  const [id, name, kind, atk, spd, def, hp, rate, range, shield, dur] = row;
  return { id, name, kind, atk, spd, def, hp, rate, range, shield, dur };
}

const TURTLE_FACE = mkFace(["turtle", "TURTLE", "timed", 0, 0, 0, 0, 0, 0, 0, 2]);

const FACE_TABLE: Record<string, { timed: FaceRow[]; until: FaceRow[] }> = {
  assist: {
    timed: [
      ["giant", "GIANT", "timed", 2, 3, 0, 2, 0, 0, 0, 8],
      ["shield", "SHIELD", "timed", 0, 0, 0, 0, 0, 0, 24, 2],
      ["berserk", "BERSERK", "timed", 2, 0, 0, 0, 0.04, 0, 0, 5],
    ],
    until: [
      ["atk", "ATK +2", "until", 2, 0, 0, 0, 0, 0, 0, 0],
      ["spd", "SPD +2", "until", 0, 2, 0, 0, 0, 0, 0, 0],
      ["def", "DEF +4%", "until", 0, 0, 0.04, 0, 0, 0, 0, 0],
      ["hp", "HP +8", "until", 0, 0, 0, 8, 0, 0, 0, 0],
      ["rate", "RATE +4%", "until", 0, 0, 0, 0, 0.04, 0, 0, 0],
      ["range", "RANGE +5%", "until", 0, 0, 0, 0, 0, 0.05, 0, 0],
    ],
  },
  wanted: {
    timed: [
      ["giant", "GIANT", "timed", 4.5, 7.5, 0, 4.5, 0, 0, 0, 12],
      ["shield", "SHIELD", "timed", 0, 0, 0, 0, 0, 0, 60, 3],
      ["berserk", "BERSERK", "timed", 4.5, 0, 0, 0, 0.105, 0, 0, 8],
      ["sniper", "SNIPER", "timed", 4.5, 0, 0, 0, 0, 0.12, 0, 9],
      ["double_giant", "DOUBLE GIANT", "timed", 6, 10, 0, 6, 0, 0, 0, 12],
    ],
    until: [
      ["atk", "ATK +5", "until", 4.5, 0, 0, 0, 0, 0, 0, 0],
      ["spd", "SPD +6", "until", 0, 6, 0, 0, 0, 0, 0, 0],
      ["def", "DEF +9%", "until", 0, 0, 0.09, 0, 0, 0, 0, 0],
      ["hp", "HP +21", "until", 0, 0, 0, 21, 0, 0, 0, 0],
      ["rate", "RATE +11%", "until", 0, 0, 0, 0, 0.105, 0, 0, 0],
      ["range", "RANGE +12%", "until", 0, 0, 0, 0, 0, 0.12, 0, 0],
    ],
  },
  kill: {
    timed: [
      ["giant", "GIANT", "timed", 3, 5, 0, 3, 0, 0, 0, 12],
      ["shield", "SHIELD", "timed", 0, 0, 0, 0, 0, 0, 40, 3],
      ["berserk", "BERSERK", "timed", 3, 0, 0, 0, 0.07, 0, 0, 8],
      ["sniper", "SNIPER", "timed", 3, 0, 0, 0, 0, 0.08, 0, 9],
    ],
    until: [
      ["atk", "ATK +3", "until", 3, 0, 0, 0, 0, 0, 0, 0],
      ["spd", "SPD +4", "until", 0, 4, 0, 0, 0, 0, 0, 0],
      ["def", "DEF +6%", "until", 0, 0, 0.06, 0, 0, 0, 0, 0],
      ["hp", "HP +14", "until", 0, 0, 0, 14, 0, 0, 0, 0],
      ["rate", "RATE +7%", "until", 0, 0, 0, 0, 0.07, 0, 0, 0],
      ["range", "RANGE +8%", "until", 0, 0, 0, 0, 0, 0.08, 0, 0],
    ],
  },
};

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

export function rouletteBChance(rank: string): number {
  if (rank === "assist") {return ROULETTE_B_CHANCE_ASSIST;}
  if (rank === "wanted") {return ROULETTE_B_CHANCE_WANTED;}
  return ROULETTE_B_CHANCE_KILL;
}

export function rouletteFaces(rank: string, timedGroup: boolean): RouletteFace[] {
  const table = FACE_TABLE[rank] ?? FACE_TABLE.kill;
  return (timedGroup ? table.timed : table.until).map(mkFace);
}

export function pickRouletteFace(rank: string, rng: RouletteRng): RouletteFace {
  if (rng.rangef(0, 1) < ROULETTE_TURTLE_CHANCE) {return { ...TURTLE_FACE };}
  const faces = rouletteFaces(rank, rng.rangef(0, 1) < rouletteBChance(rank));
  return { ...faces[rng.rangei(0, faces.length - 1)] };
}

export function rouletteFaceList(rank: string): Array<{ id: string; name: string }> {
  const faces: Array<{ id: string; name: string }> = [];
  for (const face of rouletteFaces(rank, false)) {faces.push({ id: face.id, name: face.name });}
  for (const face of rouletteFaces(rank, true)) {faces.push({ id: face.id, name: face.name });}
  faces.push({ id: "turtle", name: "TURTLE" });
  return faces;
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

function num(v: unknown, fallback: number): number {
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

export function applyRouletteFace(hero: RouletteHero, face: RouletteFace | Record<string, never>): void {
  if (!hero.alive) {return;}
  const hpAdd = num(face.hp, 0);
  if (String(face.kind ?? "until") === "until") {
    hero.rlUntil.atk += num(face.atk, 0);
    hero.rlUntil.spd += num(face.spd, 0);
    hero.rlUntil.def += num(face.def, 0);
    hero.rlUntil.hp += hpAdd;
    hero.rlUntil.rate += num(face.rate, 0);
    hero.rlUntil.range += num(face.range, 0);
    addHp(hero, hpAdd);
    return;
  }
  hero.rlTimed.push({
    id: String(face.id ?? ""), name: String(face.name ?? ""), time: num(face.dur, 0),
    atk: num(face.atk, 0), spd: num(face.spd, 0), def: num(face.def, 0), hp: hpAdd,
    rate: num(face.rate, 0), range: num(face.range, 0), shield: num(face.shield, 0),
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
  const face = hero.roulettePending;
  applyRouletteFace(hero, face);
  hero.roulettePhase = "land";
  hero.rouletteTime = ROULETTE_LAND_TIME;
  hero.rouletteLabel = String(face.name ?? "");
  hero.rouletteSpinId = String(face.id ?? "");
  hero.rouletteDesc = "";
  hero.roulettePending = {};
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
