import type { LoaderState } from "@/types";
import { clampPackPct } from "../domain/waiting-room-pack";

/** Godot 로더 스냅샷 → 대기실 팩 퍼센트. */
export function packPctFromLoader(state: LoaderState, progress: number): number {
  if (state === "ready" || state === "running" || state === "compiling") {return 100;}
  if (state === "downloading") {return clampPackPct(progress * 100);}
  return 0;
}

/** 허브에 올릴 간격 — 5% 단위와 0·100만. */
export function shouldSendPackPct(prev: number | null, next: number): boolean {
  const pct = clampPackPct(next);
  if (prev === null) {return true;}
  if (pct === prev) {return false;}
  if (pct === 0 || pct === 100) {return true;}
  return pct >= prev + 5;
}
