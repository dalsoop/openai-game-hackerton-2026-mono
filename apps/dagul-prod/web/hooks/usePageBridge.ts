"use client";
// React 방이 인게임 메시지를 Godot 으로만 넘긴다. Godot 는 허브 소켓을 열지 않는다.
import { useEffect, useRef } from "react";
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
  const attachedRef = useRef(false);
  // matchInfo 객체 신원이 아니라 방 id. StrictMode·resendStart 재생성으로 브릿지를 떼지 않는다.
  const matchRoomId = matchInfo?.roomId ?? "";
  useEffect(() => {
    if (!room || matchRoomId === "") {return;}
    const target = room;
    const off = attachPageBridge({
      send: (type, payload): void => {target.send(type, payload ?? {});},
    }, {
      onLeave: (): void => {void target.leave(ROOM_LEAVE.CONSENTED);},
    });
    // 재접속 세션은 직전 SNAP_OFF 가 남아 있을 수 있다. 엔진이 다시 끄기 전까지 JSON SNAP 을 연다.
    target.send(MSG.SNAP_ON, {});
    attachedRef.current = true;
    return (): void => {
      off();
      attachedRef.current = false;
      const leftover = target;
      // StrictMode 재부착은 같은 틱에 attached 가 다시 true. 그때는 opt-out 을 풀지 않는다.
      queueMicrotask(() => {
        if (attachedRef.current) {return;}
        leftover.send(MSG.SNAP_ON, {});
      });
    };
  }, [room, matchRoomId]);

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
