import { useCallback, type MutableRefObject } from "react";
import type { Room } from "@colyseus/sdk";
import { HANDOFF } from "@/lib/contract";
import { clearMyRoom } from "@/lib/room-membership";
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
    localStorage.removeItem(HANDOFF.RESUME);
    localStorage.removeItem(HANDOFF.FROM_HUB);
    localStorage.removeItem(HANDOFF.MATCH);
    clearMyRoom((k) => localStorage.removeItem(k));
    setMatchInfo(null);
    setJoinRequest(null);
  }, [clearDrop, setJoinRequest, setMatchInfo]);

  const disconnect = useCallback(() => {
    leaveRoom();
    setConnected(false);
  }, [leaveRoom, setConnected]);

  const returnToLobby = useCallback((_name: string) => {
    const roomId = matchInfo?.roomId;
    localStorage.removeItem(HANDOFF.FROM_HUB);
    localStorage.removeItem(HANDOFF.MATCH);
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
    const token = localStorage.getItem(HANDOFF.RESUME);
    if (!reactOwnsResume(localStorage.getItem(HANDOFF.FROM_HUB), token)) {return false;}
    nameRef.current = localStorage.getItem(HANDOFF.NAME) ?? "";
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
