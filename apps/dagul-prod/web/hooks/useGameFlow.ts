"use client";
// 게임 페이즈 상태머신 — page.tsx 가 화면 그리기만 하도록 로직을 이곳으로 뺀다.
import { useCallback, useEffect, useRef, useState } from "react";
import { WEB_STORE } from "@/lib/contract";
import { parseRoomShare, peekPendingJoin, savePendingJoin, takePendingJoin } from "@/lib/hub/room-link";
import { useHub } from "@/hooks/useHub";
import { useSession } from "@/hooks/useSession";
import { useGodotLoader } from "@/hooks/useGodotLoader";
import { useDeployRevision } from "@/hooks/useDeployRevision";
import { asGameId } from "@/lib/games/catalog";
import { useWaitingRoomPack } from "@/hooks/useWaitingRoomPack";
import {
  phaseFromHubStatus, phaseAfterMatchEnd, displayNameOf, phaseOnMount, deployReloadSafe,
  resumeYieldsToShare, shouldAutoJoinShare,
} from "@/lib/game-flow-state";
import { isAutoGuestName, parseGuestId, readCookie } from "@/lib/guest-identity";
import { clearInboundSnap } from "@/lib/hub/page-bridge";
import { holdLobbyBgmOff } from "@/hooks/useLobbyAudio";
import type { GamePhase, MatchInfo } from "@/types";

/** useGameFlow 반환 계약 — page.tsx 가 이 필드들만 소비한다. */
export interface UseGameFlowResult {
  phase: GamePhase;
  name: string;
  displayName: string;
  setName: (name: string) => void;
  resetName: () => void;
  hasSavedName: boolean;
  hub: ReturnType<typeof useHub>;
  loader: ReturnType<typeof useGodotLoader>;
  ownPackPct: number;
  matchInfo: MatchInfo;
  findRoom: () => void;
  start: () => void;
  backToIntro: () => void;
  leaveToLobby: () => void;
  matchEnd: () => void;
  errorToIntro: () => void;
  deployStale: boolean;
  reloadDeploy: () => void;
}

