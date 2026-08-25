"use client";
// 대기실 좌석 카드 1매 — 채움/내 자리/왕관/단절 상태 표시만 담당.
import type { JSX } from "react";
import type { HubPlayer } from "@/types";
import { useTranslations } from "next-intl";

interface SlotCardProps {
  index: number;
  player: HubPlayer | null;
  you: number;
}

export default function SlotCard({ index, player, you }: SlotCardProps): JSX.Element {
  const t = useTranslations("room");
  const isMe = index === you;
  const classes = ["slot-card", player && "filled", isMe && "me"].filter(Boolean).join(" ");

  return (
    <div className={classes}>
      {player ? (
        <>
          <div className={`slot-name c${index + 1}`}>
            {player.host && <span className="slot-crown">👑 </span>}
            {player.name}
            {isMe ? ` (${t("me")})` : ""}
          </div>
          <div className={`slot-tag ${player.dropped ? "bad" : player.host ? "cyan" : "ok"}`}>
            {player.dropped ? t("waitingReconnect") : player.host ? t("host") : t("waiting")}
          </div>
        </>
      ) : (
        <div className="slot-cpu">{t("cpuAtStart")}</div>
      )}
    </div>
  );
}
