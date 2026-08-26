"use client";
import { useCallback, useEffect, useRef } from "react";
import type { Room } from "@colyseus/sdk";
import { MSG } from "@/lib/contract";
import { clampPackPct, shouldSendPackPct } from "@/lib/domain/waiting-room-pack";

export function useSendPackPct(room: Room | undefined, resetKey: string): (pct: number) => void {
  const last = useRef<number | null>(null);
  useEffect(() => {
    last.current = null;
  }, [resetKey]);
  return useCallback((pct: number) => {
    const next = clampPackPct(pct);
    if (!shouldSendPackPct(last.current, next)) {return;}
    last.current = next;
    room?.send(MSG.PACK_PCT, { pct: next });
  }, [room]);
}
