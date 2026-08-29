"use client";
// GodotRuntime 구독 어댑터 — 로딩 상태를 React 상태로 노출만 한다.
// 실제 다운로드/컴파일/부팅은 lib/godot/runtime.ts 의 GodotRuntime 이 소유한다.
import { useEffect, useState, useCallback, useRef } from "react";
import { GodotRuntime, type RuntimeSnapshot } from "@/lib/godot/runtime";
import type { GameId } from "@/lib/games/catalog";

export type LoaderState = RuntimeSnapshot["state"];

function reportLoadTime(startMs: number): void {
  const ms = Math.round(performance.now() - startMs);
  if (ms <= 0) { return; }
  fetch("/api/load-time", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ ms }),
  }).catch(() => {});
}

export function useGodotLoader(game: GameId): RuntimeSnapshot & { start: () => void } {
  const runtime = GodotRuntime.for(game);
  const [snap, setSnap] = useState<RuntimeSnapshot>(runtime.snapshot);
  const loadStartRef = useRef(0);
  const reportedRef = useRef(false);

  useEffect(() => runtime.subscribe(setSnap), [runtime]);

  useEffect(() => {
    if (snap.state === "downloading" && loadStartRef.current === 0) {
      loadStartRef.current = performance.now();
      reportedRef.current = false;
    }
    if (snap.state === "ready" && loadStartRef.current > 0 && !reportedRef.current) {
      reportLoadTime(loadStartRef.current);
      reportedRef.current = true;
      loadStartRef.current = 0;
    }
  }, [snap.state]);

  const start = useCallback(() => {
    void runtime.preload();
  }, [runtime]);

  return { ...snap, start };
}
