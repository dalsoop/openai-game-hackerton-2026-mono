/**
 * 12지신 장비 레지스트리 — equipment_registry.gd 결정론 포팅.
 * 수치·이름·매핑은 원본 그대로. RNG·시계 없음.
 */

export type FireMode = "auto" | "semi" | "bolt" | "gl" | "lever";
export type Vec2 = { x: number; y: number };

export type EquipmentDef = {
  id: string;
  name: string;
  normalName: string;
  skillName: string;
  skillDesc: string;
  ultimateName: string;
  ultimateDesc: string;
  fireMode: FireMode;
  damage: number;
  interval: number;
  speed: number;
  range: number;
  spread: number;
  projectiles: number;
  splash: number;
  leech: boolean;
  cc: number;
  knockback: number;
  kind: string;
  radius: number;
  pierce: number;
  burstShots: number;
  magSize: number;
  reloadTime: number;
  preferredRange: number;
  cooldown: number;
};

export type EquipmentIdentity = { characterName: string; role: string; badge: string };
export type EquipmentCombat = {
  moveSpeed: number;
  maxHp: number;
  weight: number;
  comboCapRatio: number;
  specialName: string;
  specialDesc: string;
};
export type EquipmentMobility = {
  mobilityName: string;
  mobilityDesc: string;
  mobilityCooldown: number;
  mobilityDistance: number;
};
export type Equipment = EquipmentDef & EquipmentIdentity & EquipmentCombat & EquipmentMobility;

const SKILL = { skillName: "", skillDesc: "", ultimateName: "", ultimateDesc: "" } as const;

