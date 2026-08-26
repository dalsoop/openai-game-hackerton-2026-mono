"use client";
import type { JSX } from "react";
import { slotBadge, type SlotBadge } from "@/lib/domain/waiting-room-pack";
import type { Seat } from "@/lib/domain/roster";
import { asCharacterId, findCharacter, stepCharacterId } from "@/lib/characters";
import CharacterPortrait from "@/components/CharacterPortrait";
import { useTranslations } from "next-intl";

interface SlotCardProps {
  index: number;
  player: Seat | null;
  you: number;
  onSetCharacter?: (characterId: string) => void;
}

const TAG_CLASS: Record<SlotBadge, string> = {
  reconnect: "bad",
  pending: "cyan",
  progress: "cyan",
  host: "cyan",
  waiting: "ok",
};

export default function SlotCard({ index, player, you, onSetCharacter }: SlotCardProps): JSX.Element {
  const t = useTranslations("room");
  const tx = useTranslations();
  const isMe = index === you;
  const classes = ["slot-card", player && "filled", isMe && "me"].filter(Boolean).join(" ");
  const badge = player ? slotBadge(player) : null;
  const character = player ? findCharacter(asCharacterId(player.characterId)) : undefined;
  const canPick = Boolean(isMe && character && onSetCharacter);
  const labels: Record<SlotBadge, string> = {
    reconnect: t("waitingReconnect"),
    pending: t("packNotStarted"),
    progress: t("packProgress", { pct: player?.packPct ?? 0 }),
    host: t("host"),
    waiting: t("waiting"),
  };

  return (
    <div className={classes}>
      {player && badge ? (
        <>
          {character ? (
            <div className="slot-char" aria-label={t("pickCharacter")}>
              {canPick ? (
                <button
                  type="button"
                  className="slot-char-btn"
                  aria-label={t("prevCharacter")}
                  onClick={() => {onSetCharacter?.(stepCharacterId(character.id, -1));}}
                >
                  {"<"}
                </button>
              ) : null}
              <CharacterPortrait characterId={character.id} size={44} title={tx(character.titleKey)} />
              {canPick ? (
                <button
                  type="button"
                  className="slot-char-btn"
                  aria-label={t("nextCharacter")}
                  onClick={() => {onSetCharacter?.(stepCharacterId(character.id, 1));}}
                >
                  {">"}
                </button>
              ) : null}
            </div>
          ) : null}
          {character ? <div className="slot-char-name">{tx(character.titleKey)}</div> : null}
          <div className={`slot-name c${index + 1}`}>
            {player.isHost && <span className="slot-crown">👑 </span>}
            {player.name}
            {isMe ? ` (${t("me")})` : ""}
          </div>
          <div className={`slot-tag ${TAG_CLASS[badge]}`}>{labels[badge]}</div>
        </>
      ) : (
        <div className="slot-cpu">{t("cpuAtStart")}</div>
      )}
    </div>
  );
}
