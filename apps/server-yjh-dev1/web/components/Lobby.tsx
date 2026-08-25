"use client";
// 방 목록 — 멤버십 판정·정렬은 lib/room-membership(순수), 여기는 표현만.
// 관전: 서버에 관전 슬롯 개념이 없어 제거 — 플레이 중 방은 입장 불가 표시.
import type { JSX } from "react";
import type { HubRoom } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import { GAME_CATALOG, DEFAULT_GAME_ID } from "@/lib/games/catalog";
import { membershipOf, sortRoomsByMembership, type MyRoomIdentity } from "@/lib/room-membership";
import { useTranslations } from "next-intl";

interface Props {
  rooms: HubRoom[];
  myRoom: MyRoomIdentity | null;
  onCreate: (game: string) => void;
  onJoin: (id: string) => void;
  onRefresh: () => void;
}

export default function Lobby({ rooms, myRoom, onCreate, onJoin, onRefresh }: Props): JSX.Element {
  const t = useTranslations("lobby");
  const sorted = sortRoomsByMembership(rooms, myRoom);

  return (
    <div className="fade-in">
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

      {/* 비제어 select — 폼 제출로 값을 읽는다(컴포넌트 상태 없음) */}
      <form
        className="create-row"
        onSubmit={(e) => {
          e.preventDefault();
          const data = new FormData(e.currentTarget);
          onCreate(String(data.get("game") ?? DEFAULT_GAME_ID));
        }}
      >
        <select className="game-select" name="game" defaultValue={DEFAULT_GAME_ID} aria-label={t("gameSelect")}>
          {GAME_CATALOG.map((g) => (
            <option key={g.id} value={g.id}>{t(g.titleKey)}</option>
          ))}
        </select>
        <button className="cta block" type="submit">
          {t("createButton")}
        </button>
      </form>
    </div>
  );
}
