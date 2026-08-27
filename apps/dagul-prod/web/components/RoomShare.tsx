"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { useRoomShare } from "@/hooks/useRoomShare";
import { hasRoomPassword } from "@/lib/hub/room-password";

interface Props {
  roomId: string;
  password: string;
}

export default function RoomShare({ roomId, password }: Props): JSX.Element {
  const t = useTranslations("room");
  const share = useRoomShare(roomId, hasRoomPassword(password) ? password : "");

  return (
    <div className="room-share">
      <p className="sec-title" id="room-share-label">{t("share")}</p>
      <p className="lock-hint">{t("shareHint")}</p>
      {share.svg ? (
        <div className="room-qr" aria-hidden="true" dangerouslySetInnerHTML={{ __html: share.svg }} />
      ) : null}
      {share.url ? <code className="share-url">{share.url}</code> : null}
      <button type="button" className="ghost" onClick={share.copy} disabled={!share.url}>
        {share.copied ? t("copied") : t("copyLink")}
      </button>
    </div>
  );
}
