import { useCallback, type MutableRefObject } from "react";
import type { Room } from "@colyseus/sdk";
import { HANDOFF, ROOM_LEAVE } from "@/lib/contract";
import { clearMyRoom } from "@/lib/room-membership";
import { forgetHubPin } from "@/lib/hub/public-address";
import { reactOwnsResume } from "@/lib/game-flow-state";
import { clearEngineHandoff } from "@/lib/godot/handoff";
import { clearInboundSnap } from "@/lib/hub/page-bridge";
import type { JoinRequest, MatchInfo } from "@/types";

export function useHubCommands(
  nameRef: MutableRefObject<string>,
  room: Room | undefined,
  setJoinRequest: (req: JoinRequest | null) => void,
  setMatchInfo: (info: MatchInfo | null) => void,
  setError: (message: string | null) => void,
  setConnected: (on: boolean) => void,
  setResumeFailed: (on: boolean) => void,
  clearDrop: () => void,
  takeReconnectId: () => string | null,
): {
  connect: (name: string) => void;
  createRoom: (raw?: { game?: string; title?: string }) => void;
  joinRoom: (id: string) => void;
  leaveRoom: () => void;
  forgetMyRoom: () => void;
  disconnect: () => void;
  returnToLobby: (name: string) => void;
  reconnectAfterDrop: () => void;
  tryResume: () => boolean;
} {
  const connect = useCallback((name: string) => {
    nameRef.current = name;
    setError(null);
    setConnected(true);
  }, [nameRef, setConnected, setError]);

  const createRoom = useCallback((raw?: { game?: string; title?: string }) => {
    setError(null);
    setJoinRequest({ kind: "create", game: raw?.game, title: raw?.title });
  }, [setError, setJoinRequest]);

  const joinRoom = useCallback((id: string) => {
    setError(null);
    setJoinRequest({ kind: "join", id });
  }, [setError, setJoinRequest]);

  const leaveRoom = useCallback(() => {
    clearDrop();
    clearEngineHandoff(true);
    forgetHubPin();
    clearMyRoom((k) => localStorage.removeItem(k));
    clearInboundSnap();
    setMatchInfo(null);
    if (room) {void room.leave(ROOM_LEAVE.CONSENTED);}
    setJoinRequest(null);
  }, [clearDrop, room, setJoinRequest, setMatchInfo]);

  /** 로비 목록에서 내 방(아직 살아있지만 지금은 연결 안 된)을 버리고 다른 방으로
   * 갈 때 — leaveRoom 과 달리 소켓이 없으니 room.leave() 는 안 부른다. 버려진
   * 방은 서버 쪽 유휴 타이머로 자연 정리된다. */
  const forgetMyRoom = useCallback(() => {
    clearMyRoom((k) => localStorage.removeItem(k));
  }, []);

  const disconnect = useCallback(() => {
    leaveRoom();
    setConnected(false);
  }, [leaveRoom, setConnected]);

  const returnToLobby = useCallback((_name: string) => {
    // 매치 종료는 끝난 방 resume 으로 재접속하면 안 된다. 새로고침 중 매치 지속은 leave 하지 않으므로 토큰이 남는다.
    leaveRoom();
  }, [leaveRoom]);

  const reconnectAfterDrop = useCallback(() => {
    const id = takeReconnectId();
    setError(null);
    setConnected(true);
    if (id) {setJoinRequest({ kind: "join", id });}
  }, [setConnected, setError, setJoinRequest, takeReconnectId]);

  const tryResume = useCallback((): boolean => {
    const token = sessionStorage.getItem(HANDOFF.RESUME);
    if (!reactOwnsResume(sessionStorage.getItem(HANDOFF.FROM_HUB), token)) {return false;}
    nameRef.current = sessionStorage.getItem(HANDOFF.NAME) ?? "";
    setResumeFailed(false);
    setConnected(true);
    setJoinRequest({ kind: "resume" });
    return true;
  }, [nameRef, setConnected, setJoinRequest, setResumeFailed]);

  return {
    connect, createRoom, joinRoom, leaveRoom, forgetMyRoom, disconnect,
    returnToLobby, reconnectAfterDrop, tryResume,
  };
}
