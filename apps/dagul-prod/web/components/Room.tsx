"use client";
// 대기실 화면 — 좌석 표시는 SlotCard, 여기선 배치·호스트 액션만.
import type { JSX } from "react";
import type { Seat } from "@/lib/domain/roster";
import { HUB_CONFIG } from "@/lib/hub/config";
import { modeI18nKey } from "@/lib/games/catalog";
import SlotCard from "@/components/SlotCard";
import RoomTools from "@/components/RoomTools";
import { MaterialIcon } from "@/components/MaterialIcon";
import { useTranslations } from "next-intl";
import { playOkButton } from "@/lib/ui-sfx";
import { lobbyLeaveLocked } from "@/lib/domain/waiting-room-start";

interface Props {
  players: Seat[];
  you: number;
  isHost: boolean;
  gameId: string;
  mode: string;
  roomOpen: boolean;
  idleLeftSec: number;
  onStart: () => void;
  onLeave: () => void;
  onSetGame: (game: string) => void;
  onToggleRoom: () => void;
  onSetCharacter: (characterId: string) => void;
  onKick: (slot: number) => void;
  onSetPassword: (password: string) => void;
  onSetLock: (on: boolean) => void;
  roomId: string;
  password: string;
  matchWait: boolean;
  canStart: boolean;
  connClass: string;
  connText: string;
  rttMs: number;
  rttText: string | null;
  startInSec: number;
}

export default function Room({
  players, you, isHost, gameId, mode, idleLeftSec,
  onStart, onLeave, onSetGame, onSetCharacter, onKick, onSetPassword, onSetLock, canStart,
  roomId, password, matchWait, rttMs, startInSec,
}: Props): JSX.Element {
  const t = useTranslations("room");
  const leaveLocked = lobbyLeaveLocked(startInSec);
  const counting = startInSec > 0;
  const slots = Array.from(
    { length: HUB_CONFIG.maxPlayers },
    (_, i) => players.find((p) => p.slot === i) ?? null,
  );

  return (
    <div className="fade-in wait-panel">
      <div className="back-row">
        <button
          type="button"
          className="ghost btn-icon"
          onClick={onLeave}
          disabled={leaveLocked}
          aria-label={leaveLocked ? t("leaveLocked") : t("leaveButton")}
        >
          <MaterialIcon name="undo" />
        </button>
        <div className="wait-line">
          <span className="wait-title-inline">{t("title")}</span>
          <span className="wait-mode">{modeText(t, mode)}</span>
        </div>
      </div>

      {matchWait && <p className="wait-match">{t("matchWait")}</p>}
      {counting && (
        <p className="wait-start-count" data-lock={leaveLocked || undefined}>
          {t("startCountdown", { sec: startInSec })}
        </p>
      )}

      <RoomTools
        isHost={isHost}
        gameId={gameId}
        roomId={roomId}
        password={password}
        onSetGame={onSetGame}
        onSetPassword={onSetPassword}
        onSetLock={onSetLock}
      />

      <div className="slots">
        {slots.map((player, i) => (
          <SlotCard
            // eslint-disable-next-line react/no-array-index-key -- 슬롯 인덱스가 곧 신원이다 (고정 좌석)
            key={i}
            index={i}
            player={player}
            you={you}
            onSetCharacter={onSetCharacter}
            onKick={isHost ? onKick : undefined}
            pingMs={i === you ? rttMs : 0}
          />
        ))}
      </div>

      <div className="wait-summary">
        {t("playerCount", { count: players.length, max: HUB_CONFIG.maxPlayers })}
      </div>

      <div className="host-bar">
        {isHost ? (
          <button
            type="button"
            className="cta block"
            data-sfx="ok"
            onClick={() => {
              playOkButton();
              onStart();
            }}
            disabled={!canStart || counting}
          >
            {counting ? t("startCountdown", { sec: startInSec }) : t("startButton")}
          </button>
        ) : (
          <div className="host-wait">{t("waitingForHost")}</div>
        )}
      </div>
      {idleLeftSec > 0 && (
        <p className="wait-idle-inline">
          {isHost ? t("idleHost", { sec: idleLeftSec }) : t("idleGuest", { sec: idleLeftSec })}.
        </p>
      )}

    </div>
  );
}

function modeText(t: (key: "modes.classic" | "modes.full" | "modes.default") => string, mode: string): string {
  const key = modeI18nKey(mode);
  if (key === "classic") {return t("modes.classic");}
  if (key === "full") {return t("modes.full");}
  if (key === "default") {return t("modes.default");}
  return mode;
}
