"use client";
// 렌더 전용 — 페이즈 상태머신은 useGameFlow, 허브는 useHub, 로더는 useGodotLoader.
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { useGameFlow } from "@/hooks/useGameFlow";
import { ConnectionLostModal } from "@/components/ConnectionLostModal";
import { shouldShowConnectionLost } from "@/lib/game-flow-state";
import {
  OfflinePhase,
  ConnectingPhase,
  LobbyPhase,
  InRoomPhase,
  PlayingPhase,
} from "@/components/phases";
import { CONNECTION_CLASS, type HubStatus } from "@/types";
import { PrefetchStatus } from "@/components/PrefetchStatus";

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
    matchInfo,
    findRoom,
    start,
    backToIntro,
    leaveToLobby,
    matchEnd,
    errorToIntro,
  } = useGameFlow(t("intro.defaultPlayer"));

  // 끊김 판정은 페이즈보다 먼저 — 게임 중에도 진행을 막는다.
  const lost = shouldShowConnectionLost(hub.status, phase);
  const lostModal = lost ? (
    <ConnectionLostModal onReconnect={findRoom} onExit={backToIntro} />
  ) : null;

  if (phase === "playing") {
    return (
      <>
        {/* inert — 서버가 죽었으면 게임도 조작 불가. 모달로 재접속/복귀만 허용 */}
        <div inert={lost}>
          <PlayingPhase
            game="dagul"
            matchInfo={matchInfo}
            onMatchEnd={matchEnd}
            onError={errorToIntro}
          />
        </div>
        {lostModal}
      </>
    );
  }

  const loadPct = Math.round(loader.progress * 100);

  return (
    <div className="page-shell" inert={lost}>
      <header className="hero">
        <div className="logo-word">{t("logo.word")}</div>
        {phase !== "intro" && (
          <div className={CONNECTION_CLASS[hub.status]}>
            <span className="conn-dot" />
            <span className="conn-txt">{connLabel(hub.status, t)}</span>
          </div>
        )}
      </header>

      {lostModal}

      {(phase === "lobby" || phase === "room") && !lost && (
        <PrefetchStatus state={loader.state} pct={loadPct} />
      )}

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
                    hub.leaveRoom();
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
              onCreateRoom={hub.createRoom}
              onJoinRoom={hub.joinRoom}
              onRefresh={hub.refreshRooms}
              onBackToIntro={backToIntro}
            />
          )}
        </div>
      )}

      {phase === "room" && (
        <InRoomPhase
          roomOpen={hub.roomOpen}
          onToggleRoom={hub.toggleRoom}
          players={hub.players}
          you={hub.you}
          isHost={hub.isHost}
          loader={loader}
          onStartGame={start}
          onLeaveRoom={leaveToLobby}
        />
      )}
    </div>
  );
}
