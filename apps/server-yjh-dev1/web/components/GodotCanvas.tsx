"use client";
// 렌더 전용: 캔버스 + 오버레이. 수명주기는 useGodotMatch(어댑터)·GodotRuntime(클래스)이 소유한다.
import type { JSX } from "react";
import { GodotRuntime } from "@/lib/godot/runtime";
import { runtimeErrorKey } from "@/lib/godot/runtime-errors";
import { useGodotMatch } from "@/hooks/useGodotMatch";
import { useTranslations } from "next-intl";
import type { MatchInfo } from "@/types";

export type { MatchInfo } from "@/types";

interface GodotCanvasProps {
  game: string;
  matchInfo: MatchInfo;
  visible: boolean;
  onMatchEnd?: (detail: Record<string, unknown>) => void;
  onError?: () => void;
}

export default function GodotCanvas({ matchInfo, visible, onMatchEnd, onError }: GodotCanvasProps): JSX.Element | null {
  const t = useTranslations("godot");
  const { canvasRef, snap } = useGodotMatch({ matchInfo, visible, onMatchEnd });

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
