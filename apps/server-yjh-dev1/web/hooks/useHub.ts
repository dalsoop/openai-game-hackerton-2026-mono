"use client";
// Colyseus 허브 훅 — @colyseus/react 공식 훅만 사용한다.
//   방 목록: useRoom + join 직후 핸들러 등록 (내장 LobbyRoom 실시간 리스팅)
//   방 연결: useRoom / 상태: useRoomState / 메시지: useRoomMessage
// 커스텀 수신: start/snap/peer_input(→ Godot 브릿지) + error.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Client, type Room, type RoomAvailable } from "@colyseus/sdk";
import { useRoom, useRoomState, useRoomMessage } from "@colyseus/react";
import { MSG, HANDOFF, ROOM_NAME, LIST_ROOM_NAME } from "@/lib/hub/config";
import { Roster, type RosterSnapshot } from "@/lib/domain/roster";
import type { HubRoom, HubPlayer, HubStatus, JoinRequest, BridgeableRoom, UseHubResult, MatchInfo } from "@/types";

let _client: Client | null = null;
function getClient(): Client {
  if (!_client) {_client = new Client(location.origin);}
  return _client;
}

// 인게임 핸드오프 — 브릿지는 없다. 매치 시작(START) 정보와 재접속 토큰을
// localStorage 에 남기고 방을 떠난다. Godot 가 공식 SDK reconnect(token) 으로
// 같은 세션·좌석을 이어받는다(서버 allowReconnection 유예 안에서).
function handOffToGodot(
  room: BridgeableRoom,
  onStarted: (payload: Record<string, unknown>) => void,
): void {
  room.onMessage(MSG.START, (payload: unknown): void => {
    try {
      localStorage.setItem(HANDOFF.MATCH, JSON.stringify(payload ?? {}));
      localStorage.setItem(HANDOFF.RESUME, room.reconnectionToken);
      localStorage.setItem(HANDOFF.FROM_HUB, "1");
    } catch { /* localStorage 불가 — 엔진이 토큰 없이 시도한다 */ }
    onStarted((payload ?? {}) as Record<string, unknown>);
    // 페이지 쪽 SDK 자동 재접속을 끈다 — 켜 두면 Godot 의 세션 승계와 싸운다.
    room.reconnection.enabled = false;
    // consent=false → close 코드 1000 이외 → 서버가 좌석을 allowReconnection 유예로 유지한다.
    room.leave(false);
  });
}

// 접속 상태 계산 — 훅 본문의 복잡도를 낮추기 위해 모듈 레벨로 뺐다.
function deriveStatus(
  derived: { status: HubStatus } | null,
  connected: boolean,
  lobbyErr: Error | undefined,
  lobbyConnecting: boolean,
  matchInfo: MatchInfo | null,
): HubStatus {
  if (matchInfo) {return "playing";} // 핸드오프 후 방을 떠났어도 매치는 진행 중
  if (derived) {return derived.status;}
  if (!connected) {return "offline";}
  if (lobbyErr) {return "offline";}
  if (lobbyConnecting) {return "connecting";}
  return "lobby";
}

