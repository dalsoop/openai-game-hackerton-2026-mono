/**
 * LobbyPhase 컴포넌트
 * 로비 화면 (방 목록 + 뒤로가기)
 * 연결 끊김(offline) 표기는 ConnectionLostModal 이 소유한다 — 여기서 다루지 않는다.
 * 연결 중에도 뒤로가기는 남겨 둔다 — 리스트 룸이 늦어도 인트로로 빠져나올 수 있게.
 */
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import Lobby from "@/components/Lobby";
import { MaterialIcon } from "@/components/MaterialIcon";
import { ConnectingPhase } from "./ConnectingPhase";
import type { HubRoom, HubStatus } from "@/types";
import type { MyRoomIdentity } from "@/lib/room-membership";
import type { CcuSnapshot } from "@/lib/hub/ccu-plan";

interface LobbyPhaseProps {
  rooms: HubRoom[];
  status: HubStatus;
  myRoom: MyRoomIdentity | null;
  onJoinRoom: (id: string) => void;
  onForgetMyRoom: () => void;
  onRefresh: () => void;
  refreshing?: boolean;
  onBackToIntro: () => void;
  connClass: string;
  connText: string;
  rttMs: number;
  rttText: string | null;
  ccu?: CcuSnapshot | null;
}

export function LobbyPhase({
  rooms,
  status,
  myRoom,
  onJoinRoom,
  onForgetMyRoom,
  onRefresh,
  refreshing = false,
  onBackToIntro,
  connClass,
  connText,
  rttMs,
  rttText,
  ccu = null,
}: LobbyPhaseProps): JSX.Element {
  const t = useTranslations();

  return (
    <div className="fade-in">
      <div className="back-row">
        <button type="button" className="ghost btn-icon" onClick={onBackToIntro} aria-label={t("game.back")}>
          <MaterialIcon name="undo" />
        </button>
        <div className={connClass}>
          <span className="conn-dot" />
          <span className="conn-txt">{connText}</span>
          {rttMs > 0 && rttText && (
            <span className="conn-ping">{rttText}</span>
          )}
        </div>
      </div>

      {status === "connecting" ? (
        <ConnectingPhase />
      ) : (
        <Lobby
          rooms={rooms}
          myRoom={myRoom}
          onJoin={onJoinRoom}
          onForgetMyRoom={onForgetMyRoom}
          onRefresh={onRefresh}
          refreshing={refreshing}
          ccu={ccu}
        />
      )}
    </div>
  );
}
