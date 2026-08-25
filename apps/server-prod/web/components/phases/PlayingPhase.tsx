/**
 * PlayingPhase 컴포넌트
 * 게임 실행 페이즈 (GodotCanvas 래퍼)
 */
import type { JSX } from "react";
import GodotCanvas from "@/components/GodotCanvas";
import type { MatchInfo } from "@/types";

interface PlayingPhaseProps {
  game: string;
  matchInfo: MatchInfo;
  onMatchEnd: (detail: Record<string, unknown>) => void;
  onError: () => void;
}

export function PlayingPhase({
  game,
  matchInfo,
  onMatchEnd,
  onError,
}: PlayingPhaseProps): JSX.Element {
  return (
    <GodotCanvas
      visible
      game={game}
      matchInfo={matchInfo}
      onMatchEnd={onMatchEnd}
      onError={onError}
    />
  );
}
