/** 로딩 막대는 0..1 이고, 한 세션 안에서는 줄어들지 않는다. */

import { clamp01 } from "../util/math.js";
export { clamp01 };

export function ratioProgress(loaded: number, total: number): number {
  if (!(total > 0)) {return 0;}
  return clamp01(loaded / total);
}

export function monotonicProgress(prev: number, next: number, reset = false): number {
  const clamped = clamp01(next);
  if (reset) {return clamped;}
  return Math.max(clamp01(prev), clamped);
}

export function applyRuntimeProgress<T extends { progress: number; state: string }>(
  prev: T,
  partial: Partial<T>,
): T {
  const next = { ...prev, ...partial };
  if (partial.progress === undefined) {return next;}
  const reset = next.state === "idle" || next.state === "error";
  next.progress = monotonicProgress(prev.progress, partial.progress, reset);
  return next;
}
