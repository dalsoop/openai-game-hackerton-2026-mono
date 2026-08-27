"use client";
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { findGame, visibleCatalog } from "@/lib/games/catalog";
import { MaterialIcon } from "@/components/MaterialIcon";
import RoomShare from "@/components/RoomShare";
import RoomLock from "@/components/RoomLock";
import RoomSheet from "@/components/RoomSheet";
import { useRoomSheet } from "@/hooks/useRoomSheet";

interface Props {
  isHost: boolean;
  gameId: string;
  roomId: string;
  password: string;
  onSetGame: (game: string) => void;
  onSetPassword: (password: string) => void;
  onSetLock: (on: boolean) => void;
}

export default function RoomTools({
  isHost, gameId, roomId, password, onSetGame, onSetPassword, onSetLock,
}: Props): JSX.Element {
  const t = useTranslations("room");
  const games = useTranslations();
  const sheet = useRoomSheet();
  const current = findGame(gameId);

  return (
    <>
      <div className="wait-tools">
        <button type="button" className="ghost wait-tool" onClick={() => {sheet.open("pin");}}>
          <MaterialIcon name="lock" />
          {t("pin")}
        </button>
        <button type="button" className="ghost wait-tool" onClick={() => {sheet.open("share");}}>
          <MaterialIcon name="qr_code_2" />
          {t("share")}
        </button>
        {isHost ? (
          <button type="button" className="ghost wait-tool" onClick={() => {sheet.open("game");}}>
            <MaterialIcon name="sports_esports" />
            {t("changeGame")}
          </button>
        ) : null}
        <span className="wait-game-fixed">{current ? games(current.titleKey) : ""}</span>
      </div>

      {sheet.kind === "pin" && (
        <RoomSheet labelledBy="room-pin-label" closeLabel={t("closePanel")} onClose={sheet.close}>
          <RoomLock
            password={password}
            isHost={isHost}
            onSetLock={onSetLock}
            onSetPassword={onSetPassword}
          />
        </RoomSheet>
      )}
      {sheet.kind === "share" && (
        <RoomSheet labelledBy="room-share-label" closeLabel={t("closePanel")} onClose={sheet.close}>
          <RoomShare roomId={roomId} password={password} />
        </RoomSheet>
      )}
      {sheet.kind === "game" && isHost && (
        <RoomSheet labelledBy="room-game-label" closeLabel={t("closePanel")} onClose={sheet.close}>
          <fieldset className="wait-games">
            <legend className="sec-title" id="room-game-label">{t("changeGame")}</legend>
            <div className="wait-game-list">
              {visibleCatalog().map((g) => (
                <label key={g.id} className={`wait-game${g.id === gameId ? " on" : ""}`}>
                  <input
                    type="radio"
                    name="room-game"
                    value={g.id}
                    checked={g.id === gameId}
                    onChange={() => {onSetGame(g.id);}}
                  />
                  <span>{games(g.titleKey)}</span>
                </label>
              ))}
            </div>
          </fieldset>
        </RoomSheet>
      )}
    </>
  );
}
