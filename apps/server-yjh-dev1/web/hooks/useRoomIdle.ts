"use client";
import { useEffect, useState } from "react";
import { HUB_CONFIG } from "@/lib/hub/config";
import { idleLeftSec } from "@/lib/hub/lobby-idle";

export function useRoomIdle(createdAtMs: number, active: boolean): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    if (!active || createdAtMs <= 0) {return;}
    const id = setInterval(() => {setNow(Date.now());}, 1000);
    return (): void => {clearInterval(id);};
  }, [active, createdAtMs]);
  if (!active || createdAtMs <= 0) {return 0;}
  return idleLeftSec(createdAtMs, now);
}

export function idleBudgetSec(): number {
  return Math.floor(HUB_CONFIG.idleStartMs / 1000);
}