/** equipment_registry.gd defs 12행 — skill/ultimate 이름은 전부 빈 문자열. */
export const EQUIPMENT_DEFS: readonly EquipmentDef[] = [
  { id: "scatter", name: "SPAS-12", normalName: "PUMP BLAST", ...SKILL, fireMode: "semi", damage: 33.6, interval: 0.50, speed: 800.0, range: 0.48, spread: 0.12, projectiles: 5, splash: 0.0, leech: false, cc: 0.0, knockback: 24.0, kind: "pellet", radius: 6.0, pierce: 0, burstShots: 0, magSize: 7, reloadTime: 1.80, preferredRange: 260.0, cooldown: 99.0 },
  { id: "rail", name: "AWM", normalName: "BOLT SHOT", ...SKILL, fireMode: "bolt", damage: 142.0, interval: 1.22, speed: 1520.0, range: 1.12, spread: 0.006, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 14.0, kind: "bolt", radius: 5.0, pierce: 3, burstShots: 0, magSize: 5, reloadTime: 2.40, preferredRange: 560.0, cooldown: 99.0 },
  { id: "mortar", name: "M79", normalName: "RPG", ...SKILL, fireMode: "gl", damage: 88.0, interval: 1.05, speed: 620.0, range: 0.95, spread: 0.012, projectiles: 1, splash: 120.0, leech: false, cc: 0.0, knockback: 42.0, kind: "shell", radius: 9.0, pierce: 0, burstShots: 0, magSize: 1, reloadTime: 1.40, preferredRange: 430.0, cooldown: 99.0 },
  { id: "leech", name: "MP5", normalName: "SMG BURST", ...SKILL, fireMode: "auto", damage: 11.4, interval: 0.095, speed: 980.0, range: 0.42, spread: 0.038, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 5.0, kind: "bolt", radius: 5.0, pierce: 0, burstShots: 0, magSize: 25, reloadTime: 1.25, preferredRange: 240.0, cooldown: 99.0 },
  { id: "breaker", name: "RPK", normalName: "LMG FIRE", ...SKILL, fireMode: "auto", damage: 12.2, interval: 0.155, speed: 1020.0, range: 0.82, spread: 0.028, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 8.0, kind: "bolt", radius: 6.0, pierce: 0, burstShots: 0, magSize: 40, reloadTime: 2.20, preferredRange: 380.0, cooldown: 99.0 },
  { id: "burst", name: "GLOCK 18", normalName: "AUTO PISTOL", ...SKILL, fireMode: "auto", damage: 13.26, interval: 0.105, speed: 1000.0, range: 0.44, spread: 0.040, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 5.0, kind: "bolt", radius: 5.0, pierce: 0, burstShots: 0, magSize: 18, reloadTime: 1.15, preferredRange: 250.0, cooldown: 99.0 },
  { id: "blade", name: "THOMPSON", normalName: "DRUM FIRE", ...SKILL, fireMode: "auto", damage: 12.2, interval: 0.125, speed: 910.0, range: 0.58, spread: 0.055, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 6.0, kind: "bolt", radius: 5.0, pierce: 0, burstShots: 0, magSize: 32, reloadTime: 1.70, preferredRange: 300.0, cooldown: 99.0 },
  { id: "brawler", name: "M1911", normalName: "SEMI PISTOL", ...SKILL, fireMode: "semi", damage: 46.8, interval: 0.40, speed: 1080.0, range: 0.55, spread: 0.018, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 8.0, kind: "bolt", radius: 5.0, pierce: 0, burstShots: 0, magSize: 7, reloadTime: 1.05, preferredRange: 230.0, cooldown: 99.0 },
  { id: "bomb", name: "DOUBLE BARREL", normalName: "TWIN BLAST", ...SKILL, fireMode: "semi", damage: 27.4, interval: 0.22, speed: 760.0, range: 0.40, spread: 0.16, projectiles: 6, splash: 0.0, leech: false, cc: 0.0, knockback: 28.0, kind: "pellet", radius: 6.0, pierce: 0, burstShots: 2, magSize: 2, reloadTime: 1.10, preferredRange: 220.0, cooldown: 99.0 },
  { id: "spear", name: "AK-47", normalName: "RIFLE FIRE", ...SKILL, fireMode: "auto", damage: 13.2, interval: 0.135, speed: 1060.0, range: 0.86, spread: 0.030, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 8.0, kind: "bolt", radius: 5.0, pierce: 0, burstShots: 0, magSize: 30, reloadTime: 1.55, preferredRange: 390.0, cooldown: 99.0 },
  { id: "chain", name: "M4A1", normalName: "RIFLE FIRE", ...SKILL, fireMode: "auto", damage: 11.6, interval: 0.115, speed: 1100.0, range: 0.88, spread: 0.022, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 7.0, kind: "bolt", radius: 5.0, pierce: 0, burstShots: 0, magSize: 30, reloadTime: 1.35, preferredRange: 400.0, cooldown: 99.0 },
  { id: "shield", name: "WINCHESTER", normalName: "LEVER SHOT", ...SKILL, fireMode: "lever", damage: 70.2, interval: 0.62, speed: 1200.0, range: 0.78, spread: 0.014, projectiles: 1, splash: 0.0, leech: false, cc: 0.0, knockback: 12.0, kind: "bolt", radius: 5.0, pierce: 0, burstShots: 0, magSize: 8, reloadTime: 1.60, preferredRange: 360.0, cooldown: 99.0 },
];

/** identity_for `_` 분기 — shield 도 명시 키가 없어 여기로 떨어진다. */
export const FALLBACK_IDENTITY: EquipmentIdentity = { characterName: "WARD", role: "FORTIFIER", badge: "BW" };
export const FALLBACK_COMBAT: EquipmentCombat = { moveSpeed: 340.0, maxHp: 213.0, weight: 1.55, comboCapRatio: 0.24, specialName: "HEAVY FRAME", specialDesc: "slowest high HP body" };
export const FALLBACK_MOBILITY: EquipmentMobility = { mobilityName: "BRACE STEP", mobilityDesc: "small step with a long guard", mobilityCooldown: 5.0, mobilityDistance: 138.0 };

