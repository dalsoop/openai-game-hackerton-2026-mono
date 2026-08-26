"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { connectedSeatsPacked, packKind } from "@/lib/domain/waiting-room-pack";
import type { Seat } from "@/lib/domain/roster";

interface Props {
  seats: Seat[];
  you: number;
}

export default function WaitingRoomPackList({ seats, you }: Props): JSX.Element | null {
  const t = useTranslations("room");
  const live = seats.filter((s) => s.connected);
  if (live.length === 0) {return null;}
  const pending = !connectedSeatsPacked(live);

  return (
    <div className="pack-list">
      <div className="pack-list-label">{pending ? t("downloading") : t("packReady")}</div>
      <ul className="pack-list-rows">
        {live.map((s) => {
          const kind = packKind(s.packPct);
          const status = {
            ready: t("packReady"),
            pending: t("packNotStarted"),
            progress: t("packProgress", { pct: s.packPct }),
          }[kind];
          return (
            <li key={s.slot} className={s.slot === you ? "pack-row me" : "pack-row"}>
              <span className="pack-name">
                {s.name}
                {s.slot === you ? ` (${t("me")})` : ""}
              </span>
              <div className="bar-track">
                {/* eslint-disable-next-line react/forbid-dom-props -- 진행률은 동적 폭 */}
                <div className={`bar-fill${s.packPct >= 100 ? " done" : ""}`} style={{ width: `${s.packPct}%` }} />
              </div>
              <span className="pack-pct">{status}</span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
