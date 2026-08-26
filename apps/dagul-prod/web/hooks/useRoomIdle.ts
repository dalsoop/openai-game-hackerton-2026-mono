"use client";
import { useEffect, useState } from "react";
import { idleLeftFromUntil, nowUnixSec } from "@/lib/hub/lobby-idle";

/** 서버 idleUntilSec(unix 초) 기준 남은 초. 백그라운드 탭은 복귀 때 다시 읽는다. */
export function useRoomIdle(idleUntilSec: number, active: boolean): number {
  const [nowSec, setNowSec] = useState(nowUnixSec);
  useEffect(() => {
    if (!active || idleUntilSec <= 0) {return;}
    const tick = (): void => {setNowSec(nowUnixSec());};
    const id = setInterval(tick, 1000);
    const onVis = (): void => {
      if (document.visibilityState === "visible") {tick();}
    };
    document.addEventListener("visibilitychange", onVis);
    return (): void => {
      clearInterval(id);
      document.removeEventListener("visibilitychange", onVis);
    };
  }, [active, idleUntilSec]);
  if (!active || idleUntilSec <= 0) {return 0;}
  return idleLeftFromUntil(idleUntilSec, nowSec);
}
