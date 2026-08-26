"use client";
import { useEffect, useState } from "react";
import { DOM_EVT, MSG } from "@/lib/contract";
import { snapShowsMatchEnd } from "@/lib/game-flow-state";
import { parseBridgePacket } from "@/lib/hub/page-bridge";

/** SNAP result 가 끝나면 대기실 버튼을 켠다. */
export function useMatchOver(): boolean {
  const [over, setOver] = useState(false);
  useEffect(() => {
    const onTo = (ev: Event): void => {
      const packet = parseBridgePacket((ev as CustomEvent).detail);
      if (packet?.type === MSG.SNAP && snapShowsMatchEnd(packet.payload)) {setOver(true);}
    };
    window.addEventListener(DOM_EVT.TO_ENGINE, onTo);
    return (): void => window.removeEventListener(DOM_EVT.TO_ENGINE, onTo);
  }, []);
  return over;
}
