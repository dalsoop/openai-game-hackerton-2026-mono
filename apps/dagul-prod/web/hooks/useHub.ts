"use client";
// Colyseus 허브 훅(조합 루트) — 세부는 각 훅·모듈이 소유한다.
//   방 목록: useRoomList (GET /rooms 폴링)
//   방 연결: useGameRoom (핸드오프·matchInfo)
//   파생 명단: lib/domain/roster · 내 방 멤버십: useMyRoom
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Client, type Room } from "@colyseus/sdk";
import { useRoomMessage, useRoomState } from "@colyseus/react";
import { HANDOFF, MSG } from "@/lib/contract";
import { type RosterSnapshot } from "@/lib/domain/roster";
import { waitingRoomRosterOf } from "@/lib/hub/waiting-room-roster";
import { useMyRoom } from "@/hooks/useMyRoom";
import { useRoomList } from "@/hooks/useRoomList";
import { useRoomIdle } from "@/hooks/useRoomIdle";
import { useHubCommands } from "@/hooks/useHubCommands";
import { useGameRoom, type RoomEndKind } from "@/hooks/useGameRoom";
import { usePageBridge } from "@/hooks/usePageBridge";
import { useRoomRtt } from "@/hooks/useRoomRtt";
import { forgetHubPin, hubHttpEndpoint } from "@/lib/hub/public-address";
import { dropReasonFromKick, shouldMarkRoomDropped } from "@/lib/hub/room-end";
import { useDropSession } from "@/hooks/useDropSession";
import { deriveStatus } from "@/lib/hub/status";
import { useSendPackPct } from "@/hooks/useSendPackPct";
import { isUncheckedRuntimeLastError } from "@/lib/helpers/runtime-noise";
import type { HubStatus, JoinRequest, UseHubResult } from "@/types";

function setHubError(setError: (message: string | null) => void, message: string | null): void {
  if (message && isUncheckedRuntimeLastError(message)) {return;}
  setError(message);
}

function liveRttMs(room: Room | undefined, roomRtt: number, healthRtt: number): number {
  return room ? roomRtt : healthRtt;
}

function useHubExternalErrors(
  roomError: Error | null | undefined,
  lobbyErr: Error | null | undefined,
  setError: (message: string | null) => void,
): void {
  useEffect(() => {
    if (roomError) {setHubError(setError, roomError.message);}
  }, [roomError, setError]);
  useEffect(() => {
    if (lobbyErr) {setHubError(setError, lobbyErr.message);}
  }, [lobbyErr, setError]);
}

let _client: Client | null = null;
function getClient(pin?: string | null): Client {
  if (!pin) {
    _client ??= new Client(location.origin);
    return _client;
  }
  return new Client(hubHttpEndpoint(location.origin, pin));
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
  const { rooms, lobbyErr, lobbyConnecting, refresh, refreshing } = useRoomList(connected && !joinRequest);
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
  // 좌석이 다른 창으로 넘어간 경우, 이 탭의 재개 토큰을 폐기해 refresh 후 자동 재개를 막는다.
  const handleKicked = useCallback((raw?: unknown) => {
    if (dropReasonFromKick(raw) === "takeover") {
      try {
        sessionStorage.removeItem(HANDOFF.RESUME);
        sessionStorage.removeItem(HANDOFF.FROM_HUB);
        sessionStorage.removeItem(HANDOFF.MATCH);
      } catch { /* sessionStorage 불가 환경 — 재개 시도는 서버가 거부한다 */ }
      forgetHubPin();
    }
    onKicked(raw);
  }, [onKicked]);
  useRoomMessage(room, MSG.KICKED, handleKicked);
  useHubExternalErrors(roomError, lobbyErr, setError);

  // 파생 사실은 도메인(Roster)이 계산한다.
  const derived = useMemo(() => waitingRoomRosterOf(room, snap), [room, snap]);
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
    setCharacter: (characterId: string): void => {room?.send(MSG.SET_CHARACTER, { characterId });},
    toggleRoom: (): void => {room?.send(MSG.ROOM_TOGGLE, {});},
  }), [room]);
  const sendPackPct = useSendPackPct(room, `${derived?.roomId ?? ""}:${derived?.gameId ?? ""}`);
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
    sendPackPct,
    setGame: sends.setGame,
    setCharacter: sends.setCharacter,
    idleLeftSec,
    toggleRoom: sends.toggleRoom,
    refreshRooms: refresh,
    refreshingRooms: refreshing,
    tryResume: commands.tryResume,
    resuming: joinRequest?.kind === "resume",
    resumeFailed,
    joiningKind: roomError
      && (joinRequest?.kind === "create" || joinRequest?.kind === "join")
      ? null
      : (joinRequest?.kind ?? null),
    dropReason,
    lastRoomId,
    reconnectAfterDrop: commands.reconnectAfterDrop,
    myRoom,
  };
}
