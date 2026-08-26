"use client";
import { useEffect } from "react";
import { downloadStartsInRoom } from "@/lib/game-flow-state";
import { pctFromLoader } from "@/lib/hub/download-progress";
import type { GamePhase, LoaderState } from "@/types";

type Loader = {
  state: LoaderState;
  progress: number;
  start: () => void;
};

export function useRoomAssets(
  phase: GamePhase,
  loader: Loader,
  reportDownload: (pct: number) => void,
): { localPct: number } {
  const startDownload = loader.start;
  const localPct = pctFromLoader(loader.state, loader.progress);

  useEffect(() => {
    if (downloadStartsInRoom(phase)) {startDownload();}
  }, [phase, startDownload]);

  useEffect(() => {
    if (!downloadStartsInRoom(phase)) {return;}
    reportDownload(localPct);
  }, [phase, localPct, reportDownload]);

  return { localPct };
}