const IDENTITY: Readonly<Record<string, EquipmentIdentity>> = {
  scatter: { characterName: "REX", role: "BRAWLER", badge: "SG" },
  rail: { characterName: "SCOPE", role: "SNIPER", badge: "RL" },
  mortar: { characterName: "BOMBI", role: "CONTROLLER", badge: "CM" },
  leech: { characterName: "NYX", role: "DRAINER", badge: "LC" },
  breaker: { characterName: "BRICK", role: "VANGUARD", badge: "BH" },
  burst: { characterName: "ZIP", role: "HUNTER", badge: "BR" },
  blade: { characterName: "AKARI", role: "ASSASSIN", badge: "KT" },
  brawler: { characterName: "MACK", role: "STRIKER", badge: "FK" },
  bomb: { characterName: "MIMI", role: "SABOTEUR", badge: "MN" },
  spear: { characterName: "ORIN", role: "LANCER", badge: "SP" },
  chain: { characterName: "RIVA", role: "CONTROLLER", badge: "CH" },
};
const COMBAT: Readonly<Record<string, EquipmentCombat>> = {
  scatter: { moveSpeed: 432.0, maxHp: 155.0, weight: 1.00, comboCapRatio: 0.26, specialName: "LIGHT FRAME", specialDesc: "fast close-range body" },
  rail: { moveSpeed: 394.0, maxHp: 141.0, weight: 0.88, comboCapRatio: 0.27, specialName: "LIGHT FRAME", specialDesc: "low HP long-range body" },
  mortar: { moveSpeed: 365.0, maxHp: 140.0, weight: 0.92, comboCapRatio: 0.26, specialName: "GLASS FRAME", specialDesc: "slow glass cannon body" },
  leech: { moveSpeed: 419.0, maxHp: 149.0, weight: 0.98, comboCapRatio: 0.26, specialName: "MID FRAME", specialDesc: "average SMG body" },
  breaker: { moveSpeed: 359.0, maxHp: 195.0, weight: 1.34, comboCapRatio: 0.24, specialName: "HEAVY FRAME", specialDesc: "high launch resistance" },
  burst: { moveSpeed: 454.0, maxHp: 137.0, weight: 0.90, comboCapRatio: 0.27, specialName: "LIGHT FRAME", specialDesc: "fast low HP body" },
  blade: { moveSpeed: 478.0, maxHp: 157.0, weight: 0.86, comboCapRatio: 0.27, specialName: "SWIFT FRAME", specialDesc: "fastest body" },
  brawler: { moveSpeed: 440.0, maxHp: 176.0, weight: 1.12, comboCapRatio: 0.24, specialName: "COMEBACK", specialDesc: "12% more damage below half health" },
  bomb: { moveSpeed: 389.0, maxHp: 158.0, weight: 1.04, comboCapRatio: 0.26, specialName: "MID FRAME", specialDesc: "average shotgun body" },
  spear: { moveSpeed: 427.0, maxHp: 204.0, weight: 1.02, comboCapRatio: 0.26, specialName: "TANK FRAME", specialDesc: "high HP rifle body" },
  chain: { moveSpeed: 402.0, maxHp: 164.0, weight: 1.08, comboCapRatio: 0.24, specialName: "MID FRAME", specialDesc: "average rifle body" },
};
const MOBILITY: Readonly<Record<string, EquipmentMobility>> = {
  scatter: { mobilityName: "SKIRMISH HOP", mobilityDesc: "fast lateral recoil", mobilityCooldown: 4.2, mobilityDistance: 219.0 },
  rail: { mobilityName: "SIGHTLINE STEP", mobilityDesc: "short precise sidestep", mobilityCooldown: 4.8, mobilityDistance: 190.0 },
  mortar: { mobilityName: "BLAST HOP", mobilityDesc: "jump and repel nearby enemies", mobilityCooldown: 5.2, mobilityDistance: 201.0 },
  leech: { mobilityName: "SHADOW PULL", mobilityDesc: "long slide with a small heal", mobilityCooldown: 5.0, mobilityDistance: 247.0 },
  breaker: { mobilityName: "IRON MARCH", mobilityDesc: "short armored advance", mobilityCooldown: 4.6, mobilityDistance: 167.0 },
  burst: { mobilityName: "FLASH CUT", mobilityDesc: "long blink with no attack", mobilityCooldown: 5.5, mobilityDistance: 288.0 },
  blade: { mobilityName: "SHADOW SHEATH", mobilityDesc: "blink and evade one hit", mobilityCooldown: 3.8, mobilityDistance: 305.0 },
  brawler: { mobilityName: "WEAVE", mobilityDesc: "short dodge that breaks a combo", mobilityCooldown: 3.6, mobilityDistance: 178.0 },
  bomb: { mobilityName: "BLAST ROLL", mobilityDesc: "roll away from the live fuse", mobilityCooldown: 4.8, mobilityDistance: 219.0 },
  spear: { mobilityName: "POLE VAULT", mobilityDesc: "long committed vault", mobilityCooldown: 4.3, mobilityDistance: 265.0 },
  chain: { mobilityName: "SWING STEP", mobilityDesc: "curve around the captured target", mobilityCooldown: 4.5, mobilityDistance: 236.0 },
};

