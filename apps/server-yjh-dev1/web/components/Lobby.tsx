"use client";
import type { JSX } from "react";
import type { HubRoom } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import { useTranslations } from "next-intl";

interface Props {
  rooms: HubRoom[];
  onCreate: () => void;
  onJoin: (id: string) => void;
  onRefresh: () => void;
}

export default function Lobby({ rooms, onCreate, onJoin, onRefresh }: Props): JSX.Element {
  const t = useTranslations("lobby");

  return (
    <div className="fade-in">
      <div className="sec-title">
        {t("title")} <span className="count-badge">{rooms.length}</span>
        <button className="ghost btn-sm" onClick={onRefresh}>
          {t("refresh")}
        </button>
      </div>

      <div className="rooms">
        {rooms.length === 0 ? (
          <div className="empty-rooms">{t("emptyRooms")}</div>
        ) : (
          rooms.map((room) => (
            <div
              key={room.id}
              role="button"
              tabIndex={0}
              className="room-card"
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
              <span className="room-mode-badge">
                {room.mode === "full" ? t("modeFull") : room.mode}
              </span>
              <span className="room-count">
                {room.players}/{HUB_CONFIG.maxPlayers}
              </span>
              {room.playing ? (
                <button
                  className="ghost"
                  onClick={(e) => {
                    e.stopPropagation();
                    onJoin(room.id);
                  }}
                >
                  {t("spectate")}
                </button>
              ) : (
                <span className="room-enter">{t("join")} →</span>
              )}
            </div>
          ))
        )}
      </div>

      <button className="cta block" onClick={onCreate}>
        {t("createButton")}
      </button>
    </div>
  );
}
