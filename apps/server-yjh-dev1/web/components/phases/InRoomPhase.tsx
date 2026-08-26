/**
 * InRoomPhase — 대기실 화면. 받기 표시만 하고 시작은 자기 팩 준비에 맡긴다.
 */
import type { JSX } from "react";
import Room from "@/components/Room";
import RoomDownload from "@/components/RoomDownload";
import { roomDownload } from "@/lib/domain/download";
import type { HubPlayer } from "@/types";

interface InRoomPhaseProps {
  players: HubPlayer[];
  you: number;
  isHost: boolean;
  gameId: string;
  roomOpen: boolean;
  idleLeftSec: number;
  localPct: number;
  canStart: boolean;
  onStartGame: () => void;
  onLeaveRoom: () => void;
  onSetGame: (game: string) => void;
  onToggleRoom: () => void;
}

export function InRoomPhase({
  players,
  you,
  isHost,
  gameId,
  roomOpen,
  idleLeftSec,
  localPct,
  canStart,
  onStartGame,
  onLeaveRoom,
  onSetGame,
  onToggleRoom,
}: InRoomPhaseProps): JSX.Element {
  const view = roomDownload(players, you, localPct);

  return (
    <>
      <Room
        players={view.players}
        you={you}
        isHost={isHost}
        gameId={gameId}
        roomOpen={roomOpen}
        idleLeftSec={idleLeftSec}
        onStart={onStartGame}
        onLeave={onLeaveRoom}
        onSetGame={onSetGame}
        onToggleRoom={onToggleRoom}
        canStart={canStart}
      />
      <RoomDownload seats={view.seats} you={you} />
    </>
  );
}
