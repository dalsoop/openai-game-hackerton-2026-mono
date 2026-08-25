"use client";
// GodotRuntime 구독 어댑터 — 로딩 상태를 React 상태로 노출만 한다.
// 실제 다운로드/컴파일/부팅은 lib/godot/runtime.ts 의 GodotRuntime 이 소유한다.
import { useEffect, useState, useCallback } from "react";
import { GodotRuntime, type RuntimeSnapshot } from "@/lib/godot/runtime";

export type LoaderState = RuntimeSnapshot["state"];

export function useGodotLoader(_game: string): RuntimeSnapshot & { start: () => void } {
  const [snap, setSnap] = useState<RuntimeSnapshot>(GodotRuntime.instance.snapshot);

  useEffect(() => GodotRuntime.instance.subscribe(setSnap), []);

  const start = useCallback(() => {
    void GodotRuntime.instance.preload();
  }, []);

  return { ...snap, start };
}
