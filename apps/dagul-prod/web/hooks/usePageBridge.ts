"use client";
// React 방이 인게임 메시지를 Godot 으로만 넘긴다. Godot 는 허브 소켓을 열지 않는다.
import { useEffect } from "react";
import type { Room } from "@colyseus/sdk";
import { useRoomMessage } from "@colyseus/react";
import { MSG, ROOM_LEAVE } from "@/lib/contract";
import type { RosterSnapshot } from "@/lib/domain/roster";
import { attachPageBridge, encodeHubState, postToEngine, rememberInboundSnap } from "@/lib/hub/page-bridge";
import type { MatchInfo } from "@/types";

export function usePageBridge(
  room: Room | undefined,
  matchInfo: MatchInfo | null,
  snap: RosterSnapshot | undefined,
  rttMs = 0,
): void {
  useEffect(() => {
    if (!room || !matchInfo) {return;}
    const off = attachPageBridge({
      send: (type, payload): void => {room.send(type, payload ?? {});},
    }, {
      onLeave: (): void => {void room.leave(ROOM_LEAVE.CONSENTED);},
    });
    // 재접속 세션은 직전 SNAP_OFF 가 남아 있을 수 있다. 엔진이 다시 끄기 전까지 JSON SNAP 을 연다.
    room.send(MSG.SNAP_ON, {});
    return (): void => {
      // 엔진이 SNAP_OFF 만 보내고 죽으면 죽은 세션이 opt-out 에 남아 2회차 SNAP 이 끊긴다.
      room.send(MSG.SNAP_ON, {});
      off();
    };
  }, [room, matchInfo]);

  useRoomMessage(room, MSG.SNAP, (raw: unknown) => {
    rememberInboundSnap(raw);
    postToEngine(MSG.SNAP, raw);
  });
  useRoomMessage(room, MSG.GUN_FIRE, (raw: unknown) => {postToEngine(MSG.GUN_FIRE, raw);});
  useRoomMessage(room, MSG.ERROR, (raw: unknown) => {postToEngine(MSG.ERROR, raw);});

  useEffect(() => {
    if (!room || !matchInfo || !snap) {return;}
    const encoded = encodeHubState(snap, room.sessionId, rttMs);
    if (encoded) {postToEngine(MSG.STATE, encoded);}
  }, [room, matchInfo, snap, rttMs]);
}
