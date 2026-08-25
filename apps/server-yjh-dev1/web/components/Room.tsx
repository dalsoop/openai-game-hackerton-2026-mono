"use client";
// 대기실 화면 — 좌석 표시는 SlotCard, 여기선 배치·호스트 액션만.
import type { JSX } from "react";
import type { HubPlayer } from "@/types";
import { HUB_CONFIG } from "@/lib/hub/config";
import { GAME_CATALOG, findGame } from "@/lib/games/catalog";
import SlotCard from "@/components/SlotCard";
import { useTranslations } from "next-intl";

interface Props {
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  gameId: string;
  roomOpen: boolean;
  idleLeftSec: number;
  onStart: () => void;
  onLeave: () => void;
  onSetGame: (game: string) => void;
  onToggleRoom: () => void;
  canStart: boolean;
}

export default function Room({
  players, you, isHost, gameId, roomOpen, idleLeftSec,
  onStart, onLeave, onSetGame, onToggleRoom, canStart,
}: Props): JSX.Element {
  const t = useTranslations("room");
  const games = useTranslations();
  const current = findGame(gameId);
  const slots = Array.from(
    { length: HUB_CONFIG.maxPlayers },
    (_, i) => players.find((p) => p.slot === i) ?? null,
  );

  return (
    <div className="fade-in wait-panel">
      <header className="wait-head">
        <span className="wait-mode">{current ? games(current.titleKey) : t("title")}</span>
        <h1>{t("title")}</h1>
        {isHost && (
          <button type="button" className="ghost btn-sm" onClick={onToggleRoom}>
            {roomOpen ? t("close") : t("open")}
          </button>
        )}
        <button type="button" className="ghost danger" onClick={onLeave}>
          {t("leaveButton")}
        </button>
      </header>

      {idleLeftSec > 0 && (
        <p className="wait-idle">
          {isHost ? t("idleHost", { sec: idleLeftSec }) : t("idleGuest", { sec: idleLeftSec })}
        </p>
      )}

      {isHost ? (
        <fieldset className="wait-games">
          <legend className="sec-title">{t("changeGame")}</legend>
          <div className="wait-game-list">
            {GAME_CATALOG.map((g) => (
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
      ) : (
        <p className="wait-game-fixed">{current ? games(current.titleKey) : ""}</p>
      )}

      <div className="slots">
        {slots.map((player, i) => (
          // eslint-disable-next-line react/no-array-index-key -- 슬롯 인덱스가 곧 신원이다 (고정 좌석)
          <SlotCard key={i} index={i} player={player} you={you} />
        ))}
      </div>

      <div className="wait-summary">
        {t("playerCount", { count: players.length, max: HUB_CONFIG.maxPlayers })}
      </div>

      <div className="host-bar">
        {isHost ? (
          <button type="button" className="cta block" onClick={onStart} disabled={!canStart}>
            {t("startButton")}
          </button>
        ) : (
          <div className="host-wait">{t("waitingForHost")}</div>
        )}
      </div>
    </div>
  );
}
