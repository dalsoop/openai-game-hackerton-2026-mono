import { useCallback, type MutableRefObject } from "react";
import type { Room } from "@colyseus/sdk";
import { HANDOFF, ROOM_LEAVE } from "@/lib/contract";
import { clearMyRoom } from "@/lib/room-membership";
import { forgetHubPin } from "@/lib/hub/public-address";
import { reactOwnsResume } from "@/lib/game-flow-state";
import type { JoinRequest, MatchInfo } from "@/types";

export function useHubCommands(
  nameRef: MutableRefObject<string>,
  room: Room | undefined,
  matchInfo: MatchInfo | null,
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
    setJoinRequest({ kind: "create", game: raw?.game, title: raw?.title });
  }, [setJoinRequest]);

  const joinRoom = useCallback((id: string) => {
    setJoinRequest({ kind: "join", id });
  }, [setJoinRequest]);

  const leaveRoom = useCallback(() => {
    clearDrop();
    sessionStorage.removeItem(HANDOFF.RESUME);
    sessionStorage.removeItem(HANDOFF.FROM_HUB);
    sessionStorage.removeItem(HANDOFF.MATCH);
    forgetHubPin();
    clearMyRoom((k) => localStorage.removeItem(k));
    setMatchInfo(null);
    if (room) {void room.leave(ROOM_LEAVE.CONSENTED);}
    setJoinRequest(null);
  }, [clearDrop, room, setJoinRequest, setMatchInfo]);

  const disconnect = useCallback(() => {
    leaveRoom();
    setConnected(false);
  }, [leaveRoom, setConnected]);

  const returnToLobby = useCallback((_name: string) => {
    const roomId = matchInfo?.roomId;
    sessionStorage.removeItem(HANDOFF.FROM_HUB);
    sessionStorage.removeItem(HANDOFF.MATCH);
    setMatchInfo(null);
    if (room) {return;}
    setJoinRequest(roomId ? { kind: "join", id: roomId } : null);
  }, [matchInfo, room, setJoinRequest, setMatchInfo]);

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
    connect, createRoom, joinRoom, leaveRoom, disconnect,
    returnToLobby, reconnectAfterDrop, tryResume,
  };
}
