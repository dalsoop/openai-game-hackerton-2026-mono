"use client";
// 방 목록 — 멤버십 판정·정렬은 lib/room-membership(순수), 여기는 표현만.
// 방 만들기는 /create 페이지. 목록과 생성 폼을 한 화면에 두지 않는다.
import type { JSX } from "react";
import { useRefreshSpin } from "@/hooks/useRefreshSpin";
import { useLobbyPinPrompt } from "@/hooks/useLobbyPinPrompt";
import type { HubRoom } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import { findGame, modeI18nKey } from "@/lib/games/catalog";
import { roomJoinable } from "@/lib/hub/room-mapper";
import { filterRoomsByQuery } from "@/lib/hub/room-search";
import {
  membershipOf, needsLeaveConfirm, sortRoomsByMembership, type MyRoomIdentity,
} from "@/lib/room-membership";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { MaterialIcon } from "@/components/MaterialIcon";
import PinBoxes from "@/components/PinBoxes";
import RoomSheet from "@/components/RoomSheet";
import { PIN_LENGTH } from "@/lib/hub/room-password";
import type { CcuSnapshot } from "@/lib/hub/ccu-plan";

interface Props {
  rooms: HubRoom[];
  myRoom: MyRoomIdentity | null;
  onJoin: (id: string, raw?: { password?: string }) => void;
  onForgetMyRoom: () => void;
  onRefresh: () => void;
  refreshing?: boolean;
  ccu?: CcuSnapshot | null;
}

export default function Lobby({
  rooms, myRoom, onJoin, onForgetMyRoom, onRefresh, refreshing = false, ccu = null,
}: Props): JSX.Element {
  const t = useTranslations("lobby");
  const congestion = useTranslations("congestion");
  const games = useTranslations();
  const pin = useLobbyPinPrompt();
  const sorted = filterRoomsByQuery(sortRoomsByMembership(rooms, myRoom), pin.query);
  const spin = useRefreshSpin(refreshing);
  const blocked = ccu !== null && !ccu.admit;

  return (
    <div className="fade-in lobby-board">
      {blocked && <p className="ccu-hint">{congestion("fullHint")}</p>}
      <div className="lobby-toolbar">
        <Link
          href="/create"
          className={`cta lobby-create-link${blocked ? " is-disabled" : ""}`}
          aria-disabled={blocked || undefined}
          onClick={(e) => {
            if (blocked) {e.preventDefault(); return;}
            if (!needsLeaveConfirm(myRoom, undefined, rooms)) {return;}
            if (!window.confirm(t("leaveRoomConfirm"))) {e.preventDefault(); return;}
            onForgetMyRoom();
          }}
        >
          {t("createButton")}
        </Link>
        <button type="button" className="ghost btn-icon" onClick={onRefresh} aria-label={t("refresh")} aria-busy={refreshing}>
          <span className={spin.className} aria-hidden="true" onAnimationIteration={spin.onAnimationIteration}>
            <MaterialIcon name="directory_sync" />
          </span>
        </button>
      </div>

      <label className="lobby-search">
        <span className="sec-title">{t("search")}</span>
        <input
          className="name-input"
          type="search"
          value={pin.query}
          onChange={(e) => {pin.setQuery(e.target.value);}}
          placeholder={t("searchPlaceholder")}
          autoComplete="off"
        />
      </label>

      <div className="sec-title">
        {t("title")} <span className="count-badge">{sorted.length}</span>
      </div>

      <div className="rooms">
        {sorted.length === 0 ? (
          <div className="empty-rooms">{t("emptyRooms")}</div>
        ) : (
          sorted.map((room) => {
            const { membership } = membershipOf(room, myRoom);
            const joinable = roomJoinable(room) && (membership !== "none" || !blocked);
            const game = findGame(room.gameId);
            const tryJoin = (): void => {
              if (!joinable) {return;}
              if (needsLeaveConfirm(myRoom, room.id, rooms)) {
                if (!window.confirm(t("leaveRoomConfirm"))) {return;}
                onForgetMyRoom();
              }
              if (room.hasPassword && membership === "none") {
                pin.openPin(room);
                return;
              }
              onJoin(room.id);
            };
            return (
              <div
                key={room.id}
                role="button"
                tabIndex={joinable ? 0 : -1}
                className={`room-card${membership !== "none" ? " mine" : ""}${joinable ? "" : " locked"}`}
                onClick={tryJoin}
                onKeyDown={(e) => {
                  if (e.key === "Enter") {tryJoin();}
                }}
              >
                <div className="room-info">
                  <b>
                    {room.hasPassword ? <span className="room-lock" aria-label={t("locked")}>🔒 </span> : null}
                    {room.title || `${t("room")} ${room.id}`}
                  </b>
                  <span className="room-game-line">
                    {room.mode
                      ? t("gameModeLine", {
                        game: game ? games(game.titleKey) : t("room"),
                        mode: lobbyModeText(t, room.mode),
                      })
                      : (game ? games(game.titleKey) : t("room"))}
                  </span>
                  <div className="room-pips" aria-hidden="true">
                    {Array.from({ length: HUB_CONFIG.maxPlayers }, (_, i) => (
                      <i key={i} className={i < room.players ? "on" : ""} />
                    ))}
                  </div>
                </div>
                <div className="room-aside">
                  {membership === "host" && (
                    <span className="room-mine-badge host">{t("mineHost")}</span>
                  )}
                  {membership === "member" && (
                    <span className="room-mine-badge">{t("mine")}</span>
                  )}
                  <span className="room-count">
                    {room.players}/{HUB_CONFIG.maxPlayers}
                  </span>
                  {room.playing ? (
                    <span className="room-playing">{t("inProgress")}</span>
                  ) : room.open ? (
                    <span className="room-enter">{t("join")}</span>
                  ) : (
                    <span className="room-playing">{t("closed")}</span>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {pin.pwRoom && (
        <RoomSheet labelledBy="pw-prompt-label" closeLabel={t("passwordCancel")} onClose={pin.closePin}>
          <form
            className="pw-modal"
            onSubmit={(e) => {
              e.preventDefault();
              const taken = pin.takePin();
              if (!taken) {return;}
              onJoin(taken.id, { password: taken.password });
            }}
          >
            <p className="sec-title" id="pw-prompt-label">{t("passwordPrompt", { title: pin.pwRoom.title || pin.pwRoom.id })}</p>
            <PinBoxes value={pin.pwDraft} onChange={pin.setPwDraft} labelledBy="pw-prompt-label" autoFocus />
            <div className="pw-modal-actions">
              <button type="button" className="ghost" onClick={pin.closePin}>{t("passwordCancel")}</button>
              <button type="submit" className="cta" disabled={pin.pwDraft.replace(/\D/g, "").length !== PIN_LENGTH}>{t("join")}</button>
            </div>
          </form>
        </RoomSheet>
      )}
    </div>
  );
}

function lobbyModeText(
  t: (key: "modes.classic" | "modes.full" | "modes.default") => string,
  mode: string,
): string {
  const key = modeI18nKey(mode);
  if (key === "classic") {return t("modes.classic");}
  if (key === "full") {return t("modes.full");}
  if (key === "default") {return t("modes.default");}
  return mode;
}