/** Rat=0 .. Pig=11 — gun_signature.gd ANIMAL_SIGNATURE_EQUIPMENT. */
export const ANIMAL_SIGNATURE_EQUIPMENT: readonly string[] = [
  "burst", "breaker", "spear", "brawler", "mortar", "leech",
  "chain", "shield", "blade", "rail", "scatter", "bomb",
];
export const MODE_START_EQUIPMENT: Readonly<Record<string, string>> = {
  "gun-semi": "rail", "gun-auto": "burst", item: "scatter",
};
export const GUN_LOOT_CHAIN: readonly string[] = [
  "rail", "burst", "scatter", "mortar", "breaker", "bomb",
  "leech", "blade", "spear", "chain", "shield", "brawler",
];
export const GUN_LOOT_MODES: readonly string[] = ["gun-semi", "gun-auto", "full"];

export function identityFor(equipmentId: string): EquipmentIdentity {
  return IDENTITY[equipmentId] ?? FALLBACK_IDENTITY;
}
export function combatStatsFor(equipmentId: string): EquipmentCombat {
  return COMBAT[equipmentId] ?? FALLBACK_COMBAT;
}
export function mobilityFor(equipmentId: string): EquipmentMobility {
  return MOBILITY[equipmentId] ?? FALLBACK_MOBILITY;
}
export function equipmentForAnimal(slot: number): string {
  const n = ANIMAL_SIGNATURE_EQUIPMENT.length;
  return ANIMAL_SIGNATURE_EQUIPMENT[((slot % n) + n) % n] ?? "burst";
}
export function isSignature(slot: number, equipmentId: string): boolean {
  return equipmentForAnimal(slot) === equipmentId;
}
export function startEquipmentId(mode: string, animal: number): string {
  return MODE_START_EQUIPMENT[mode] ?? equipmentForAnimal(animal);
}
export function makeEquipment(equipmentId: string): Equipment {
  const def = EQUIPMENT_DEFS.find((d) => d.id === equipmentId) ?? EQUIPMENT_DEFS[0];
  return { ...def, ...identityFor(def.id), ...mobilityFor(def.id), ...combatStatsFor(def.id) };
}
export function equipmentReach(eq: Pick<EquipmentDef, "speed" | "range">, rouletteRange = 0): number {
  return eq.speed * eq.range * 0.92 * (1.0 + rouletteRange);
}
export function nextGunLootId(currentId: string): string {
  const i = GUN_LOOT_CHAIN.indexOf(currentId);
  if (i < 0) {return GUN_LOOT_CHAIN[0] ?? "rail";}
  if (i >= GUN_LOOT_CHAIN.length - 1) {return "";}
  return GUN_LOOT_CHAIN[i + 1] ?? "";
}
export const seed = makeEquipment;
export const apply = startEquipmentId;
export const tick = nextGunLootId;

export type GunVisual = {
  frame: number; gun: string; family: string; muzzleRow: number;
  ox: number; oy: number; mx: number; my: number;
};
export type GunFeel = { kick: number; rot: number; body: number; strap: number; decay: number; muzzle: number };
export type GunFx = { row: number; frames: number; scale: number; shake: number };

