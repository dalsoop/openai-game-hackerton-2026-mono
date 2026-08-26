"use client";
import { useCallback, useEffect, useState } from "react";
import { VERSION_PATH, pinOrDetectStale, revisionIdOf } from "@/lib/hub/revision";

export const REVISION_INTERVAL_MS = 30 * 60 * 1000;
export const REVISION_MIN_GAP_MS = 60 * 1000;
export const REVISION_DEV_INTERVAL_MS = 5_000;
export const REVISION_DEV_MIN_GAP_MS = 2_000;

export interface DeployRevisionOptions {
  enabled?: boolean;
  fetchImpl?: typeof fetch;
  now?: () => number;
}

export function revisionWatchMs(
  env = process.env.NODE_ENV,
): { interval: number; minGap: number } {
  if (env === "production") {
    return { interval: REVISION_INTERVAL_MS, minGap: REVISION_MIN_GAP_MS };
  }
  return { interval: REVISION_DEV_INTERVAL_MS, minGap: REVISION_DEV_MIN_GAP_MS };
}

export async function fetchRemoteRevision(
  fetchImpl: typeof fetch = fetch,
): Promise<string> {
  const res = await fetchImpl(VERSION_PATH, { cache: "no-store" });
  if (!res.ok) {return "";}
  return revisionIdOf(await res.json());
}

export function useDeployRevision(
  currentId: string,
  options: DeployRevisionOptions = {},
): { stale: boolean; reload: () => void } {
  const enabled = options.enabled ?? true;
  const [stale, setStale] = useState(false);

  const reload = useCallback((): void => {
    window.location.reload();
  }, []);

  useEffect(() => {
    if (!enabled || stale) {return;}

    const fetchImpl = options.fetchImpl ?? fetch;
    const now = options.now ?? Date.now;
    const watch = revisionWatchMs();
    let cancelled = false;
    let last = 0;
    let inFlight = false;
    let pinned = currentId;

    async function check(): Promise<void> {
      const t = now();
      if (inFlight || t - last < watch.minGap) {return;}
      inFlight = true;
      last = t;
      try {
        const remote = await fetchRemoteRevision(fetchImpl);
        if (cancelled) {return;}
        const next = pinOrDetectStale(pinned, remote);
        pinned = next.pin;
        if (next.stale) {setStale(true);}
      } catch {
        // 네트워크 순간 오류 — 다음 트리거에서 다시 본다.
      } finally {
        inFlight = false;
      }
    }

    function onVisible(): void {
      if (document.visibilityState === "visible") {void check();}
    }

    void check();
    document.addEventListener("visibilitychange", onVisible);
    window.addEventListener("focus", onVisible);
    const interval = setInterval(() => { void check(); }, watch.interval);
    return (): void => {
      cancelled = true;
      document.removeEventListener("visibilitychange", onVisible);
      window.removeEventListener("focus", onVisible);
      clearInterval(interval);
    };
  }, [currentId, enabled, stale, options.fetchImpl, options.now]);

  return { stale, reload };
}
