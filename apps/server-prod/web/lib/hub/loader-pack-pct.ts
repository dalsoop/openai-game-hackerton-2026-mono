import type { LoaderState } from "../../types";
import { clampPackPct } from "../domain/roster";

export function packPctFromLoader(state: LoaderState, progress: number): number {
  if (state === "ready" || state === "running" || state === "compiling") {return 100;}
  if (state === "downloading") {return clampPackPct(progress * 100);}
  return 0;
}

/** 매치 부팅 오버레이 — 런타임이 올린 0..1 진행률만 보여 준다. ready 를 100 으로 접지 않는다. */
export function bootOverlayPct(progress: number): number {
  return clampPackPct(progress * 100);
}
