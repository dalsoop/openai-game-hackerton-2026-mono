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
  roomOpen: boolean;
  loader: LoaderResult;
  onStartGame: () => void;
  onLeaveRoom: () => void;
  onToggleRoom: () => void;
}

export function InRoomPhase({
  players,
  you,
  isHost,
  roomOpen,
  loader,
  onStartGame,
  onLeaveRoom,
  onToggleRoom,
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
        canStart={loader.state === "ready"}
      />
      {isHost && (
        <button className="ghost btn-sm" onClick={onToggleRoom}>
          {roomOpen ? t("room.close") : t("room.open")}
        </button>
      )}
      {loader.state !== "ready" && (
        <div className="room-download">
          <div className="dl-label">{t("room.downloading")}</div>
          <div className="bar-track">
            {/* eslint-disable-next-line react/forbid-dom-props -- 진행률은 동적 폭 */}
            <div className="bar-fill" style={{ width: `${Math.round(loader.progress * 100)}%` }} />
          </div>
          <div className="dl-pct">{Math.round(loader.progress * 100)}%</div>
        </div>
      )}
    </>
  );
}
