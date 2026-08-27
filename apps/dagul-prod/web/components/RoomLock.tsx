"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import RoomPin from "@/components/RoomPin";
import { hasRoomPassword } from "@/lib/hub/room-password";

interface Props {
  password: string;
  isHost: boolean;
  onSetLock: (on: boolean) => void;
  onSetPassword: (password: string) => void;
}

export default function RoomLock({ password, isHost, onSetLock, onSetPassword }: Props): JSX.Element {
  const t = useTranslations("room");
  const locked = hasRoomPassword(password);

  return (
    <div className="room-lock-panel">
      <p className="sec-title" id="room-pin-label">{t("pin")}</p>
      {isHost ? (
        <label className="lock-row">
          <span className="sec-title">{t("lock")}</span>
          <input
            className="lock-switch"
            type="checkbox"
            role="switch"
            aria-checked={locked}
            checked={locked}
            onChange={(e) => {onSetLock(e.target.checked);}}
          />
        </label>
      ) : null}
      {locked ? (
        <RoomPin password={password} isHost={isHost} onSetPassword={onSetPassword} showHeading={false} />
      ) : (
        <p className="lock-hint">{isHost ? t("lockOffHint") : t("lockOffGuest")}</p>
      )}
    </div>
  );
}
