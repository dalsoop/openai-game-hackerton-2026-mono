"use client";
// 게임 페이즈 상태머신 — page.tsx 가 화면 그리기만 하도록 로직을 이곳으로 뺀다.
import { useCallback, useEffect, useRef, useState } from "react";
import { useHub } from "@/hooks/useHub";
import { useSession } from "@/hooks/useSession";
import { useGodotLoader } from "@/hooks/useGodotLoader";
import { asGameId } from "@/lib/games/catalog";
import { phaseFromHubStatus, phaseAfterMatchEnd, displayNameOf, downloadStartsInRoom, phaseOnMount } from "@/lib/game-flow-state";
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
  matchInfo: MatchInfo;
  findRoom: () => void;
  start: () => void;
  backToIntro: () => void;
  leaveToLobby: () => void;
  matchEnd: () => void;
  errorToIntro: () => void;
}

export function useGameFlow(defaultPlayer: string): UseGameFlowResult {
  const { nickname, saveNickname, clearNickname } = useSession();
  const hub = useHub();
  // 유즈맵 — 접속한 방의 게임을 따라간다 (없으면 기본 게임).
  const loader = useGodotLoader(asGameId(hub.gameId));
  const [phase, setPhase] = useState<GamePhase>("intro");
  const [name, setName] = useState(nickname || "");

  const displayName = displayNameOf(name, defaultPlayer);
  // START 이후에도 React 방이 살아 있다. matchInfo 가 있으면 그 확정본을 쓴다.
  const matchInfo: MatchInfo = hub.matchInfo ?? {
    roomId: hub.roomId,
    name: displayName,
    slot: hub.you,
    resumeToken: hub.resumeToken,
  };

  // 재접근 시 이전 세션 재개 — 세션이 살아있는(재접속 유예 안) 동안에는 그 세션으로 복귀한다.
  const resumeTried = useRef(false);
  useEffect(() => {
    if (resumeTried.current) {return;} // StrictMode 2회 실행 가드
    resumeTried.current = true;
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
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 외부 저장소(localStorage) → React 동기화
    if (nickname) {setName(nickname);}
  }, [nickname]);

  // 허브 상태가 화면 페이즈를 몰아간다 (in-room → 대기실, playing → 게임).
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 허브(외부 시스템) 상태 → 페이즈 반영
    setPhase((current) => phaseFromHubStatus(hub.status, current));
  }, [hub.status]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 튕김은 대기실·캔버스를 붙잡지 않고 로비로
    if (hub.dropReason) {setPhase("lobby");}
  }, [hub.dropReason]);

  const startDownload = loader.start;
  useEffect(() => {
    if (downloadStartsInRoom(phase)) {startDownload();} // 유즈맵 — 다운로드는 방에 들어와서 시작
  }, [phase, startDownload]); // gameId 가 확정되면 런타임이 바뀌므로 start 가 다시 불린다

  const findRoom = useCallback(() => {
    saveNickname(displayName);
    hub.connect(displayName);
    setPhase("lobby");
     
  }, [displayName, hub, saveNickname]);

  const start = useCallback(() => {
    if (loader.state !== "ready") {return;}
    hub.startMatch();
  }, [hub, loader.state]);

  const backToIntro = useCallback(() => {
    hub.disconnect();
    setPhase("intro");
  }, [hub]);

  const leaveToLobby = useCallback(() => {
    hub.leaveRoom();
    setPhase("lobby");
  }, [hub]);

  const matchEnd = useCallback(() => {
    setPhase(phaseAfterMatchEnd(hub.status));
    if (phaseAfterMatchEnd(hub.status) === "lobby") {hub.returnToLobby(displayName);}
  }, [hub, displayName]);

  const errorToIntro = useCallback(() => setPhase("intro"), []);

  const resetName = useCallback(() => {
    clearNickname();
    setName("");
  }, [clearNickname]);

  return {
    phase,
    name,
    displayName,
    setName,
    resetName,
    hasSavedName: nickname !== "",
    hub,
    loader,
    matchInfo,
    findRoom,
    start,
    backToIntro,
    leaveToLobby,
    matchEnd,
    errorToIntro,
  };
}
