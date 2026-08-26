"use client";
// 대기실 좌석 카드 1매 — 채움/내 자리/왕관/단절·받기 단계 표시만 담당.
import type { JSX } from "react";
import type { HubPlayer } from "@/types";
import { clampPct, seatTag, type SeatTag } from "@/lib/domain/download";
import { useTranslations } from "next-intl";

interface SlotCardProps {
  index: number;
  player: HubPlayer | null;
  you: number;
}

const TAG_CLASS: Record<SeatTag, string> = {
  reconnect: "bad",
  pending: "cyan",
  progress: "cyan",
  host: "cyan",
  waiting: "ok",
};

export default function SlotCard({ index, player, you }: SlotCardProps): JSX.Element {
  const t = useTranslations("room");
  const isMe = index === you;
  const classes = ["slot-card", player && "filled", isMe && "me"].filter(Boolean).join(" ");
  const pct = clampPct(player?.dlPct);
  const tag = seatTag(player?.dropped === true, pct, player?.host === true);
  const labels: Record<SeatTag, string> = {
    reconnect: t("waitingReconnect"),
    pending: t("dlNotStarted"),
    progress: t("dlProgress", { pct }),
    host: t("host"),
    waiting: t("waiting"),
  };

  return (
    <div className={classes}>
      {player ? (
        <>
          <div className={`slot-name c${index + 1}`}>
            {player.host && <span className="slot-crown">👑 </span>}
            {player.name}
            {isMe ? ` (${t("me")})` : ""}
          </div>
          <div className={`slot-tag ${TAG_CLASS[tag]}`}>{labels[tag]}</div>
        </>
      ) : (
        <div className="slot-cpu">{t("cpuAtStart")}</div>
      )}
    </div>
  );
}
