import type { RouletteFace, RouletteRng } from "./match-wanted.js";

const TURTLE_CHANCE = 0.03;
const B_CHANCE_ASSIST = 0.25;
const B_CHANCE_WANTED = 0.55;
const B_CHANCE_KILL = 0.40;

type FaceRow = [string, string, "timed" | "until", number, number, number, number, number, number, number, number];

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

export function rouletteBChance(rank: string): number {
  if (rank === "assist") {return B_CHANCE_ASSIST;}
  if (rank === "wanted") {return B_CHANCE_WANTED;}
  return B_CHANCE_KILL;
}

export function rouletteFaces(rank: string, timedGroup: boolean): RouletteFace[] {
  const table = FACE_TABLE[rank] ?? FACE_TABLE.kill;
  return (timedGroup ? table.timed : table.until).map(mkFace);
}

export function pickRouletteFace(rank: string, rng: RouletteRng): RouletteFace {
  if (rng.rangef(0, 1) < TURTLE_CHANCE) {return { ...TURTLE_FACE };}
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
