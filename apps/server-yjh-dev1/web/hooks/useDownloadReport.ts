"use client";
import { useCallback, useEffect, useRef } from "react";
import type { Room } from "@colyseus/sdk";
import { MSG } from "@/lib/contract";
import { clampPct } from "@/lib/domain/download";
import { shouldReport } from "@/lib/hub/download-progress";

export function useDownloadReport(room: Room | undefined, resetKey: string): (pct: number) => void {
  const last = useRef<number | null>(null);
  useEffect(() => {
    last.current = null;
  }, [resetKey]);
  return useCallback((pct: number) => {
    const next = clampPct(pct);
    if (!shouldReport(last.current, next)) {return;}
    last.current = next;
    room?.send(MSG.DL, { pct: next });
  }, [room]);
}