export const GUN_TSCN_SCALE = 0.645;
export const GUN_CELL_W = 256.0;
export const MUZZLE_FLASH_LOCAL: Vec2 = { x: 49.536, y: 0.0 };
export const SPRAY_RECOVER_DEFAULT = 12.0;

export const EQUIP_VISUAL: Readonly<Record<string, GunVisual>> = {
  burst: { frame: 1, gun: "Glock 18", family: "pistol", muzzleRow: 0, ox: 9.302326, oy: -12.403107, mx: 93.0, my: -22.000305 },
  brawler: { frame: 0, gun: "M1911", family: "pistol", muzzleRow: 0, ox: 12.403101, oy: -20.155045, mx: 89.0, my: -22.000305 },
  leech: { frame: 2, gun: "MP5", family: "smg", muzzleRow: 1, ox: 41.860466, oy: -29.45737, mx: 133.0, my: -22.000305 },
  blade: { frame: 3, gun: "Thompson", family: "smg", muzzleRow: 1, ox: -6.2015514, oy: -17.05427, mx: 114.0, my: -19.0 },
  spear: { frame: 6, gun: "AK-47", family: "rifle", muzzleRow: 1, ox: 29.457336, oy: 0.0, mx: 138.0, my: -10.0 },
  chain: { frame: 5, gun: "M4A1", family: "rifle", muzzleRow: 1, ox: 27.906982, oy: -4.651169, mx: 137.0, my: -16.50813 },
  shield: { frame: 10, gun: "Winchester M1873", family: "rifle", muzzleRow: 1, ox: 35.658913, oy: 21.705421, mx: 144.0, my: -19.0 },
  scatter: { frame: 9, gun: "SPAS-12", family: "shotgun", muzzleRow: 1, ox: 40.310078, oy: 18.604645, mx: 145.0, my: -17.0 },
  bomb: { frame: 8, gun: "Double barrel", family: "shotgun", muzzleRow: 2, ox: 29.457365, oy: 20.155033, mx: 140.0, my: -22.0 },
  breaker: { frame: 4, gun: "RPK", family: "heavy", muzzleRow: 2, ox: 20.15503, oy: 7.751938, mx: 130.0, my: -9.675 },
  rail: { frame: 7, gun: "AWM (AKM stand-in)", family: "heavy", muzzleRow: 2, ox: 49.612404, oy: -17.05427, mx: 151.0, my: -14.754375 },
  mortar: { frame: 11, gun: "M79", family: "heavy", muzzleRow: 2, ox: 9.302326, oy: -4.651169, mx: 120.0, my: -20.0 },
};
export const GUN_FEEL: Readonly<Record<string, GunFeel>> = {
  burst: { kick: 6.2, rot: 0.07, body: 0.07, strap: 1.4, decay: 24.0, muzzle: 0.12 },
  brawler: { kick: 11.0, rot: 0.16, body: 0.12, strap: 1.8, decay: 22.0, muzzle: 0.055 },
  leech: { kick: 5.0, rot: 0.065, body: 0.06, strap: 1.8, decay: 22.0, muzzle: 0.11 },
  blade: { kick: 6.4, rot: 0.085, body: 0.08, strap: 2.0, decay: 18.0, muzzle: 0.12 },
  spear: { kick: 10.5, rot: 0.15, body: 0.12, strap: 2.0, decay: 13.0, muzzle: 0.14 },
  chain: { kick: 8.2, rot: 0.11, body: 0.09, strap: 1.6, decay: 15.0, muzzle: 0.13 },
  shield: { kick: 12.5, rot: 0.20, body: 0.14, strap: 2.2, decay: 11.0, muzzle: 0.16 },
  scatter: { kick: 20.0, rot: 0.34, body: 0.22, strap: 3.2, decay: 7.5, muzzle: 0.16 },
  bomb: { kick: 24.0, rot: 0.40, body: 0.26, strap: 3.6, decay: 6.5, muzzle: 0.17 },
  breaker: { kick: 13.5, rot: 0.18, body: 0.15, strap: 2.4, decay: 8.5, muzzle: 0.15 },
  rail: { kick: 20.0, rot: 0.26, body: 0.20, strap: 3.0, decay: 7.0, muzzle: 0.18 },
  mortar: { kick: 18.0, rot: 0.24, body: 0.19, strap: 2.8, decay: 7.5, muzzle: 0.17 },
};
export const GUN_FX: Readonly<Record<string, GunFx>> = {
  brawler: { row: 0, frames: 2, scale: 1.0, shake: 3 }, burst: { row: 0, frames: 2, scale: 1.0, shake: 2 },
  leech: { row: 1, frames: 3, scale: 1.0, shake: 3 }, blade: { row: 1, frames: 3, scale: 1.0, shake: 3 },
  chain: { row: 1, frames: 3, scale: 1.0, shake: 4 }, spear: { row: 1, frames: 3, scale: 1.28, shake: 5 },
  shield: { row: 1, frames: 3, scale: 1.0, shake: 4 }, scatter: { row: 1, frames: 3, scale: 1.0, shake: 10 },
  breaker: { row: 2, frames: 4, scale: 1.0, shake: 6 }, bomb: { row: 2, frames: 4, scale: 1.12, shake: 14 },
  rail: { row: 2, frames: 4, scale: 1.1, shake: 14 }, mortar: { row: 2, frames: 4, scale: 1.1, shake: 11 },
};
type XY = readonly [number, number];
const SPRAY_KICK: Readonly<Record<string, readonly XY[]>> = {
  spear: [[0, -15], [1, -17], [-1, -16], [2, -15], [-2, -14], [3, -12], [-5, -10], [7, -7], [-9, -4], [11, -2], [-12, 0], [12, 1], [-11, 1], [10, 0], [-10, 1], [9, 0], [-9, 1], [8, 0], [-8, 0], [8, 1], [-7, 0], [7, 0], [-7, 1], [6, 0], [-6, 0], [6, 0], [-5, 0], [5, 0], [-5, 0], [5, 0]],
  chain: [[0, -12], [1, -13], [0, -13], [1, -12], [-2, -11], [3, -9], [-4, -7], [6, -5], [-7, -3], [8, -1], [-8, 0], [8, 1], [-7, 0], [7, 0], [-6, 1], [6, 0], [-6, 0], [5, 0], [-5, 0], [5, 0], [-5, 0], [4, 0], [-4, 0], [4, 0], [-4, 0], [4, 0], [-3, 0], [3, 0], [-3, 0], [3, 0]],
  leech: [[1, -8], [-1, -9], [2, -8], [-3, -7], [4, -6], [-6, -4], [7, -3], [-8, -1], [8, 0], [-8, 1], [7, 0], [-7, 0], [6, 1], [-6, 0], [6, 0], [-5, 0], [5, 0], [-5, 0], [4, 0], [-4, 0], [4, 0], [-4, 0], [3, 0], [-3, 0], [3, 0]],
  blade: [[1, -10], [-2, -11], [3, -10], [-4, -8], [6, -6], [-8, -4], [9, -2], [-10, 0], [10, 1], [-9, 0], [9, 0], [-8, 1], [8, 0], [-7, 0], [7, 0], [-6, 0], [6, 0], [-6, 0], [5, 0], [-5, 0], [5, 0], [-4, 0], [4, 0], [-4, 0], [4, 0], [-3, 0], [3, 0], [-3, 0], [3, 0], [-3, 0], [3, 0], [-2, 0]],
  breaker: [[0, -14], [1, -15], [-1, -14], [2, -13], [-3, -12], [4, -10], [-6, -8], [8, -5], [-9, -3], [11, -1], [-12, 0], [12, 1], [-11, 0], [10, 0], [-10, 1], [9, 0], [-9, 0], [8, 0], [-8, 0], [8, 1], [-7, 0], [7, 0], [-7, 0], [6, 0], [-6, 0], [6, 0], [-5, 0], [5, 0], [-5, 0], [5, 0], [-5, 0], [4, 0], [-4, 0], [4, 0], [-4, 0], [4, 0], [-3, 0], [3, 0], [-3, 0], [3, 0]],
  burst: [[1, -9], [-2, -10], [3, -9], [-4, -7], [6, -5], [-7, -3], [8, -1], [-8, 0], [7, 1], [-7, 0], [6, 0], [-6, 0], [5, 0], [-5, 0], [5, 0], [-4, 0], [4, 0], [-4, 0]],
  brawler: [[0, -18], [2, -16], [-3, -14], [4, -10], [-5, -6], [5, -3], [-4, 0]],
  shield: [[0, -20], [2, -16], [-3, -12], [4, -8], [-5, -4], [5, -2], [-4, 0], [4, 0]],
  scatter: [[3, -28], [-4, -24], [6, -18], [-7, -12], [8, -8], [-6, -4], [5, 0]],
  bomb: [[5, -34], [-6, -22]],
  rail: [[1, -30], [0, -8], [-1, -6], [1, -5], [0, -4]],
  mortar: [[2, -26]],
};
const SPRAY_RECOVER: Readonly<Record<string, number>> = {
  spear: 10.0, chain: 12.0, leech: 16.0, blade: 14.0, breaker: 8.0,
  burst: 15.0, brawler: 14.0, shield: 9.0, scatter: 7.0, bomb: 7.0, rail: 6.0, mortar: 6.0,
};

