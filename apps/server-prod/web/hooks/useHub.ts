"use client";
// Colyseus 허브 훅(조합 루트) — 세부는 각 훅·모듈이 소유한다.
//   방 목록: useRoomList (리스트 룸 구독·델타는 lib/hub/room-mapper)
//   방 연결: useGameRoom (핸드오프·matchInfo)
//   파생 명단: lib/domain/roster · 내 방 멤버십: useMyRoom
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Client, type Room } from "@colyseus/sdk";
import { useRoomMessage, useRoomState } from "@colyseus/react";
import { MSG, HANDOFF } from "@/lib/contract";
import { Roster, type RosterSnapshot } from "@/lib/domain/roster";
import { clearMyRoom } from "@/lib/room-membership";
import { useMyRoom } from "@/hooks/useMyRoom";
import { useRoomList } from "@/hooks/useRoomList";
import { useGameRoom, type RoomEndKind } from "@/hooks/useGameRoom";
import { shouldMarkRoomDropped } from "@/lib/game-flow-state";
import { useDropSession } from "@/hooks/useDropSession";
import { deriveStatus } from "@/lib/hub/status";
import type { HubPlayer, HubStatus, JoinRequest, UseHubResult } from "@/types";

let _client: Client | null = null;
function getClient(): Client {
  _client ??= new Client(location.origin);
  return _client;
}


interface HubFacts {
  gameId: string;
  open: boolean;
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  roomId: string;
  resumeToken: string;
  status: HubStatus;
}

// 방 파생 사실 — 훅 복잡도를 낮추기 위해 모듈로 뺀 순수 계산.
function deriveHubFacts(room: Room | undefined, snap: RosterSnapshot | undefined): HubFacts | null {
  if (!room || !snap) {return null;}
  const roster = Roster.fromSnapshot(snap, room.sessionId);
  const players: HubPlayer[] = roster.seats.map((seat) => ({
    slot: seat.slot, id: seat.playerId, name: seat.name,
    host: seat.isHost, dropped: !seat.connected,
  }));
  return {
    gameId: snap.gameId ?? "",
    open: snap.open !== false,
    players,
    you: roster.you,
    isHost: roster.isHost,
    roomId: room.roomId,
    resumeToken: room.reconnectionToken,
    status: (roster.playing ? "playing" : "in-room") as HubStatus,
  };
}

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
  const { rooms, lobbyErr, lobbyConnecting } = useRoomList(connected && !joinRequest, getClient);
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

  useRoomMessage(room, MSG.ERROR, (msg: { msg?: string }) => {
    setError(msg.msg ?? null);
  });
  useRoomMessage(room, MSG.KICKED, onKicked);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 허브(외부 시스템) 오류 → React 반영
    if (roomError) {setError(roomError.message);}
  }, [roomError]);

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

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 리스트 룸(외부 시스템) 오류 → React 반영
    if (lobbyErr) {setError(lobbyErr.message);}
  }, [lobbyErr]);

  const connect = useCallback((name: string) => {
    nameRef.current = name;
    setError(null);
    setConnected(true);
  }, []);

  const createRoom = useCallback((raw?: { game?: string; title?: string }) => {
    setJoinRequest({ kind: "create", game: raw?.game, title: raw?.title });
  }, []);
  const joinRoom = useCallback((id: string) => {
    setJoinRequest({ kind: "join", id });
  }, []);

  const leaveRoom = useCallback(() => {
    clearDrop();
    localStorage.removeItem(HANDOFF.RESUME); // 의도적 퇴장 — 세션 종료
    clearMyRoom((k) => localStorage.removeItem(k)); // 멤버십도 폐기 — 더 이상 내 방 아님
    setMatchInfo(null);
    setJoinRequest(null); // useRoom 이 room.leave 를 수행하고, 리스트 룸이 다시 붙는다
  }, [setMatchInfo, clearDrop]);

  const reconnectAfterDrop = useCallback(() => {
    const id = takeReconnectId();
    setError(null);
    setConnected(true);
    if (id) {setJoinRequest({ kind: "join", id });}
  }, [takeReconnectId]);

  const disconnect = useCallback(() => {
    leaveRoom();
    setConnected(false); // 리스트 룸도 내린다 — 뒤로가기가 인트로에서 멈추게
  }, [leaveRoom]);

  // 게임 종료 후: Godot 이 세션을 반납했으므로 페이지가 재입장해 대기실로 돌아간다.
  const returnToLobby = useCallback((_name: string) => {
    const roomId = matchInfo?.roomId;
    setMatchInfo(null);
    if (!room && roomId) {setJoinRequest({ kind: "join", id: roomId });}
    else if (!room) {setJoinRequest(null);}
  }, [room, matchInfo, setMatchInfo]);

  const startMatch = useCallback(() => room?.send(MSG.START, {}), [room]);

  // 방장의 방 열기/닫기 — 닫으면 서버가 재실자를 강퇴한다.
  const toggleRoom = useCallback(() => room?.send(MSG.ROOM_TOGGLE, {}), [room]);

  // 리스트가 실시간이므로 수동 새로고침은 없다 (인터페이스 호환용 no-op).
  const refreshRooms = useCallback(() => {}, []);

  // 세션 재개 — 저장된 토큰이 있으면 재접속을 시도한다 (성공 여부는 room 상태로 판정).
  const tryResume = useCallback((): boolean => {
    const token = localStorage.getItem(HANDOFF.RESUME);
    if (!token) {return false;}
    nameRef.current = localStorage.getItem(HANDOFF.NAME) ?? "";
    setResumeFailed(false);
    setConnected(true);
    setJoinRequest({ kind: "resume" });
    return true;
  }, []);

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
    error,
    matchInfo,
    connect,
    createRoom,
    joinRoom,
    leaveRoom,
    disconnect,
    returnToLobby,
    startMatch,
    toggleRoom,
    refreshRooms,
    tryResume,
    resuming: joinRequest?.kind === "resume",
    resumeFailed,
    dropReason,
    lastRoomId,
    reconnectAfterDrop,
    myRoom,
  };
}
