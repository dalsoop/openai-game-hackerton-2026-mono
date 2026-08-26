"use client";
import type { JSX } from "react";
import { slotBadge, type SlotBadge } from "@/lib/domain/waiting-room-pack";
import type { Seat } from "@/lib/domain/roster";
import { useTranslations } from "next-intl";

interface SlotCardProps {
  index: number;
  player: Seat | null;
  you: number;
}

const TAG_CLASS: Record<SlotBadge, string> = {
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
  const badge = player ? slotBadge(player) : null;
  const labels: Record<SlotBadge, string> = {
    reconnect: t("waitingReconnect"),
    pending: t("packNotStarted"),
    progress: t("packProgress", { pct: player?.packPct ?? 0 }),
    host: t("host"),
    waiting: t("waiting"),
  };

  return (
    <div className={classes}>
      {player && badge ? (
        <>
          <div className={`slot-name c${index + 1}`}>
            {player.isHost && <span className="slot-crown">👑 </span>}
            {player.name}
            {isMe ? ` (${t("me")})` : ""}
          </div>
          <div className={`slot-tag ${TAG_CLASS[badge]}`}>{labels[badge]}</div>
        </>
      ) : (
        <div className="slot-cpu">{t("cpuAtStart")}</div>
      )}
    </div>
  );
}
