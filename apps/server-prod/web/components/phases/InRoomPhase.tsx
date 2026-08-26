/**
 * InRoomPhase — 대기실 화면. 팩 진행은 표시만 하고 시작은 자기 팩 준비에 맡긴다.
 */
import type { JSX } from "react";
import Room from "@/components/Room";
import { overlayOwnPackPct } from "@/lib/domain/waiting-room-pack";
import type { Seat } from "@/lib/domain/roster";

interface InRoomPhaseProps {
  players: Seat[];
  you: number;
  isHost: boolean;
  gameId: string;
  roomOpen: boolean;
  idleLeftSec: number;
  ownPackPct: number;
  canStart: boolean;
  onStartGame: () => void;
  onLeaveRoom: () => void;
  onSetGame: (game: string) => void;
  onSetCharacter: (characterId: string) => void;
  onToggleRoom: () => void;
  connClass: string;
  connText: string;
  rttMs: number;
  rttText: string | null;
}

export function InRoomPhase({
  players,
  you,
  isHost,
  gameId,
  roomOpen,
  idleLeftSec,
  ownPackPct,
  canStart,
  onStartGame,
  onLeaveRoom,
  onSetGame,
  onSetCharacter,
  onToggleRoom,
  connClass,
  connText,
  rttMs,
  rttText,
}: InRoomPhaseProps): JSX.Element {
  const seats = overlayOwnPackPct(players, you, ownPackPct);

  return (
    <Room
      players={seats}
      you={you}
      isHost={isHost}
      gameId={gameId}
      roomOpen={roomOpen}
      idleLeftSec={idleLeftSec}
      onStart={onStartGame}
      onLeave={onLeaveRoom}
      onSetGame={onSetGame}
      onSetCharacter={onSetCharacter}
      onToggleRoom={onToggleRoom}
      canStart={canStart}
      connClass={connClass}
      connText={connText}
      rttMs={rttMs}
      rttText={rttText}
    />
  );
}
