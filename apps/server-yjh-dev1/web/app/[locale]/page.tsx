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
import type { LoaderState } from "@/hooks/useGodotLoader";

type Translate = (key: string) => string;

// 연결 상태 표시 문구 — Home 본문 복잡도를 낮추기 위해 모듈 레벨 헬퍼로 뺐다.
function connLabel(status: HubStatus, t: Translate): string {
  if (status === "connecting") {return t("connection.connecting");}
  if (status === "offline") {return t("connection.offline");}
  return t("connection.connected");
}

// 로딩 진행 문구 — 같은 이유로 추출.
function loadLabel(state: LoaderState, pct: number, t: Translate): string {
  if (state === "ready") {return t("game.loading.ready");}
  if (state === "downloading") {return `${t("game.loading.downloading")} ${pct}%`;}
  if (state === "compiling") {return t("game.loading.compiling");}
  return t("game.loading.preparing");
}

export default function Home(): JSX.Element {
  const t = useTranslations();

  const {
    phase,
    name,
    setName,
    hub,
    loader,
    matchInfo,
    findRoom,
    start,
    backToIntro,
    leaveToLobby,
    matchEnd,
    errorToIntro,
  } = useGameFlow("dagul", t("intro.defaultPlayer"));

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

      {(phase === "lobby" || phase === "room") && !lost &&
        (loader.state === "ready" ? (
          // 완료 상태는 배지로 — 전체 폭 바가 한 줄을 차지하는 위화감 제거
          <div className="ready-badge">
            <span className="ready-dot" />
            {t("game.loading.ready")}
          </div>
        ) : (
          <div className="prefetch-strip">
            <span className="prefetch-txt">
              {loadLabel(loader.state, loadPct, t)}
            </span>
            <div className="bar-track">
              {/* 진행률은 동적 값 — width만 인라인 불가피 */}
              <div
                className="bar-fill"
                // eslint-disable-next-line react/forbid-dom-props -- 진행률 동적 값
                style={{ width: `${loadPct}%` }}
              />
            </div>
          </div>
        ))}

      {phase === "intro" && (
        <OfflinePhase
          nickname={name}
          onNameChange={setName}
          onConnect={findRoom}
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
