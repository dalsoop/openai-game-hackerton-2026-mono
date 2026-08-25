/**
 * LobbyPhase 컴포넌트
 * 로비 화면 (방 목록 + 뒤로가기)
 */
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { Button, StatusMessage } from "@/components/ui";
import Lobby from "@/components/Lobby";
import { ConnectingPhase } from "./ConnectingPhase";
import type { HubRoom, HubStatus } from "@/types";

interface LobbyPhaseProps {
  rooms: HubRoom[];
  status: HubStatus;
  onCreateRoom: () => void;
  onJoinRoom: (id: string) => void;
  onRefresh: () => void;
  onBackToIntro: () => void;
  onReconnect: () => void;
}

export function LobbyPhase({
  rooms,
  status,
  onCreateRoom,
  onJoinRoom,
  onRefresh,
  onBackToIntro,
  onReconnect,
}: LobbyPhaseProps): JSX.Element {
  const t = useTranslations();

  if (status === "connecting") {
    return <ConnectingPhase />;
  }

  if (status === "offline") {
    return (
      <div className="fade-in">
        <StatusMessage variant="error">
          {t("game.serverConnectFailed")}
          <br />
          <Button className="ghost" onClick={onReconnect}>
            {t("game.reconnect")}
          </Button>
        </StatusMessage>
      </div>
    );
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
        onCreate={onCreateRoom}
        onJoin={onJoinRoom}
        onRefresh={onRefresh}
      />
    </div>
  );
}
