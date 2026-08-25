"use client";
// 렌더 전용: 캔버스 + 오버레이. 수명주기는 GodotRuntime 이 소유한다.
import type { JSX } from "react";
import { useEffect, useRef, useState } from "react";
import { GodotRuntime, type HandoffInfo, type RuntimeSnapshot } from "@/lib/godot/runtime";
import { DOM_EVT } from "@/lib/hub/config";
import { runtimeErrorKey } from "@/lib/godot/runtime-errors";
import { useTranslations } from "next-intl";

export type MatchInfo = HandoffInfo;

interface GodotCanvasProps {
  game: string;
  matchInfo: MatchInfo;
  visible: boolean;
  onMatchEnd?: (detail: Record<string, unknown>) => void;
  onError?: () => void;
}

export default function GodotCanvas({ matchInfo, visible, onMatchEnd, onError }: GodotCanvasProps): JSX.Element | null {
  const t = useTranslations("godot");
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

  if (!visible) {return null;}

  const booting = snap.state !== "running" && snap.state !== "error";

  return (
    <div className="gc-overlay">
      <canvas ref={canvasRef} id="godot-canvas" className="gc-canvas" tabIndex={0} />
      {booting && (
        <div className="gc-booting">
          <div>{t("starting")}</div>
          <div className="gc-boot-sub">{t("loadingEngine")}</div>
        </div>
      )}
      {snap.state === "error" && (
        <div className="gc-error-box">
          <div className="gc-error-msg">
            {t("startError")}: {t(runtimeErrorKey(snap.error ?? ""))}
          </div>
          <button
            className="ghost"
            onClick={() => {
              GodotRuntime.instance.resetError();
              onError?.();
            }}
          >
            {t("backToLobby")}
          </button>
        </div>
      )}
    </div>
  );
}
