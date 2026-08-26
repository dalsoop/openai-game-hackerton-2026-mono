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

function SlotFilledBody({
  index,
  player,
  you,
  onSetCharacter,
}: {
  index: number;
  player: Seat;
  you: number;
  onSetCharacter?: (characterId: string) => void;
}): JSX.Element {
  const t = useTranslations("room");
  const tx = useTranslations();
  const isMe = index === you;
  const badge = slotBadge(player);
  const character = findCharacter(asCharacterId(player.characterId));
  const canPick = Boolean(isMe && character && onSetCharacter);
  const labels: Record<SlotBadge, string> = {
    reconnect: t("waitingReconnect"),
    pending: t("packDownloading", { pct: player.packPct }),
    progress: t("packDownloading", { pct: player.packPct }),
    host: t("host"),
    waiting: t("waiting"),
  };
  return (
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
  );
}

export default function SlotCard({ index, player, you, onSetCharacter, pingMs = 0 }: SlotCardProps): JSX.Element {
  const t = useTranslations("room");
  const conn = useTranslations("connection");
  const isMe = index === you;
  const classes = ["slot-card", player && "filled", isMe && "me"].filter(Boolean).join(" ");
  return (
    <div className={classes}>
      {isMe && pingMs > 0 && <span className="slot-ping">{conn("ping", { ms: pingMs })}</span>}
      {player ? (
        <SlotFilledBody index={index} player={player} you={you} onSetCharacter={onSetCharacter} />
      ) : (
        <div className="slot-cpu">{t("cpuAtStart")}</div>
      )}
    </div>
  );
}
