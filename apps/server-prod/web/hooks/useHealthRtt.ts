"use client";
// 리스트 룸은 ping 을 받지 않는다. 로비에서는 /health 왕복으로 지연을 본다.
import { useEffect, useState } from "react";
import { HUB_CONFIG } from "@/lib/hub/config";

export async function measureHealthRtt(now = Date.now, fetchImpl: typeof fetch = fetch): Promise<number | null> {
  const t0 = now();
  const res = await fetchImpl("/health", { cache: "no-store" });
  if (!res.ok) {return null;}
  return Math.max(0, now() - t0);
}

export function useHealthRtt(active: boolean): number {
  const [rttMs, setRttMs] = useState(0);
  useEffect(() => {
    if (!active) {return;}
    let alive = true;
    const beat = (): void => {
      void measureHealthRtt().then((next) => {
        if (alive && next !== null) {setRttMs(next);}
      });
    };
    beat();
    const id = setInterval(beat, HUB_CONFIG.rttIntervalMs);
    return (): void => {alive = false; clearInterval(id);};
  }, [active]);
  return active ? rttMs : 0;
}
