import type { LoaderState } from "@/types";
import { clampPackPct } from "@dalsoop/hub-kernel";

export function packPctFromLoader(state: LoaderState, progress: number): number {
  if (state === "ready" || state === "running" || state === "compiling") {return 100;}
  if (state === "downloading") {return clampPackPct(progress * 100);}
  return 0;
}
