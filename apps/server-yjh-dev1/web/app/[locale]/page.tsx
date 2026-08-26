"use client";
// 렌더 전용 — 페이즈 상태머신은 useGameFlow, 허브는 useHub, 로더는 useGodotLoader.
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { useGameFlowContext } from "@/hooks/GameFlowProvider";
import { ConnectionLostModal } from "@/components/ConnectionLostModal";
import { DeployReloadBanner } from "@/components/DeployReloadBanner";
import { shouldShowReconnect } from "@/lib/game-flow-state";
import {
  OfflinePhase,
  ConnectingPhase,
  LobbyPhase,
  InRoomPhase,
  PlayingPhase,
} from "@/components/phases";
import { asGameId } from "@/lib/games/catalog";
import { CONNECTION_CLASS, type HubStatus } from "@/types";

type Translate = (key: string) => string;

// 연결 상태 표시 문구 — Home 본문 복잡도를 낮추기 위해 모듈 레벨 헬퍼로 뺐다.
function connLabel(status: HubStatus, t: Translate): string {
  if (status === "connecting") {return t("connection.connecting");}
  if (status === "offline") {return t("connection.offline");}
  return t("connection.connected");
}

export default function Home(): JSX.Element {
  const t = useTranslations();

  const {
    phase,
    name,
    setName,
    resetName,
    hasSavedName,
    hub,
    loader,
    localPct,
    matchInfo,
    findRoom,
    start,
    backToIntro,
    leaveToLobby,
    matchEnd,
    errorToIntro,
    deployStale,
    reloadDeploy,
  } = useGameFlowContext();

  // 튕김·강퇴는 회색 캔버스 대신 재접속 모달만 보여 준다.
  const bounced = shouldShowReconnect(hub.status, phase, hub.dropReason);
  if (bounced) {
    return (
      <div className="page-shell">
        <header className="hero">
          <div className="logo-word">{t("logo.word")}</div>
        </header>
        <ConnectionLostModal
          reason={hub.dropReason ?? "offline"}
          onReconnect={hub.reconnectAfterDrop}
          onExit={backToIntro}
        />
      </div>
    );
  }

  if (phase === "playing") {
    return (
      <PlayingPhase
        game={asGameId(matchInfo.gameId ?? hub.gameId)}
        matchInfo={matchInfo}
        onMatchEnd={matchEnd}
        onError={errorToIntro}
      />
    );
  }

  return (
    <div className="page-shell">
      <header className="hero">
        <div className="logo-word">{t("logo.word")}</div>
        {phase !== "intro" && (
          <div className={CONNECTION_CLASS[hub.status]}>
            <span className="conn-dot" />
            <span className="conn-txt">{connLabel(hub.status, t)}</span>
            {hub.rttMs > 0 && (
              <span className="conn-ping">{t("connection.ping", { ms: hub.rttMs })}</span>
            )}
          </div>
        )}
      </header>

      <DeployReloadBanner visible={deployStale} onReload={reloadDeploy} />

      {phase === "intro" && (
        <OfflinePhase
          nickname={name}
          hasSavedName={hasSavedName}
          onNameChange={setName}
          onConnect={findRoom}
          onResetName={resetName}
        />
      )}

      {phase === "lobby" && hub.status !== "in-room" && (
        <div className="fade-in">
          {hub.resuming ? (
            <>
              <ConnectingPhase message={t("game.resuming")} />
              <div className="center-row">
                <button
                  className="btn-text"
                  onClick={() => {
                    backToIntro();
                  }}
                >
                  {t("game.startFresh")}
                </button>
              </div>
            </>
          ) : (
            <LobbyPhase
              rooms={hub.rooms}
              status={hub.status}
              myRoom={hub.myRoom}
              onJoinRoom={hub.joinRoom}
              onRefresh={hub.refreshRooms}
              onBackToIntro={backToIntro}
            />
          )}
        </div>
      )}

      {phase === "room" && hub.status === "in-room" && (
        <InRoomPhase
          roomOpen={hub.roomOpen}
          onToggleRoom={hub.toggleRoom}
          gameId={hub.gameId}
          idleLeftSec={hub.idleLeftSec}
          onSetGame={hub.setGame}
          players={hub.players}
          you={hub.you}
          isHost={hub.isHost}
          localPct={localPct}
          canStart={loader.state === "ready"}
          onStartGame={start}
          onLeaveRoom={leaveToLobby}
        />
      )}
    </div>
  );
}
