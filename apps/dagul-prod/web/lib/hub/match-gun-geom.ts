import type { Vec2 } from "./match-equipment.js";

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
