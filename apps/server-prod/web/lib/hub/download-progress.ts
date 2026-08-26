import type { LoaderState } from "@/types";
import { clampPct } from "../domain/download";

export function pctFromLoader(state: LoaderState, progress: number): number {
  if (state === "ready" || state === "running" || state === "compiling") {return 100;}
  if (state === "downloading") {return clampPct(progress * 100);}
  return 0;
}

export function shouldReport(prev: number | null, next: number): boolean {
  const pct = clampPct(next);
  if (prev === null) {return true;}
  if (pct === prev) {return false;}
  if (pct === 0 || pct === 100) {return true;}
  return pct >= prev + 5;
}
