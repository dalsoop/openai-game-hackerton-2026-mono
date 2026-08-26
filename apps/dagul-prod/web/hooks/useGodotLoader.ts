"use client";
// GodotRuntime 구독 어댑터 — 로딩 상태를 React 상태로 노출만 한다.
// 실제 다운로드/컴파일/부팅은 lib/godot/runtime.ts 의 GodotRuntime 이 소유한다.
import { useEffect, useState, useCallback } from "react";
import { GodotRuntime, type RuntimeSnapshot } from "@/lib/godot/runtime";
import type { GameId } from "@/lib/games/catalog";

export type LoaderState = RuntimeSnapshot["state"];

export function useGodotLoader(game: GameId): RuntimeSnapshot & { start: () => void } {
  const runtime = GodotRuntime.for(game);
  const [snap, setSnap] = useState<RuntimeSnapshot>(runtime.snapshot);

  useEffect(() => runtime.subscribe(setSnap), [runtime]);

  const start = useCallback(() => {
    void runtime.preload();
  }, [runtime]);

  return { ...snap, start };
}
