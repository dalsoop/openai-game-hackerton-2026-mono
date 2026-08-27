"use client";
// 게임 방 연결 훅 — 수명주기는 공식 useRoom 이 소유한다 (StrictMode 안전).
// START/onLeave 등록은 join resolve 직후에 한다 — 이펙트보다 늦으면
// 입장과 동시에 온 START 를 놓친다 (리스트 룸과 같은 경주).
import { useEffect, useRef, useState } from "react";
import type { Client, Room } from "@colyseus/sdk";
import { useRoom } from "@colyseus/react";
import { MSG, HANDOFF } from "@/lib/contract";
import { clearEngineHandoff } from "@/lib/godot/handoff";
import { clearMyRoom } from "@/lib/room-membership";
import { ROOM_NAME } from "@/lib/hub/config";
import { forgetHubPin, matchmakePin, rememberHubPin } from "@/lib/hub/public-address";
import { hubLimits, parseRoomSettings } from "@/lib/hub/room-options";
import { seatClaimNow } from "@/lib/guest-identity";
import { roomEndKindFromCode, type RoomEndKind } from "@/lib/hub/room-end";
import {
  matchInfoFromPlayingState, matchInfoFromStoredStart, parseStartPayload, type StartPayload,
} from "@/lib/hub/start-payload";
import type { RosterSnapshot } from "@/lib/domain/roster";
import type { JoinRequest, BridgeableRoom, MatchInfo } from "@/types";

export type { RoomEndKind };

function restoreMatchHandoff(
  room: {
    roomId: string;
    sessionId: string;
    reconnectionToken: string;
    state?: RosterSnapshot & { seed?: unknown };
  },
  name: string,
): MatchInfo | null {
  const roomMeta = {
    roomId: room.roomId,
    reconnectionToken: room.reconnectionToken,
    gameId: room.state?.gameId,
  };
  const stored = matchInfoFromStoredStart(
    sessionStorage.getItem(HANDOFF.MATCH),
    roomMeta,
    name,
  );
  if (stored) {return stored;}
  return matchInfoFromPlayingState(room.state, room.sessionId, roomMeta, name);
}

// 인게임 핸드오프 — START 정보와 재접속 토큰을 sessionStorage 에 남긴다.
// 탭 스코프로 둬야 새 탭이 남의 재접속 토큰을 주워 자동 reconnect 하지 않는다.
// 허브 소켓은 React 가 유지한다. Godot 는 페이지 브릿지로만 I/O 한다.
function persistMatchForEngine(
  room: BridgeableRoom,
  onStarted: (payload: StartPayload) => void,
): void {
  room.onMessage(MSG.START, (raw: unknown): void => {
    const payload = parseStartPayload(raw);
    if (!payload) {return;}
    try {
      sessionStorage.setItem(HANDOFF.MATCH, JSON.stringify(payload));
      sessionStorage.setItem(HANDOFF.RESUME, room.reconnectionToken);
      sessionStorage.setItem(HANDOFF.FROM_HUB, "1");
    } catch { /* sessionStorage 불가 — 엔진은 MATCH 없이 부팅한다 */ }
    onStarted(payload);
  });
}

export function useGameRoom(
  joinRequest: JoinRequest | null,
  playerName: () => string,
  getClient: (pin?: string | null) => Client,
  onRoomEnded: (kind: RoomEndKind) => void,
  onResumeFailed: (message: string) => void,
): {
  room: Room<RosterSnapshot> | undefined;
  roomError: Error | undefined;
  matchInfo: MatchInfo | null;
  setMatchInfo: (m: MatchInfo | null) => void;
} {
  const [matchInfo, setMatchInfo] = useState<MatchInfo | null>(null);
  // resume 시도에 실제로 쓴 토큰 — 실패 시 "이 토큰이 지금도 유효한 삭제 대상인지" 대조용.
  const resumeAttemptToken = useRef<string | null>(null);

  const { room, error: roomError } = useRoom<RosterSnapshot>(
    joinRequest
      ? async (): Promise<Room<RosterSnapshot>> => {
          const settings = parseRoomSettings({
            name: playerName(),
            game: joinRequest.kind === "create" ? joinRequest.game : undefined,
            title: joinRequest.kind === "create" ? joinRequest.title : undefined,
          }, hubLimits(""));
          const client = getClient(
            matchmakePin(joinRequest.kind, joinRequest.kind === "join" ? joinRequest.id : undefined),
          );
          // 좌석 이어받기 증명(쿠키) — 같은 브라우저의 새 창이 기존 좌석을 넘겨받게 한다.
          const claim = seatClaimNow() ?? {};
          const r = joinRequest.kind === "create"
            ? await client.create(ROOM_NAME, { name: settings.name, game: settings.game, title: settings.title, ...claim })
            : joinRequest.kind === "resume"
              ? await ((): Promise<Room<RosterSnapshot>> => {
                  const token = sessionStorage.getItem(HANDOFF.RESUME) ?? "";
                  resumeAttemptToken.current = token;
                  return client.reconnect(token);
                })()
              : await client.joinById(joinRequest.id, { name: settings.name, ...claim });
          rememberHubPin(r.connection.url, r.roomId);
          persistMatchForEngine(r as unknown as BridgeableRoom, (payload): void => {
            setMatchInfo({
              roomId: r.roomId,
              name: playerName(),
              slot: payload.you,
              resumeToken: r.reconnectionToken,
              match: payload,
              gameId: (r.state as RosterSnapshot | undefined)?.gameId,
            });
          });
          const restored = restoreMatchHandoff(r, playerName());
          if (restored) {setMatchInfo(restored);}
          r.onLeave((code?: number) => {
            const kind = roomEndKindFromCode(code);
            if (kind === "consented") {
              clearMyRoom((k) => localStorage.removeItem(k));
            }
            setMatchInfo(null);
            onRoomEnded(kind);
          });
          return r;
        }
      : null,
    [joinRequest],
  );

  // 재개(resume) 실패 — 세션 유예 만료. 토큰 폐기는 이 훅이, 화면 초기화는 콜백이 담당한다.
  // 방금 시도했던 토큰이 저장소 값과 다르면(그 사이 새 매치가 시작돼 토큰이 갱신된 경우) 건드리지 않는다.
  useEffect(() => {
    if (!roomError) {return;}
    if (joinRequest?.kind !== "resume") {return;}
    if (sessionStorage.getItem(HANDOFF.RESUME) !== resumeAttemptToken.current) {return;}
    clearEngineHandoff(true);
    forgetHubPin();
    onResumeFailed(roomError.message);
  }, [roomError, joinRequest, onResumeFailed]);

  return { room, roomError, matchInfo, setMatchInfo };
}
