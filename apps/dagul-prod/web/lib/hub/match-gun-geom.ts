import { makeEquipment, type FireMode, type Vec2 } from "./match-equipment.js";
import type { EquipmentSkillTable, GunHero } from "./match-gun.js";

const BRAWLER_HP_RATIO = 0.5;
const RAIL_PASSIVE_DIST = 430.0;
const SPEAR_PASSIVE_DIST = 280.0;
const PASSIVE_MUL = 1.12;

export function hopLift(h: Pick<GunHero, "hopTime" | "hopMax" | "hopHeight">): number {
  if (h.hopTime <= 0) {return 0;}
  const hopMax = Math.max(0.001, h.hopMax);
  return h.hopHeight * Math.sin(Math.PI * Math.min(1, Math.max(0, 1.0 - h.hopTime / hopMax)));
}

export function attackDirection(x: number, y: number): Vec2 {
  const len = Math.hypot(x, y);
  if (len === 0) {return { x: 1, y: 0 };}
  return { x: x / len, y: y / len };
}

export function rotateVec(x: number, y: number, angle: number): Vec2 {
  const c = Math.cos(angle);
  const s = Math.sin(angle);
  return { x: x * c - y * s, y: x * s + y * c };
}

export function pelletOffset(index: number, count: number, spread: number): number {
  if (count <= 1) {return 0;}
  return (index - (count - 1) * 0.5) * spread;
}

export function projectileKind(equipmentId: string, kind: string): string {
  if (equipmentId === "rail") {return "tracer";}
  if (kind === "pellet" || kind === "bolt" || kind === "shell") {return kind;}
  return "bolt";
}

export function wantsFire(mode: FireMode, primary: boolean, primaryPressed: boolean): boolean {
  if (mode === "auto") {return primary;}
  return primaryPressed;
}

export function weaponPassiveDamageMul(id: string, hp: number, maxHp: number, dist: number): number {
  if (id === "brawler" && hp <= maxHp * BRAWLER_HP_RATIO) {return PASSIVE_MUL;}
  if (id === "rail" && dist >= RAIL_PASSIVE_DIST) {return PASSIVE_MUL;}
  if (id === "spear" && dist >= SPEAR_PASSIVE_DIST) {return PASSIVE_MUL;}
  return 1;
}

export function equipmentSkillTable(id: string): EquipmentSkillTable {
  const eq = makeEquipment(id);
  return { skillName: eq.skillName, skillDesc: eq.skillDesc, cooldown: eq.cooldown, implemented: false };
}
