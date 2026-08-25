"use client";
// 대기실 화면 — 좌석 표시는 SlotCard, 여기선 배치·호스트 액션만.
import type { JSX } from "react";
import type { HubPlayer } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import SlotCard from "@/components/SlotCard";
import { useTranslations } from "next-intl";

interface Props {
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  onStart: () => void;
  onLeave: () => void;
  canStart: boolean;
}

export default function Room({ players, you, isHost, onStart, onLeave, canStart }: Props): JSX.Element {
  const t = useTranslations("room");
  const slots = Array.from(
    { length: HUB_CONFIG.maxPlayers },
    (_, i) => players.find((p) => p.slot === i) ?? null,
  );

  return (
    <div className="fade-in">
      <header className="wait-head">
        <span className="wait-mode">{t("mode")}</span>
        <h1>{t("title")}</h1>
        <button className="ghost danger" onClick={onLeave}>
          {t("leaveButton")}
        </button>
      </header>

      <div className="slots">
        {slots.map((player, i) => (
          // eslint-disable-next-line react/no-array-index-key -- 슬롯 인덱스가 곧 신원이다 (고정 좌석)
          <SlotCard key={i} index={i} player={player} you={you} />
        ))}
      </div>

      <div className="wait-summary">
        {t("playerCount", { count: players.length, max: HUB_CONFIG.maxPlayers })}
      </div>

      <div className="host-bar">
        {isHost ? (
          <button className="cta block" onClick={onStart} disabled={!canStart}>
            {t("startButton")}
          </button>
        ) : (
          <div className="host-wait">{t("waitingForHost")}</div>
        )}
      </div>
    </div>
  );
}
