"use client";
import { useEffect } from "react";
import { packLoadStartsInRoom } from "@/lib/game-flow-state";
import { packPctFromLoader } from "@/lib/hub/loader-pack-pct";
import type { GamePhase, LoaderState } from "@/types";

type Loader = {
  state: LoaderState;
  progress: number;
  start: () => void;
};

export function useWaitingRoomPack(
  phase: GamePhase,
  loader: Loader,
  sendPackPct: (pct: number) => void,
): { ownPackPct: number } {
  const startPackLoad = loader.start;
  const ownPackPct = packPctFromLoader(loader.state, loader.progress);

  useEffect(() => {
    if (packLoadStartsInRoom(phase)) {startPackLoad();}
  }, [phase, startPackLoad]);

  useEffect(() => {
    if (!packLoadStartsInRoom(phase)) {return;}
    sendPackPct(ownPackPct);
  }, [phase, ownPackPct, sendPackPct]);

  return { ownPackPct };
}
