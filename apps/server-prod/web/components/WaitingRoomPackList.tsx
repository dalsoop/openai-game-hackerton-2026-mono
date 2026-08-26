"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import type { PackSeat } from "@/lib/domain/waiting-room-pack";
import { allPacksReceived, packLabelKind } from "@/lib/domain/waiting-room-pack";

interface Props {
  seats: PackSeat[];
  you: number;
}

export default function WaitingRoomPackList({ seats, you }: Props): JSX.Element | null {
  const t = useTranslations("room");
  const humans = seats.filter((s) => s.present);
  if (humans.length === 0) {return null;}
  const pending = !allPacksReceived(humans);

  return (
    <div className="pack-list">
      <div className="pack-list-label">{pending ? t("downloading") : t("packReady")}</div>
      <ul className="pack-list-rows">
        {humans.map((s) => {
          const kind = packLabelKind(s.pct);
          const status = {
            ready: t("packReady"),
            pending: t("packNotStarted"),
            progress: t("packProgress", { pct: s.pct }),
          }[kind];
          return (
            <li key={s.slot} className={s.slot === you ? "pack-row me" : "pack-row"}>
              <span className="pack-name">
                {s.name}
                {s.slot === you ? ` (${t("me")})` : ""}
              </span>
              <div className="bar-track">
                {/* eslint-disable-next-line react/forbid-dom-props -- 진행률은 동적 폭 */}
                <div className={`bar-fill${s.pct >= 100 ? " done" : ""}`} style={{ width: `${s.pct}%` }} />
              </div>
              <span className="pack-pct">{status}</span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
