"use client";
// 렌더 전용: 캔버스 + 오버레이. 수명주기는 useGodotMatch(어댑터)·GodotRuntime(클래스)이 소유한다.
import type { JSX } from "react";
import { GodotRuntime } from "@/lib/godot/runtime";
import { asGameId } from "@/lib/games/catalog";
import { runtimeErrorText } from "@/lib/godot/runtime-errors";
import { bootOverlayPct } from "@/lib/hub/loader-pack-pct";
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

export default function GodotCanvas({ game, matchInfo, visible, onMatchEnd, onError }: GodotCanvasProps): JSX.Element | null {
  // 런타임 오류 키는 game.errors.* (정본). godot 네임스페이스에서 읽으면
  // godot.game.errors.matchSignalMissing 같은 깨진 경로가 그대로 보인다.
  const t = useTranslations();
  const { canvasRef, snap } = useGodotMatch({ game, matchInfo, visible, onMatchEnd });

  if (!visible) {return null;}

  const booting = snap.state !== "running" && snap.state !== "error";
  const pct = bootOverlayPct(snap.progress);
  const errorText = runtimeErrorText(snap.error ?? "", t);

  return (
    <div className="gc-overlay">
      <canvas ref={canvasRef} id="canvas" className="gc-canvas" tabIndex={0} />
      {booting && (
        <div className="gc-booting">
          <div className="gc-boot-pct">{t("godot.loadingPct", { pct })}</div>
          <div
            className="gc-boot-bar"
            role="progressbar"
            aria-valuemin={0}
            aria-valuemax={100}
            aria-valuenow={pct}
            aria-label={t("godot.loadingPct", { pct })}
          >
            <div
              className="gc-boot-bar-fill"
              // eslint-disable-next-line react/forbid-dom-props -- 진행률 동적 값
              style={{ width: `${pct}%` }}
            />
          </div>
        </div>
      )}
      {snap.state === "error" && (
        <div className="gc-error-box">
          <div className="gc-error-msg">
            {errorText}
          </div>
          <button
            className="ghost"
            onClick={() => {
              GodotRuntime.for(asGameId(game)).resetError();
              onError?.();
            }}
          >
            {t("godot.backToLobby")}
          </button>
        </div>
      )}
    </div>
  );
}
