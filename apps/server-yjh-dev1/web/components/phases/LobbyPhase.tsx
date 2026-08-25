/**
 * LobbyPhase 컴포넌트
 * 로비 화면 (방 목록 + 뒤로가기)
 * 연결 끊김(offline) 표기는 ConnectionLostModal 이 소유한다 — 여기서 다루지 않는다.
 */
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { Button } from "@/components/ui";
import Lobby from "@/components/Lobby";
import { ConnectingPhase } from "./ConnectingPhase";
import type { HubRoom, HubStatus } from "@/types";
import type { MyRoomIdentity } from "@/lib/room-membership";

interface LobbyPhaseProps {
  rooms: HubRoom[];
  status: HubStatus;
  myRoom: MyRoomIdentity | null;
  onCreateRoom: (game: string) => void;
  onJoinRoom: (id: string) => void;
  onRefresh: () => void;
  onBackToIntro: () => void;
}

export function LobbyPhase({
  rooms,
  status,
  myRoom,
  onCreateRoom,
  onJoinRoom,
  onRefresh,
  onBackToIntro,
}: LobbyPhaseProps): JSX.Element {
  const t = useTranslations();

  if (status === "connecting") {
    return <ConnectingPhase />;
  }

  return (
    <div className="fade-in">
      <div className="back-row">
        <Button variant="ghost" size="sm" onClick={onBackToIntro}>
          ← {t("game.back")}
        </Button>
      </div>

      <Lobby
        rooms={rooms}
        myRoom={myRoom}
        onCreate={onCreateRoom}
        onJoin={onJoinRoom}
        onRefresh={onRefresh}
      />
    </div>
  );
}
