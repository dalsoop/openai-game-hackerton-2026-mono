"use client";
// 게임 방 연결 훅 — 수명주기는 공식 useRoom 이 소유한다 (StrictMode 안전).
// START/onLeave 등록은 join resolve 직후에 한다 — 이펙트보다 늦으면
// 입장과 동시에 온 START 를 놓친다 (리스트 룸과 같은 경주).
import { useEffect, useState } from "react";
import type { Client, Room } from "@colyseus/sdk";
import { useRoom } from "@colyseus/react";
import { MSG, HANDOFF } from "@/lib/contract";
import { ROOM_NAME } from "@/lib/hub/config";
import { hubLimits, parseRoomSettings } from "@/lib/hub/room-options";
import { roomEndKindFromCode, type RoomEndKind } from "@/lib/hub/room-end";
import { matchInfoFromStoredStart, parseStartPayload, type StartPayload } from "@/lib/hub/start-payload";
import type { RosterSnapshot } from "@/lib/domain/roster";
import type { JoinRequest, BridgeableRoom, MatchInfo } from "@/types";

export type { RoomEndKind };

// 인게임 핸드오프 — START 정보와 재접속 토큰을 localStorage 에 남긴다.
// 허브 소켓은 React 가 유지한다. Godot 는 페이지 브릿지로만 I/O 한다.
function persistMatchForEngine(
  room: BridgeableRoom,
  onStarted: (payload: StartPayload) => void,
): void {
  room.onMessage(MSG.START, (raw: unknown): void => {
    const payload = parseStartPayload(raw);
    if (!payload) {return;}
    try {
      localStorage.setItem(HANDOFF.MATCH, JSON.stringify(payload));
      localStorage.setItem(HANDOFF.RESUME, room.reconnectionToken);
      localStorage.setItem(HANDOFF.FROM_HUB, "1");
    } catch { /* localStorage 불가 — 엔진은 MATCH 없이 부팅한다 */ }
    onStarted(payload);
  });
}

export function useGameRoom(
  joinRequest: JoinRequest | null,
  playerName: () => string,
  getClient: () => Client,
  onRoomEnded: (kind: RoomEndKind) => void,
  onResumeFailed: (message: string) => void,
): {
  room: Room<RosterSnapshot> | undefined;
  roomError: Error | undefined;
  matchInfo: MatchInfo | null;
  setMatchInfo: (m: MatchInfo | null) => void;
} {
  const [matchInfo, setMatchInfo] = useState<MatchInfo | null>(null);

  const { room, error: roomError } = useRoom<RosterSnapshot>(
    joinRequest
      ? async (): Promise<Room<RosterSnapshot>> => {
          const settings = parseRoomSettings({
            name: playerName(),
            game: joinRequest.kind === "create" ? joinRequest.game : undefined,
            title: joinRequest.kind === "create" ? joinRequest.title : undefined,
          }, hubLimits(""));
          const r = joinRequest.kind === "create"
            ? await getClient().create(ROOM_NAME, { name: settings.name, game: settings.game, title: settings.title })
            : joinRequest.kind === "resume"
              ? await getClient().reconnect(localStorage.getItem(HANDOFF.RESUME) ?? "")
              : await getClient().joinById(joinRequest.id, { name: settings.name });
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
          const restored = matchInfoFromStoredStart(
            localStorage.getItem(HANDOFF.MATCH),
            {
              roomId: r.roomId,
              reconnectionToken: r.reconnectionToken,
              gameId: (r.state as RosterSnapshot | undefined)?.gameId,
            },
            playerName(),
          );
          if (restored) {setMatchInfo(restored);}
          r.onLeave((code?: number) => {
            setMatchInfo(null);
            onRoomEnded(roomEndKindFromCode(code));
          });
          return r;
        }
      : null,
    [joinRequest],
  );

  // 재개(resume) 실패 — 세션 유예 만료. 토큰 폐기는 이 훅이, 화면 초기화는 콜백이 담당한다.
  useEffect(() => {
    if (!roomError) {return;}
    if (joinRequest?.kind !== "resume") {return;}
    localStorage.removeItem(HANDOFF.RESUME);
    localStorage.removeItem(HANDOFF.FROM_HUB);
    localStorage.removeItem(HANDOFF.MATCH);
    onResumeFailed(roomError.message);
  }, [roomError, joinRequest, onResumeFailed]);

  return { room, roomError, matchInfo, setMatchInfo };
}