export function useHub(_game: string): UseHubResult {
  const nameRef = useRef("");
  const [connected, setConnected] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [joinRequest, setJoinRequest] = useState<JoinRequest | null>(null);
  const [resumeFailed, setResumeFailed] = useState(false);
  const [matchInfo, setMatchInfo] = useState<MatchInfo | null>(null);

  // 방 목록 — 내장 리스트 룸 구독 (실시간, 폴링 없음).
  // useLobbyRoom 은 핸들러 등록이 passive effect 로 늦어져, 서버가 join 직후
  // 보내는 첫 전체 목록(MSG.ROOMS)이 등록 전에 도착하면 놓친다 — 그래서
  // join 프로미스 resolve 시점에 직접 등록한다 (마이크로태스크라 다음 WS 프레임보다 먼저).
  // 게임 방에 들어가 있는 동안엔 리스트 연결을 내려 자원을 아낀다.
  const [roomList, setRoomList] = useState<RoomAvailable[]>([]);
  const { error: lobbyErr, isConnecting: lobbyConnecting } = useRoom(
    connected && !joinRequest
      ? async (): Promise<Room> => {
          const list = await getClient().joinOrCreate(LIST_ROOM_NAME);
          list.onMessage(MSG.ROOMS, (r: RoomAvailable[]) => setRoomList(r));
          list.onMessage("+", ([roomId, room]: [string, RoomAvailable]) => {
            setRoomList((prev) => {
              const idx = prev.findIndex((x) => x.roomId === roomId);
              if (idx === -1) {return [...prev, room];}
              const next = [...prev];
              next[idx] = room;
              return next;
            });
          });
          list.onMessage("-", (roomId: string) => {
            setRoomList((prev) => prev.filter((x) => x.roomId !== roomId));
          });
          return list;
        }
      : null,
    [connected, joinRequest],
  );

  // 게임 방 연결 — 수명주기는 공식 훅이 소유한다 (StrictMode 안전).
  // START/onLeave 등록은 join resolve 직후에 한다 — 이펙트보다 늦으면
  // 입장과 동시에 온 START 를 놓친다 (리스트 룸과 같은 경주).
  const { room, error: roomError } = useRoom<RosterSnapshot>(
    joinRequest
      ? async (): Promise<Room<RosterSnapshot>> => {
          const r = joinRequest.kind === "create"
            ? await getClient().create(ROOM_NAME, { name: nameRef.current })
            : joinRequest.kind === "resume"
              ? await getClient().reconnect(localStorage.getItem(HANDOFF.RESUME) ?? "")
              : await getClient().joinById(joinRequest.id, { name: nameRef.current });
          handOffToGodot(r as unknown as BridgeableRoom, (payload): void => {
            setMatchInfo({
              roomId: r.roomId,
              name: nameRef.current,
              slot: Number(payload.you ?? -1),
              resumeToken: r.reconnectionToken,
            });
          });
          r.onLeave(() => {
            setJoinRequest(null); // Godot 양도/강제 단절 모두 — 캔버스가 있는 동안 UI 영향 없음
          });
          return r;
        }
      : null,
    [joinRequest],
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

  const rooms: HubRoom[] = useMemo(
    () =>
      roomList.map((r) => {
        const meta = (r.metadata ?? {}) as Record<string, unknown>;
        return {
          id: r.roomId,
          title: String(meta.title ?? r.roomId),
          players: r.clients,
          mode: String(meta.mode ?? ""),
          playing: meta.phase === "playing",
        };
      }),
    [roomList],
  );

  // 파생 사실은 도메인(Roster)이 계산한다.
  const derived = useMemo(() => {
    if (!room || !snap) {return null;}
    const roster = Roster.fromSnapshot(snap, room.sessionId);
    const players: HubPlayer[] = roster.seats.map((seat) => ({
      slot: seat.slot, id: seat.playerId, name: seat.name,
      host: seat.isHost, dropped: !seat.connected,
    }));
    return {
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

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- 리스트 룸(외부 시스템) 오류 → React 반영
    if (lobbyErr) {setError(lobbyErr.message);}
  }, [lobbyErr]);

  const connect = useCallback((name: string) => {
    nameRef.current = name;
    setError(null);
    setConnected(true);
  }, []);

  const createRoom = useCallback(() => setJoinRequest({ kind: "create" }), []);
  const joinRoom = useCallback((id: string) => setJoinRequest({ kind: "join", id }), []);

  const leaveRoom = useCallback(() => {
    localStorage.removeItem(HANDOFF.RESUME); // 의도적 퇴장 — 세션 종료
    setMatchInfo(null);
    setJoinRequest(null); // useRoom 이 room.leave 를 수행하고, 리스트 룸이 다시 붙는다
  }, []);

  // 게임 종료 후: Godot 이 세션을 반납했으므로 페이지가 재입장해 대기실로 돌아간다.
  const returnToLobby = useCallback((_name: string) => {
    const roomId = matchInfo?.roomId;
    setMatchInfo(null);
    if (!room && roomId) {setJoinRequest({ kind: "join", id: roomId });}
    else if (!room) {setJoinRequest(null);}
  }, [room, matchInfo]);

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
  };
}
