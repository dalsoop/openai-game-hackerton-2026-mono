"use client";
// Godot 매치 어댑터 훅 — 캔버스 수명주기·런타임 구독·매치 종료 이벤트를 소유한다.
// GodotCanvas(뷰)는 이 훅이 내려주는 ref·스냅샷만 소비한다 (컴포넌트 훅 금지 규칙).
import { useEffect, useRef, useState } from "react";
import { GodotRuntime, type RuntimeSnapshot } from "@/lib/godot/runtime";
import { asGameId } from "@/lib/games/catalog";
import { DOM_EVT } from "@/lib/contract";
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
  const [snap, setSnap] = useState<RuntimeSnapshot>(runtime.snapshot);

  useEffect(() => runtime.subscribe(setSnap), [runtime]);

  useEffect(() => {
    if (!visible || !canvasRef.current) {return;}
    const token = ++hold.current;
    void runtime.boot(canvasRef.current, matchInfo).catch(() => {
      // 부팅 실패는 runtime 상태(error)로 전파된다.
    });
    // StrictMode 동기 리마운트에서는 바로 quit 하지 않는다 — 매치 키·워치독이 한 번만 살아 있게.
    return (): void => {
      const generation = token;
      queueMicrotask(() => {
        // 최신 generation 만 유지 — 과거 이펙트의 quit 는 버린다.
        // eslint-disable-next-line react-hooks/exhaustive-deps -- hold.current 는 의도적으로 늦게 읽는다
        if (hold.current === generation) {runtime.quit();}
      });
    };
  }, [visible, runtime]); // eslint-disable-line react-hooks/exhaustive-deps -- matchInfo는 최초 부팅에만 쓰인다

  useEffect(() => {
    if (!onMatchEnd) {return;}
    const handler = (e: Event): void => {
      runtime.quit();
      onMatchEnd((e as CustomEvent).detail ?? {});
    };
    window.addEventListener(DOM_EVT.MATCH_END, handler);
    return (): void => window.removeEventListener(DOM_EVT.MATCH_END, handler);
  }, [onMatchEnd, runtime]);

  return { canvasRef, snap };
}
