"use client";
// Colyseus 허브 훅(조합 루트) — 세부는 각 훅·모듈이 소유한다.
//   방 목록: useRoomList (리스트 룸 구독·델타는 lib/hub/room-mapper)
//   방 연결: useGameRoom (핸드오프·matchInfo)
//   파생 명단: lib/domain/roster · 내 방 멤버십: useMyRoom
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Client, type Room } from "@colyseus/sdk";
import { useRoomMessage, useRoomState } from "@colyseus/react";
import { MSG, HANDOFF, KO } from "@/lib/hub/config";
import { Roster, type RosterSnapshot } from "@/lib/domain/roster";
import { clearMyRoom } from "@/lib/room-membership";
import { useMyRoom } from "@/hooks/useMyRoom";
import { useRoomList } from "@/hooks/useRoomList";
import { useGameRoom } from "@/hooks/useGameRoom";
import { deriveStatus } from "@/lib/hub/status";
import type { HubPlayer, HubStatus, JoinRequest, UseHubResult } from "@/types";

let _client: Client | null = null;
function getClient(): Client {
  if (!_client) {_client = new Client(location.origin);}
  return _client;
}

export function useHub(): UseHubResult {
  const nameRef = useRef("");
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [joinRequest, setJoinRequest] = useState<JoinRequest | null>(null);
  const [resumeFailed, setResumeFailed] = useState(false);

  // 게임 방에 들어가 있는 동안엔 리스트 연결을 내려 자원을 아낀다.
  const { rooms, lobbyErr, lobbyConnecting } = useRoomList(connected && !joinRequest, getClient);
  const { room, roomError, matchInfo, setMatchInfo } = useGameRoom(
    joinRequest,
    () => nameRef.current,
    getClient,
    useCallback(() => {setJoinRequest(null);}, []),
  );

  // 방 상태 = 서버 state 의 불변 스냅샷.
  const snap = useRoomState(room as Room<RosterSnapshot> | undefined);

  useRoomMessage(room, MSG.ERROR, (msg: { msg?: string }) => {
    setError(msg?.msg ?? null);
  });

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 허브(외부 시스템) 오류 → React 반영
    if (roomError) {setError(roomError.message);}
    if (roomError && joinRequest?.kind === "resume") {
      // 세션 유예 만료 — 토큰 폐기, 인트로로 되돌린다
      localStorage.removeItem(HANDOFF.RESUME);
      setJoinRequest(null);
      setConnected(false);
      setResumeFailed(true);
    }
  }, [roomError, joinRequest]);

  // 파생 사실은 도메인(Roster)이 계산한다.
  const derived = useMemo(() => {
    if (!room || !snap) {return null;}
    const roster = Roster.fromSnapshot(snap, room.sessionId);
    const players: HubPlayer[] = roster.seats.map((seat) => ({
      slot: seat.slot, id: seat.playerId, name: seat.name,
      host: seat.isHost, dropped: !seat.connected,
    }));
    return {
      gameId: snap.gameId ?? "",
      players,
      you: roster.you,
      isHost: roster.isHost,
      roomId: room.roomId,
      resumeToken: room.reconnectionToken,
      status: (roster.playing ? "playing" : "in-room") as HubStatus,
    };
  }, [room, snap]);

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

  // 방 비번(선택) — PIN 은 joinRequest 에만 실리고, 서버 onAuth 가 검증한다.
  const createRoom = useCallback((game?: string) => {
    const raw = window.prompt(KO.PIN_CREATE_PROMPT) ?? "";
    const pin = raw.replace(/\D/g, "");
    setJoinRequest({ kind: "create", ...(game ? { game } : {}), ...(pin.length >= 4 ? { pin } : {}) });
  }, []);
  const joinRoom = useCallback((id: string) => {
    const locked = rooms.find((r) => r.id === id)?.locked;
    if (!locked) {setJoinRequest({ kind: "join", id }); return;}
    const raw = window.prompt(KO.PIN_JOIN_PROMPT) ?? "";
    const pin = raw.replace(/\D/g, "");
    if (pin === "") {return;} // 취소 — 입장 중단
    setJoinRequest({ kind: "join", id, pin });
  }, [rooms]);

  const leaveRoom = useCallback(() => {
    localStorage.removeItem(HANDOFF.RESUME); // 의도적 퇴장 — 세션 종료
    clearMyRoom((k) => localStorage.removeItem(k)); // 멤버십도 폐기 — 더 이상 내 방 아님
    setMatchInfo(null);
    setJoinRequest(null); // useRoom 이 room.leave 를 수행하고, 리스트 룸이 다시 붙는다
  }, [setMatchInfo]);

  // 게임 종료 후: Godot 이 세션을 반납했으므로 페이지가 재입장해 대기실로 돌아간다.
  const returnToLobby = useCallback((_name: string) => {
    const roomId = matchInfo?.roomId;
    setMatchInfo(null);
    if (!room && roomId) {setJoinRequest({ kind: "join", id: roomId });}
    else if (!room) {setJoinRequest(null);}
  }, [room, matchInfo, setMatchInfo]);

  const startMatch = useCallback(() => room?.send(MSG.START, {}), [room]);

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
    resumeToken: derived?.resumeToken ?? "",
    error,
    matchInfo,
    connect,
    createRoom,
    joinRoom,
    leaveRoom,
    returnToLobby,
    startMatch,
    refreshRooms,
    tryResume,
    resuming: joinRequest?.kind === "resume",
    resumeFailed,
    myRoom,
  };
}
