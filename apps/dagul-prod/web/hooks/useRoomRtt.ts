"use client";
// 게임 방 소켓의 왕복 지연 — 리스트 룸은 커스텀 메시지를 받지 않는다.
import { useEffect, useState } from "react";
import type { Room } from "@colyseus/sdk";
import { useRoomMessage } from "@colyseus/react";
import { MSG } from "@/lib/contract";
import { HUB_CONFIG } from "@/lib/hub/config";
import { parsePingStamp, rttFromPong } from "@/lib/hub/rtt";

export function useRoomRtt(room: Room | undefined): number {
  const [rttMs, setRttMs] = useState(0);

  useRoomMessage(room, MSG.PONG, (raw: unknown) => {
    const sent = parsePingStamp(raw);
    if (sent === null) {return;}
    const next = rttFromPong(sent, Date.now());
    if (next !== null) {setRttMs(next);}
  });

  useEffect(() => {
    if (!room) {return;}
    const beat = (): void => {room.send(MSG.PING, { t: Date.now() });};
    beat();
    const id = setInterval(beat, HUB_CONFIG.rttIntervalMs);
    return (): void => {clearInterval(id);};
  }, [room]);

  return room ? rttMs : 0;
}