export function useGameFlow(defaultPlayer: string, buildId = ""): UseGameFlowResult {
  const { nickname, guestName, saveNickname, clearNickname } = useSession();
  const hub = useHub();
  // 유즈맵 — 접속한 방의 게임을 따라간다 (없으면 기본 게임).
  const loader = useGodotLoader(asGameId(hub.gameId));
  const [phase, setPhase] = useState<GamePhase>("intro");
  const fallbackName = guestName || defaultPlayer;

  useEffect(() => {
    const share = parseRoomShare(window.location.search);
    if (!share) {return;}
    savePendingJoin(sessionStorage, WEB_STORE.PENDING_JOIN, share);
    // URL 의 room·pw 는 입장 성공 전까지 남긴다. 개발 StrictMode 재마운트가
    // pending 을 다시 살릴 수 있게 하고, 새로고침해도 같은 링크로 들어온다.
  }, []);

  useEffect(() => {
    if (hub.status !== "in-room") {return;}
    const url = new URL(window.location.href);
    if (!url.searchParams.has("room") && !url.searchParams.has("pw")) {return;}
    url.searchParams.delete("room");
    url.searchParams.delete("pw");
    const qs = url.searchParams.toString();
    window.history.replaceState(null, "", url.pathname + (qs ? `?${qs}` : "") + url.hash);
  }, [hub.status]);
  const [name, setName] = useState(nickname || guestName);
  const revision = useDeployRevision(buildId);

  // 안전한 화면(intro·lobby)에서는 stale 셸을 자동 새로고침한다 — 배너 클릭 대기 없이.
  useEffect(() => {
    if (deployReloadSafe(phase, revision.stale)) {revision.reload();}
  }, [phase, revision.stale, revision.reload, revision]);

  // 닉 하이드레이션이 name 상태보다 한 틱 늦을 수 있어, 입장 이름은 저장 닉을 우선한다.
  const displayName = displayNameOf(nickname || name, fallbackName);
  // START 이후에도 React 방이 살아 있다. matchInfo 가 있으면 그 확정본을 쓴다.
  const matchInfo: MatchInfo = hub.matchInfo ?? {
    roomId: hub.roomId,
    name: displayName,
    slot: hub.you,
    resumeToken: hub.resumeToken,
  };

  // 재접근 시 이전 세션 재개 — 세션이 살아있는(재접속 유예 안) 동안에는 그 세션으로 복귀한다.
  // 공유 링크로 들어온 입장은 이전 매치 재개보다 우선한다.
  const resumeTried = useRef(false);
  useEffect(() => {
    if (resumeTried.current) {return;} // StrictMode 2회 실행 가드
    resumeTried.current = true;
    if (resumeYieldsToShare(peekPendingJoin(sessionStorage, WEB_STORE.PENDING_JOIN) !== null)) {return;}
    const next = phaseOnMount(hub.tryResume());
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 외부 세션(유예 창) 재개 1회 시도
    if (next) {setPhase(next);}
    // eslint-disable-next-line react-hooks/exhaustive-deps -- 최초 마운트 1회 시도
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 유예 만료 → 인트로 복귀
    if (hub.resumeFailed) {setPhase("intro");}
  }, [hub.resumeFailed]);

  useEffect(() => {
    if (nickname) {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- 외부 저장소(localStorage·쿠키) → React 동기화
      setName(nickname);
      return;
    }
    if (!guestName) {return;}
    const id = typeof document === "undefined"
      ? null
      : parseGuestId(readCookie(WEB_STORE.GUEST_ID, document.cookie));
    setName((current) => {
      if (current === "" || (id !== null && isAutoGuestName(current, id))) {
        return guestName;
      }
      return current;
    });
  }, [nickname, guestName]);

  // 허브 상태가 화면 페이즈를 몰아간다 (in-room → 대기실, playing → 게임).
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 허브(외부 시스템) 상태 → 페이즈 반영
    setPhase((current) => phaseFromHubStatus(hub.status, current));
  }, [hub.status]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 튕김은 대기실·캔버스를 붙잡지 않고 로비로
    if (hub.dropReason) {setPhase("lobby");}
  }, [hub.dropReason]);

  const { ownPackPct } = useWaitingRoomPack(phase, loader, hub.sendPackPct);

  const findRoom = useCallback(() => {
    holdLobbyBgmOff();
    saveNickname(displayName);
    hub.connect(displayName);
    const pending = takePendingJoin(sessionStorage, WEB_STORE.PENDING_JOIN);
    if (pending) {hub.joinRoom(pending.roomId, { password: pending.password });}
    setPhase("lobby");
  }, [displayName, hub, saveNickname]);

  // 저장된 닉이 있으면 공유 링크만으로 입장한다 — 인트로 시작하기를 다시 누르지 않는다.
  const autoJoinTried = useRef(false);
  useEffect(() => {
    if (autoJoinTried.current) {return;}
    const pending = peekPendingJoin(sessionStorage, WEB_STORE.PENDING_JOIN);
    if (!shouldAutoJoinShare(nickname !== "", pending !== null)) {return;}
    autoJoinTried.current = true;
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 저장 닉 + 공유 링크면 인트로를 건너뛴다
    findRoom();
  }, [nickname, findRoom]);

  const start = useCallback(() => {
    if (loader.state !== "ready") {return;}
    holdLobbyBgmOff();
    hub.startMatch();
  }, [hub, loader.state]);

  const backToIntro = useCallback(() => {
    hub.disconnect();
    setPhase("intro");
  }, [hub]);

  const leaveToLobby = useCallback(() => {
    clearInboundSnap();
    hub.leaveRoom();
    setPhase("lobby");
  }, [hub]);

  const matchEnd = useCallback(() => {
    clearInboundSnap();
    setPhase(phaseAfterMatchEnd(hub.status));
    if (phaseAfterMatchEnd(hub.status) === "lobby") {hub.returnToLobby(displayName);}
  }, [hub, displayName]);

  const errorToIntro = leaveToLobby;

  const resetName = useCallback(() => {
    clearNickname();
    setName(guestName);
  }, [clearNickname, guestName]);

  return {
    phase,
    name,
    displayName,
    setName,
    resetName,
    hasSavedName: nickname !== "",
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
    deployStale: revision.stale,
    reloadDeploy: revision.reload,
  };
}