export function visualForEquipment(id: string): GunVisual { return EQUIP_VISUAL[id] ?? EQUIP_VISUAL.burst; }
export function feelForEquipment(id: string): GunFeel { return GUN_FEEL[id] ?? GUN_FEEL.burst; }
export function fxForEquipment(id: string): GunFx { return GUN_FX[id] ?? GUN_FX.burst; }
export function familyOf(id: string): string { return visualForEquipment(id).family; }
export function sprayKick(id: string, index: number): Vec2 {
  const table = SPRAY_KICK[id] ?? SPRAY_KICK.burst;
  if (index < 0 || table.length === 0) {return { x: 0, y: 0 };}
  const pair = table[Math.min(index, table.length - 1)] ?? [0, 0];
  return { x: pair[0], y: pair[1] };
}
export function sprayStep(id: string, index: number): Vec2 {
  let acc = { x: 0, y: 0 };
  for (let i = 0; i <= Math.max(0, index); i += 1) {
    const k = sprayKick(id, i);
    acc = { x: acc.x + k.x, y: acc.y + k.y };
  }
  return acc;
}
export function sprayRecoverRate(id: string): number { return SPRAY_RECOVER[id] ?? SPRAY_RECOVER_DEFAULT; }
export function gunWorldScale(): number { return 72.0 / (GUN_CELL_W * GUN_TSCN_SCALE); }
function aimDir(ax: number, ay: number): Vec2 {
  const lenSq = ax * ax + ay * ay;
  if (lenSq <= 0.0001) {return { x: 1, y: 0 };}
  const len = Math.sqrt(lenSq);
  return { x: ax / len, y: ay / len };
}
export function gunMountPos(bx: number, by: number, ax: number, ay: number, kick = 0): Vec2 {
  const dir = aimDir(ax, ay);
  const flip = dir.x < 0 ? -1 : 1;
  return { x: bx + flip * 6.0 + dir.x * (18.0 - kick), y: by + 4.0 + dir.y * (18.0 - kick) };
}
export function muzzleWorldPos(bx: number, by: number, ax: number, ay: number, id: string, kick = 0): Vec2 {
  const vis = visualForEquipment(id);
  const mount = gunMountPos(bx, by, ax, ay, kick);
  const dir = aimDir(ax, ay);
  const flip = dir.x < 0 ? -1 : 1;
  const angle = Math.atan2(dir.y, dir.x);
  const s = gunWorldScale();
  const sx = vis.mx * s;
  const sy = vis.my * s * flip;
  return { x: mount.x + Math.cos(angle) * sx - Math.sin(angle) * sy, y: mount.y + Math.sin(angle) * sx + Math.cos(angle) * sy };
}
