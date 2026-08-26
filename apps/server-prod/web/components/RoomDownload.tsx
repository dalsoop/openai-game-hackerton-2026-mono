"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import type { SeatDownload } from "@/lib/domain/download";
import { allSeatsReady, labelKind } from "@/lib/domain/download";

interface Props {
  seats: SeatDownload[];
  you: number;
}

export default function RoomDownload({ seats, you }: Props): JSX.Element | null {
  const t = useTranslations("room");
  const humans = seats.filter((s) => s.present);
  if (humans.length === 0) {return null;}
  const pending = !allSeatsReady(humans);

  return (
    <div className="room-download">
      <div className="dl-label">{pending ? t("downloading") : t("dlReady")}</div>
      <ul className="dl-roster">
        {humans.map((s) => {
          const kind = labelKind(s.pct);
          const status = {
            ready: t("dlReady"),
            pending: t("dlNotStarted"),
            progress: t("dlProgress", { pct: s.pct }),
          }[kind];
          return (
            <li key={s.slot} className={s.slot === you ? "dl-row me" : "dl-row"}>
              <span className="dl-name">
                {s.name}
                {s.slot === you ? ` (${t("me")})` : ""}
              </span>
              <div className="bar-track">
                {/* eslint-disable-next-line react/forbid-dom-props -- 진행률은 동적 폭 */}
                <div className={`bar-fill${s.pct >= 100 ? " done" : ""}`} style={{ width: `${s.pct}%` }} />
              </div>
              <span className="dl-pct">{status}</span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
