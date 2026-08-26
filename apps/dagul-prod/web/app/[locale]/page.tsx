"use client";
// 렌더 전용 — 페이즈 상태머신은 useGameFlow, 허브는 useHub, 로더는 useGodotLoader.
import type { JSX } from "react";
import { useLocale, useTranslations } from "next-intl";
import { usePathname, useRouter } from "@/i18n/routing";
import { useGameFlowContext } from "@/hooks/GameFlowProvider";
import { ConnectionLostModal } from "@/components/ConnectionLostModal";
import { DeployReloadBanner } from "@/components/DeployReloadBanner";
import { homeSurface } from "@/lib/game-flow-state";
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


function LocaleSwitch(): JSX.Element {
  const t = useTranslations("locale");
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();
  return (
    <select
      className="locale-select"
      value={locale}
      aria-label={t("label")}
      onChange={(e) => {
        router.replace(pathname, { locale: e.target.value });
      }}
    >
      <option value="ko">{t("ko")}</option>
      <option value="en">{t("en")}</option>
    </select>
  );
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
    ownPackPct,
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

  const surface = homeSurface(phase, hub.status, {
    joiningKind: hub.joiningKind,
    resuming: hub.resuming,
    dropReason: hub.dropReason,
  });

  // 튕김·강퇴는 회색 캔버스 대신 재접속 모달만 보여 준다.
  if (surface === "reconnect") {
    return (
      <div className="page-shell">
        <header className="hero" />
        <ConnectionLostModal
          reason={hub.dropReason ?? "offline"}
          onReconnect={hub.reconnectAfterDrop}
          onExit={backToIntro}
        />
      </div>
    );
  }

  if (surface === "playing") {
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
      {surface === "intro" && (
        <header className="hero intro-top">
          <LocaleSwitch />
        </header>
      )}

      <DeployReloadBanner visible={deployStale} onReload={reloadDeploy} />

      {surface === "intro" && (
        <OfflinePhase
          nickname={name}
          hasSavedName={hasSavedName}
          onNameChange={setName}
          onConnect={findRoom}
          onResetName={resetName}
        />
      )}

      {surface === "resuming" && (
        <div className="fade-in">
          <ConnectingPhase message={t("game.resuming")} />
          <div className="center-row">
            <button className="btn-text" onClick={backToIntro}>
              {t("game.startFresh")}
            </button>
          </div>
        </div>
      )}

      {surface === "matchmaking" && (
        <div className="fade-in">
          <ConnectingPhase
            message={hub.joiningKind === "create" ? t("create.pending") : t("lobby.joining")}
          />
        </div>
      )}

      {surface === "lobby" && (
        <div className="fade-in">
          <LobbyPhase
            rooms={hub.rooms}
            status={hub.status}
            myRoom={hub.myRoom}
            onJoinRoom={hub.joinRoom}
            onRefresh={hub.refreshRooms}
            refreshing={hub.refreshingRooms}
            onBackToIntro={backToIntro}
            connClass={CONNECTION_CLASS[hub.status]}
            connText={connLabel(hub.status, t)}
            rttMs={hub.rttMs}
            rttText={hub.rttMs > 0 ? t("connection.ping", { ms: hub.rttMs }) : null}
          />
        </div>
      )}

      {surface === "room" && (
        <InRoomPhase
          roomOpen={hub.roomOpen}
          onToggleRoom={hub.toggleRoom}
          gameId={hub.gameId}
          idleLeftSec={hub.idleLeftSec}
          onSetGame={hub.setGame}
          onSetCharacter={hub.setCharacter}
          players={hub.players}
          you={hub.you}
          isHost={hub.isHost}
          ownPackPct={ownPackPct}
          canStart={loader.state === "ready"}
          onStartGame={start}
          onLeaveRoom={leaveToLobby}
          connClass={CONNECTION_CLASS[hub.status]}
          connText={connLabel(hub.status, t)}
          rttMs={hub.rttMs}
          rttText={hub.rttMs > 0 ? t("connection.ping", { ms: hub.rttMs }) : null}
        />
      )}
    </div>
  );
}
