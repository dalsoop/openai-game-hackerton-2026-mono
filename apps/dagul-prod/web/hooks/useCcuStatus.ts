"use client";
import { useEffect, useState } from "react";
import { HUB_CONFIG } from "@/lib/hub/config";
import { congestionOf, type CcuSnapshot } from "@/lib/hub/ccu-plan";

function snapFromUnknown(raw: unknown): CcuSnapshot | null {
  if (!raw || typeof raw !== "object") {return null;}
  const ccu = Number((raw as { ccu?: unknown }).ccu);
  const cap = Number((raw as { cap?: unknown }).cap);
  if (!Number.isFinite(ccu) || !Number.isFinite(cap) || cap < 1) {return null;}
  return congestionOf(ccu, cap);
}

export async function fetchCcuSnapshot(
  fetchImpl: typeof fetch = fetch,
): Promise<CcuSnapshot | null> {
  const health = await fetchImpl("/health", { cache: "no-store" });
  if (health.ok) {
    const fromHealth = snapFromUnknown(await health.json());
    if (fromHealth) {return fromHealth;}
  }
  const ccuRes = await fetchImpl("/ccu", { cache: "no-store" });
  if (!ccuRes.ok) {return null;}
  return snapFromUnknown(await ccuRes.json());
}

export function useCcuStatus(active: boolean): CcuSnapshot | null {
  const [snap, setSnap] = useState<CcuSnapshot | null>(null);
  useEffect(() => {
    if (!active) {return;}
    let alive = true;
    const beat = (): void => {
      void fetchCcuSnapshot().then((next) => {
        if (alive && next) {setSnap(next);}
      }).catch(() => { /* 인트로는 배지 없이 시작 가능 */ });
    };
    beat();
    const id = setInterval(beat, HUB_CONFIG.listPollMs);
    return (): void => {alive = false; clearInterval(id);};
  }, [active]);
  return active ? snap : null;
}
