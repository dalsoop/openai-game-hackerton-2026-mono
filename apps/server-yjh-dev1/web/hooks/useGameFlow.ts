"use client";
// 게임 페이즈 상태머신 — page.tsx 가 화면 그리기만 하도록 로직을 이곳으로 뺀다.
import { useCallback, useEffect, useState } from "react";
import { useHub } from "@/hooks/useHub";
import { useSession } from "@/hooks/useSession";
import { useGodotLoader } from "@/hooks/useGodotLoader";
import { phaseFromHubStatus, phaseAfterMatchEnd, displayNameOf } from "@/lib/game-flow-state";
import type { GamePhase, MatchInfo } from "@/types";

/** useGameFlow 반환 계약 — page.tsx 가 이 필드들만 소비한다. */
export interface UseGameFlowResult {
  phase: GamePhase;
  name: string;
  displayName: string;
  setName: (name: string) => void;
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

export function useGameFlow(game: string, defaultPlayer: string): UseGameFlowResult {
  const { nickname, saveNickname } = useSession();
  const hub = useHub(game);
  const loader = useGodotLoader(game);
  const [phase, setPhase] = useState<GamePhase>("intro");
  const [name, setName] = useState(nickname || "");

  const displayName = displayNameOf(name, defaultPlayer);
  // 핸드오프 후에는 방을 떠나 hub 필드가 비므로, START 때 확정한 matchInfo 를 쓴다.
  const matchInfo: MatchInfo = hub.matchInfo ?? {
    roomId: hub.roomId,
    name: displayName,
    slot: hub.you,
    resumeToken: hub.resumeToken,
  };

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
    if (phase === "lobby" || phase === "room") {loader.start();}
  }, [phase]); // eslint-disable-line react-hooks/exhaustive-deps -- loader는 싱글턴 런타임

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
    hub.leaveRoom();
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

  return {
    phase,
    name,
    displayName,
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
  };
}
