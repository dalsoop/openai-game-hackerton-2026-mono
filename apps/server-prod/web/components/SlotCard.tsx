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
  pingMs?: number;
}

const TAG_CLASS: Record<SlotBadge, string> = {
  reconnect: "bad",
  pending: "cyan",
  progress: "cyan",
  host: "cyan",
  waiting: "ok",
};

function SlotCharacterPicker({
  characterId,
  title,
  canPick,
  pickLabel,
  prevLabel,
  nextLabel,
  onSetCharacter,
}: {
  characterId: string;
  title: string;
  canPick: boolean;
  pickLabel: string;
  prevLabel: string;
  nextLabel: string;
  onSetCharacter?: (characterId: string) => void;
}): JSX.Element {
  return (
    <div className="slot-char" aria-label={pickLabel}>
      {canPick ? (
        <button
          type="button"
          className="slot-char-btn"
          aria-label={prevLabel}
          onClick={() => {onSetCharacter?.(stepCharacterId(characterId, -1));}}
        >
          {"<"}
        </button>
      ) : null}
      <CharacterPortrait characterId={characterId} size={44} title={title} />
      {canPick ? (
        <button
          type="button"
          className="slot-char-btn"
          aria-label={nextLabel}
          onClick={() => {onSetCharacter?.(stepCharacterId(characterId, 1));}}
        >
          {">"}
        </button>
      ) : null}
    </div>
  );
}

export default function SlotCard({ index, player, you, onSetCharacter, pingMs = 0 }: SlotCardProps): JSX.Element {
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
      {isMe && pingMs > 0 && <span className="slot-ping">{pingMs}ms</span>}
      {player && badge ? (
        <>
          {character ? (
            <SlotCharacterPicker
              characterId={character.id}
              title={tx(character.titleKey)}
              canPick={canPick}
              pickLabel={t("pickCharacter")}
              prevLabel={t("prevCharacter")}
              nextLabel={t("nextCharacter")}
              onSetCharacter={onSetCharacter}
            />
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
