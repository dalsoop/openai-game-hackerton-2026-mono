"use client";
// 방 목록 — 멤버십 판정·정렬은 lib/room-membership(순수), 여기는 표현만.
// 방 만들기는 /create 페이지. 목록과 생성 폼을 한 화면에 두지 않는다.
import type { JSX } from "react";
import type { HubRoom } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import { membershipOf, sortRoomsByMembership, type MyRoomIdentity } from "@/lib/room-membership";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";

interface Props {
  rooms: HubRoom[];
  myRoom: MyRoomIdentity | null;
  onJoin: (id: string) => void;
  onRefresh: () => void;
}

export default function Lobby({ rooms, myRoom, onJoin, onRefresh }: Props): JSX.Element {
  const t = useTranslations("lobby");
  const sorted = sortRoomsByMembership(rooms, myRoom);

  return (
    <div className="fade-in">
      <Link href="/create" className="cta block lobby-create-link">
        {t("createButton")}
      </Link>

      <div className="sec-title">
        {t("title")} <span className="count-badge">{rooms.length}</span>
        <button className="ghost btn-sm" onClick={onRefresh}>
          {t("refresh")}
        </button>
      </div>

      <div className="rooms">
        {sorted.length === 0 ? (
          <div className="empty-rooms">{t("emptyRooms")}</div>
        ) : (
          sorted.map((room) => {
            const { membership } = membershipOf(room, myRoom);
            return (
              <div
                key={room.id}
                role="button"
                tabIndex={0}
                className={`room-card${membership !== "none" ? " mine" : ""}`}
                onClick={() => !room.playing && onJoin(room.id)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !room.playing) {onJoin(room.id);}
                }}
              >
                <div className="room-info">
                  <b>{room.title || `${t("room")} ${room.id}`}</b>
                  <div className="room-pips">
                    {Array.from({ length: HUB_CONFIG.maxPlayers }, (_, i) => (
                      <i key={i} className={i < room.players ? "on" : ""} />
                    ))}
                  </div>
                </div>
                {membership === "host" && (
                  <span className="room-mine-badge host">{t("mineHost")}</span>
                )}
                {membership === "member" && (
                  <span className="room-mine-badge">{t("mine")}</span>
                )}
                <span className="room-mode-badge">
                  {room.mode === "full" ? t("modeFull") : room.mode}
                </span>
                <span className="room-count">
                  {room.players}/{HUB_CONFIG.maxPlayers}
                </span>
                {room.playing ? (
                  <span className="room-playing">{t("inProgress")}</span>
                ) : (
                  <span className="room-enter">{t("join")} →</span>
                )}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
