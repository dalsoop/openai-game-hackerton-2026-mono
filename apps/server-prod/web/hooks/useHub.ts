"use client";
// Colyseus 허브 훅(조합 루트) — 세부는 각 훅·모듈이 소유한다.
//   방 목록: useRoomList (GET /rooms 폴링)
//   방 연결: useGameRoom (핸드오프·matchInfo)
//   파생 명단: lib/domain/roster · 내 방 멤버십: useMyRoom
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Client, type Room } from "@colyseus/sdk";
import { useRoomMessage, useRoomState } from "@colyseus/react";
import { MSG } from "@/lib/contract";
import { type RosterSnapshot } from "@/lib/domain/roster";
import { deriveHubFacts } from "@/lib/hub/hub-facts";
import { useMyRoom } from "@/hooks/useMyRoom";
import { useRoomList } from "@/hooks/useRoomList";
import { useRoomIdle } from "@/hooks/useRoomIdle";
import { useHubCommands } from "@/hooks/useHubCommands";
import { useGameRoom, type RoomEndKind } from "@/hooks/useGameRoom";
import { usePageBridge } from "@/hooks/usePageBridge";
import { useRoomRtt } from "@/hooks/useRoomRtt";
import { shouldMarkRoomDropped } from "@/lib/hub/room-end";
import { useDropSession } from "@/hooks/useDropSession";
import { deriveStatus } from "@/lib/hub/status";
import { useDownloadReport } from "@/hooks/useDownloadReport";
import type { HubStatus, JoinRequest, UseHubResult } from "@/types";

function liveRttMs(room: Room | undefined, roomRtt: number, healthRtt: number): number {
  return room ? roomRtt : healthRtt;
}

function useHubExternalErrors(
  roomError: Error | null | undefined,
  lobbyErr: Error | null | undefined,
  setError: (message: string | null) => void,
): void {
  useEffect(() => {
    if (roomError) {setError(roomError.message);}
  }, [roomError, setError]);
  useEffect(() => {
    if (lobbyErr) {setError(lobbyErr.message);}
  }, [lobbyErr, setError]);
}

let _client: Client | null = null;
function getClient(): Client {
  _client ??= new Client(location.origin);
  return _client;
}


// 조합 루트 — 분기 명령은 useHubCommands 가 맡는다.
// eslint-disable-next-line complexity -- 훅 조합과 반환 필드가 한곳에 모인다
export function useHub(): UseHubResult {
  const nameRef = useRef("");
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [joinRequest, setJoinRequest] = useState<JoinRequest | null>(null);
  const [resumeFailed, setResumeFailed] = useState(false);
  const {
    dropReason, lastRoomId, rememberRoomId, onRoomDropped, onKicked, clearDrop, takeReconnectId,
  } = useDropSession();

  // 게임 방에 들어가 있는 동안엔 리스트 연결을 내려 자원을 아낀다.
  const { rooms, lobbyErr, lobbyConnecting, refresh } = useRoomList(connected && !joinRequest);
  const handleResumeFailed = useCallback((message: string) => {
    setError(message);
    setJoinRequest(null);
    setConnected(false);
    setResumeFailed(true);
  }, []);
  const { room, roomError, matchInfo, setMatchInfo } = useGameRoom(
    joinRequest,
    () => nameRef.current,
    getClient,
    useCallback((kind: RoomEndKind) => {
      setJoinRequest(null);
      if (shouldMarkRoomDropped(kind)) {onRoomDropped();}
    }, [onRoomDropped]),
    handleResumeFailed,
  );

  // 방 상태 = 서버 state 의 불변 스냅샷.
  const snap = useRoomState(room as Room<RosterSnapshot> | undefined);
  const roomRtt = useRoomRtt(room);
  const rttMs = liveRttMs(room, roomRtt, 0);
  usePageBridge(room, matchInfo, snap, rttMs);

  useRoomMessage(room, MSG.ERROR, (msg: { msg?: string }) => {
    setError(msg.msg ?? null);
  });
  useRoomMessage(room, MSG.KICKED, onKicked);
  useHubExternalErrors(roomError, lobbyErr, setError);

  // 파생 사실은 도메인(Roster)이 계산한다.
  const derived = useMemo(() => deriveHubFacts(room, snap), [room, snap]);
  useEffect(() => {
    if (!derived?.roomId) {return;}
    rememberRoomId(derived.roomId);
  }, [derived?.roomId, rememberRoomId]);

  // 접속 상태: 리스트 룸 실왕복이 성공해야 "접속됨"이다.
  const status: HubStatus = deriveStatus(derived, connected, lobbyErr, lobbyConnecting, matchInfo);

  // 내 방 멤버십 — 방에 있으면 식별자를 남긴다(강제 단절 후 로비 목록에서 상단 고정·재입장용).
  const myRoom = useMyRoom(derived);
  const commands = useHubCommands(
    nameRef, room, matchInfo, setJoinRequest, setMatchInfo,
    setError, setConnected, setResumeFailed, clearDrop, takeReconnectId,
  );

  const sends = useMemo(() => ({
    startMatch: (): void => {room?.send(MSG.START, {});},
    setGame: (game: string): void => {room?.send(MSG.SET_GAME, { game });},
    toggleRoom: (): void => {room?.send(MSG.ROOM_TOGGLE, {});},
  }), [room]);
  const reportDownload = useDownloadReport(room, `${derived?.roomId ?? ""}:${derived?.gameId ?? ""}`);
  const idleLeftSec = useRoomIdle(derived?.idleUntilSec ?? 0, status === "in-room");

  return {
    status,
    rooms,
    gameId: derived?.gameId ?? "",
    players: derived?.players ?? [],
    you: derived?.you ?? -1,
    roomId: derived?.roomId ?? "",
    isHost: derived?.isHost ?? false,
    roomOpen: derived?.open ?? true,
    resumeToken: derived?.resumeToken ?? "",
    rttMs,
    error,
    matchInfo,
    connect: commands.connect,
    createRoom: commands.createRoom,
    joinRoom: commands.joinRoom,
    leaveRoom: commands.leaveRoom,
    disconnect: commands.disconnect,
    returnToLobby: commands.returnToLobby,
    startMatch: sends.startMatch,
    reportDownload,
    setGame: sends.setGame,
    idleLeftSec,
    toggleRoom: sends.toggleRoom,
    refreshRooms: refresh,
    tryResume: commands.tryResume,
    resuming: joinRequest?.kind === "resume",
    resumeFailed,
    dropReason,
    lastRoomId,
    reconnectAfterDrop: commands.reconnectAfterDrop,
    myRoom,
  };
}
