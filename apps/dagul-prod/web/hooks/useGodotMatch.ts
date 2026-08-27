"use client";
// Godot 매치 어댑터 훅 — 캔버스 수명주기·런타임 구독·매치 종료 이벤트를 소유한다.
// GodotCanvas(뷰)는 이 훅이 내려주는 ref·스냅샷만 소비한다 (컴포넌트 훅 금지 규칙).
import { useEffect, useRef, useState } from "react";
import { GodotRuntime, type RuntimeSnapshot } from "@/lib/godot/runtime";
import { lockPlayViewport } from "@/lib/godot/canvas-focus";
import { asGameId } from "@/lib/games/catalog";
import { DOM_EVT, MSG } from "@/lib/contract";
import { encodeBridgePacket, freezeMatchEndDetail } from "@/lib/hub/page-bridge";
import type { MatchInfo } from "@/types";

interface UseGodotMatchOptions {
  game: string;
  matchInfo: MatchInfo;
  visible: boolean;
  onMatchEnd?: (detail: Record<string, unknown>) => void;
}

export function useGodotMatch({ game, matchInfo, visible, onMatchEnd }: UseGodotMatchOptions): {
  canvasRef: React.RefObject<HTMLCanvasElement | null>;
  snap: RuntimeSnapshot;
} {
  const runtime = GodotRuntime.for(asGameId(game));
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const hold = useRef(0);
  const ended = useRef(false);
  const [snap, setSnap] = useState<RuntimeSnapshot>(runtime.snapshot);

  useEffect(() => runtime.subscribe(setSnap), [runtime]);

  useEffect(() => {
    if (!visible) {ended.current = false; return;}
    if (ended.current || !matchInfo.match || !canvasRef.current) {return;}
    const token = ++hold.current;
    const unlockViewport = lockPlayViewport();
    void runtime.boot(canvasRef.current, { ...matchInfo, game }).catch(() => {
      // 부팅 실패는 runtime 상태(error)로 전파된다.
    });
    return (): void => {
      unlockViewport();
      const generation = token;
      queueMicrotask(() => {
        // eslint-disable-next-line react-hooks/exhaustive-deps -- hold.current 는 의도적으로 늦게 읽는다
        if (hold.current === generation) {runtime.quit();}
      });
    };
  }, [visible, runtime, matchInfo, game]);

  useEffect(() => {
    const handler = (e: Event): void => {
      ended.current = true;
      window.dispatchEvent(new CustomEvent(DOM_EVT.FROM_ENGINE, {
        detail: encodeBridgePacket(MSG.SNAP_ON, {}),
      }));
      runtime.quit();
      onMatchEnd?.(freezeMatchEndDetail((e as CustomEvent).detail ?? {}));
    };
    window.addEventListener(DOM_EVT.MATCH_END, handler);
    return (): void => window.removeEventListener(DOM_EVT.MATCH_END, handler);
  }, [onMatchEnd, runtime]);

  return { canvasRef, snap };
}
