import type { Client } from "colyseus";
import { HUB_CONFIG } from "./config.js";
import { PLAY_MSG } from "../contract/wire.js";
import { matchJustEnded } from "./lobby-relay.js";
import { shouldRelaySnap } from "./snap-relay.js";
import { resetToLobby, type LobbyBag, type LobbyHandle } from "./lobby-waiting.js";

export function relayInput(room: LobbyHandle, client: Client, data: Record<string, unknown>): void {
  if (room.state.phase !== "playing") {return;}
  if (client.sessionId === room.state.hostSessionId) {return;}
  const slot = room.state.players.find((p) => p.sessionId === client.sessionId)?.slot ?? -1;
  if (slot < 0) {return;}
  room.clients.find((c) => c.sessionId === room.state.hostSessionId)
    ?.send(PLAY_MSG.PEER_INPUT, { ...data, slot });
}

export function relaySnap(room: LobbyHandle, bag: LobbyBag, client: Client, data: Record<string, unknown>): void {
  if (room.state.phase !== "playing" || client.sessionId !== room.state.hostSessionId) {return;}
  const ended = matchJustEnded(data, bag.lastSnap);
  if (!ended && !shouldRelaySnap(bag.lastSnap, data, HUB_CONFIG.maxSnapBytes)) {return;}
  bag.prevSnap = bag.lastSnap;
  bag.lastSnap = data;
  for (const c of room.clients) {
    if (c.sessionId !== client.sessionId) {c.send(PLAY_MSG.SNAP, data);}
  }
  if (ended) {
    if (bag.gameTimer) {bag.gameTimer.clear();}
    resetToLobby(room, bag);
  }
}

export function sendHostSnap(room: LobbyHandle, bag: LobbyBag): void {
  if (!bag.lastSnap) {return;}
  room.clients.find((c) => c.sessionId === room.state.hostSessionId)
    ?.send(PLAY_MSG.SNAP, bag.lastSnap);
}
