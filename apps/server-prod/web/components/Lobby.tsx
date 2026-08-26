"use client";
// 방 목록 — 멤버십 판정·정렬은 lib/room-membership(순수), 여기는 표현만.
// 방 만들기는 /create 페이지. 목록과 생성 폼을 한 화면에 두지 않는다.
import type { JSX } from "react";
import { useRefreshSpin } from "@/hooks/useRefreshSpin";
import type { HubRoom } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import { findGame } from "@/lib/games/catalog";
import { roomJoinable } from "@/lib/hub/room-mapper";
import { membershipOf, sortRoomsByMembership, type MyRoomIdentity } from "@/lib/room-membership";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";

interface Props {
  rooms: HubRoom[];
  myRoom: MyRoomIdentity | null;
  onJoin: (id: string) => void;
  onRefresh: () => void;
  refreshing?: boolean;
}

export default function Lobby({ rooms, myRoom, onJoin, onRefresh, refreshing = false }: Props): JSX.Element {
  const t = useTranslations("lobby");
  const games = useTranslations();
  const sorted = sortRoomsByMembership(rooms, myRoom);
  const spin = useRefreshSpin(refreshing);

  return (
    <div className="fade-in lobby-board">
      <div className="lobby-toolbar">
        <Link href="/create" className="cta lobby-create-link">
          {t("createButton")}
        </Link>
        <button type="button" className="ghost btn-icon" onClick={onRefresh} aria-label={t("refresh")} aria-busy={refreshing}>
          <span className={spin.className} aria-hidden="true" onAnimationIteration={spin.onAnimationIteration}>
            <span className="material-symbols-outlined">directory_sync</span>
          </span>
        </button>
      </div>

      <div className="sec-title">
        {t("title")} <span className="count-badge">{rooms.length}</span>
      </div>

      <div className="rooms">
        {sorted.length === 0 ? (
          <div className="empty-rooms">{t("emptyRooms")}</div>
        ) : (
          sorted.map((room) => {
            const { membership } = membershipOf(room, myRoom);
            const joinable = roomJoinable(room);
            const game = findGame(room.gameId);
            return (
              <div
                key={room.id}
                role="button"
                tabIndex={joinable ? 0 : -1}
                className={`room-card${membership !== "none" ? " mine" : ""}${joinable ? "" : " locked"}`}
                onClick={() => {if (joinable) {onJoin(room.id);}}}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && joinable) {onJoin(room.id);}
                }}
              >
                <div className="room-info">
                  <b>{room.title || `${t("room")} ${room.id}`}</b>
                  <span className="room-game-line">
                    {game ? games(game.titleKey) : t("room")}
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
    </div>
  );
}
