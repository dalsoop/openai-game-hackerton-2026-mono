"use client";
// React 방이 인게임 메시지를 Godot 으로만 넘긴다. Godot 는 허브 소켓을 열지 않는다.
import { useEffect, useRef } from "react";
import type { Room } from "@colyseus/sdk";
import { useRoomMessage } from "@colyseus/react";
import { MSG, ROOM_LEAVE } from "@/lib/contract";
import type { RosterSnapshot } from "@/lib/domain/roster";
import { lobbyStateHoldMs } from "@/lib/game-flow-state";
import { attachPageBridge, encodeHubState, postToEngine } from "@/lib/hub/page-bridge";
import type { MatchInfo } from "@/types";

export function usePageBridge(
  room: Room | undefined,
  matchInfo: MatchInfo | null,
  snap: RosterSnapshot | undefined,
  rttMs = 0,
): void {
  useEffect(() => {
    if (!room || !matchInfo) {return;}
    return attachPageBridge({
      send: (type, payload): void => {room.send(type, payload ?? {});},
    }, {
      onLeave: (): void => {void room.leave(ROOM_LEAVE.CONSENTED);},
    });
  }, [room, matchInfo]);

  useRoomMessage(room, MSG.SNAP, (raw: unknown) => {postToEngine(MSG.SNAP, raw);});
  useRoomMessage(room, MSG.PEER_INPUT, (raw: unknown) => {postToEngine(MSG.PEER_INPUT, raw);});
  useRoomMessage(room, MSG.GUN_FIRE, (raw: unknown) => {postToEngine(MSG.GUN_FIRE, raw);});
  useRoomMessage(room, MSG.ERROR, (raw: unknown) => {postToEngine(MSG.ERROR, raw);});

  const lastPostedPhase = useRef("");
  const holdUntilMs = useRef(0);
  useEffect(() => {
    if (!room || !matchInfo || !snap) {return;}
    const encoded = encodeHubState(snap, room.sessionId, rttMs);
    if (!encoded) {return;}
    const now = Date.now();
    if (holdUntilMs.current === 0) {
      const holdMs = lobbyStateHoldMs(lastPostedPhase.current, snap.phase);
      if (holdMs > 0) {holdUntilMs.current = now + holdMs;}
    }
    const left = holdUntilMs.current - now;
    if (snap.phase === "lobby" && left > 0) {
      const timer = window.setTimeout(() => {
        holdUntilMs.current = 0;
        lastPostedPhase.current = snap.phase;
        postToEngine(MSG.STATE, encoded);
      }, left);
      return (): void => {window.clearTimeout(timer);};
    }
    holdUntilMs.current = 0;
    lastPostedPhase.current = snap.phase;
    postToEngine(MSG.STATE, encoded);
  }, [room, matchInfo, snap, rttMs]);
}
