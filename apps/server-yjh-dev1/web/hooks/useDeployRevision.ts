"use client";
import { useCallback, useEffect, useState } from "react";
import { VERSION_PATH, isStaleRevision, revisionIdOf } from "@/lib/hub/revision";

export const REVISION_INTERVAL_MS = 30 * 60 * 1000;
export const REVISION_MIN_GAP_MS = 60 * 1000;

export interface DeployRevisionOptions {
  enabled?: boolean;
  fetchImpl?: typeof fetch;
  now?: () => number;
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
  const enabled = options.enabled ?? currentId !== "";
  const [stale, setStale] = useState(false);

  const reload = useCallback((): void => {
    window.location.reload();
  }, []);

  useEffect(() => {
    if (!enabled || currentId === "" || stale) {return;}

    const fetchImpl = options.fetchImpl ?? fetch;
    const now = options.now ?? Date.now;
    let cancelled = false;
    let last = -REVISION_MIN_GAP_MS;
    let inFlight = false;

    async function check(): Promise<void> {
      const t = now();
      if (inFlight || t - last < REVISION_MIN_GAP_MS) {return;}
      inFlight = true;
      last = t;
      try {
        const remote = await fetchRemoteRevision(fetchImpl);
        if (!cancelled && isStaleRevision(currentId, remote)) {setStale(true);}
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
    const interval = setInterval(() => { void check(); }, REVISION_INTERVAL_MS);
    return (): void => {
      cancelled = true;
      document.removeEventListener("visibilitychange", onVisible);
      window.removeEventListener("focus", onVisible);
      clearInterval(interval);
    };
  }, [currentId, enabled, stale, options.fetchImpl, options.now]);

  return { stale, reload };
}
