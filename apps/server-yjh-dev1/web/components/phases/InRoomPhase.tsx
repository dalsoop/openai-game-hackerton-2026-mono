/**
 * InRoomPhase 컴포넌트
 * 대기실 화면 (Room + 로딩 상태)
 */
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import Room from "@/components/Room";
import type { HubPlayer, LoaderResult } from "@/types";

interface InRoomPhaseProps {
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  loader: LoaderResult;
  onStartGame: () => void;
  onLeaveRoom: () => void;
}

export function InRoomPhase({
  players,
  you,
  isHost,
  loader,
  onStartGame,
  onLeaveRoom,
}: InRoomPhaseProps): JSX.Element {
  const t = useTranslations();

  return (
    <>
      <Room
        players={players}
        you={you}
        isHost={isHost}
        onStart={onStartGame}
        onLeave={onLeaveRoom}
      />
      {isHost && loader.state !== "ready" && (
        <div className="asset-note">{t("game.downloadingAsset")}</div>
      )}
    </>
  );
}
