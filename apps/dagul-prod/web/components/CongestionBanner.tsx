"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import type { CcuSnapshot } from "@/lib/hub/ccu-plan";

interface Props {
  snap: CcuSnapshot | null;
}

export function CongestionBanner({ snap }: Props): JSX.Element | null {
  const t = useTranslations("congestion");
  if (!snap) {return null;}
  return (
    <div className={`ccu-banner ccu-${snap.level}`} role="status">
      <span className="ccu-level">{t(snap.level)}</span>
      <span className="ccu-count">{t("count", { ccu: snap.ccu, cap: snap.cap })}</span>
    </div>
  );
}
