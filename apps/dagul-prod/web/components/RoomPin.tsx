"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { MaterialIcon } from "@/components/MaterialIcon";
import PinBoxes from "@/components/PinBoxes";
import { generateRoomPin } from "@/lib/hub/room-password";

interface Props {
  password: string;
  isHost: boolean;
  onSetPassword: (password: string) => void;
  showHeading?: boolean;
}

export default function RoomPin({ password, isHost, onSetPassword, showHeading = true }: Props): JSX.Element {
  const t = useTranslations("room");

  return (
    <div className="room-pin">
      {showHeading ? <span className="sec-title" id="room-pin-label">{t("pin")}</span> : null}
      <div className="room-pin-row">
        <PinBoxes value={password} onChange={() => undefined} disabled labelledBy="room-pin-label" />
        {isHost ? (
          <button
            type="button"
            className="ghost btn-icon"
            aria-label={t("pinEdit")}
            onClick={() => {
              if (!window.confirm(t("pinShuffleConfirm"))) {return;}
              onSetPassword(generateRoomPin());
            }}
          >
            <MaterialIcon name="lock_reset" />
          </button>
        ) : null}
      </div>
    </div>
  );
}
