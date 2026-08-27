export function clamp01(value: number): number {
  if (!Number.isFinite(value)) {return 0;}
  return Math.min(1, Math.max(0, value));
}

export function moveToward(x: number, y: number, tx: number, ty: number, delta: number): { x: number; y: number } {
  const dx = tx - x;
  const dy = ty - y;
  const dist = Math.hypot(dx, dy);
  if (dist <= delta || dist === 0) {return { x: tx, y: ty };}
  return { x: x + (dx / dist) * delta, y: y + (dy / dist) * delta };
}
