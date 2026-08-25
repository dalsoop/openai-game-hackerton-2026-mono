"use client";
// Godot 매치 어댑터 훅 — 캔버스 수명주기·런타임 구독·매치 종료 이벤트를 소유한다.
// GodotCanvas(뷰)는 이 훅이 내려주는 ref·스냅샷만 소비한다 (컴포넌트 훅 금지 규칙).
import { useEffect, useRef, useState } from "react";
import { GodotRuntime, type RuntimeSnapshot } from "@/lib/godot/runtime";
import { DOM_EVT } from "@/lib/hub/config";
import type { MatchInfo } from "@/types";

interface UseGodotMatchOptions {
  matchInfo: MatchInfo;
  visible: boolean;
  onMatchEnd?: (detail: Record<string, unknown>) => void;
}

export function useGodotMatch({ matchInfo, visible, onMatchEnd }: UseGodotMatchOptions): {
  canvasRef: React.RefObject<HTMLCanvasElement | null>;
  snap: RuntimeSnapshot;
} {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [snap, setSnap] = useState<RuntimeSnapshot>(GodotRuntime.instance.snapshot);

  useEffect(() => GodotRuntime.instance.subscribe(setSnap), []);

  useEffect(() => {
    if (!visible || !canvasRef.current) {return;}
    void GodotRuntime.instance.boot(canvasRef.current, matchInfo).catch(() => {
      // 부팅 실패는 runtime 상태(error)로 전파된다.
    });
  }, [visible]); // eslint-disable-line react-hooks/exhaustive-deps -- matchInfo는 최초 부팅에만 쓰인다

  useEffect(() => {
    if (!onMatchEnd) {return;}
    const handler = (e: Event): void => {
      GodotRuntime.instance.quit();
      onMatchEnd((e as CustomEvent).detail ?? {});
    };
    window.addEventListener(DOM_EVT.MATCH_END, handler);
    return (): void => window.removeEventListener(DOM_EVT.MATCH_END, handler);
  }, [onMatchEnd]);

  useEffect((): (() => void) => () => GodotRuntime.instance.quit(), []);

  return { canvasRef, snap };
}
