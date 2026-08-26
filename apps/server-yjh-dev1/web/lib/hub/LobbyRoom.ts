import { Room, type Client } from "colyseus";
import { HUB_CONFIG, KO } from "./config.js";
import { HUB_MSG, PLAY_MSG } from "../contract/wire.js";
import { hubLimits, parsePlayerName, parseRoomSettings } from "./room-options.js";
import { defaultModeOf } from "../games/catalog.js";
import { LobbyState, PlayerSchema } from "./lobby-state.js";
import { firstFreeSlot, graceSeconds, pickHostSessionId } from "./lobby-seats.js";
import {
  armIdleTimer, burstIdle as fireIdleBurst, clearIdleTimer, handlePackPct, handleRoomToggle,
  handleSetGame, handleStart, resetToLobby, type LobbyBag, type LobbyHandle,
} from "./lobby-waiting.js";
import { relayInput, relaySnap, sendHostSnap } from "./lobby-play.js";

export { PlayerSchema, LobbyState } from "./lobby-state.js";

export class LobbyRoom extends Room implements LobbyHandle {
  state = new LobbyState();
  private bag: LobbyBag = { lastSnap: null, prevSnap: null, gameTimer: null, idleTimer: null };

  onCreate(options: { game?: unknown; title?: unknown; name?: unknown }): void {
    this.maxClients = HUB_CONFIG.maxPlayers;
    const settings = parseRoomSettings(
      options,
      hubLimits(KO.roomTitleFallback(this.roomId)),
    );
    this.state.gameId = settings.game;
    this.state.title = settings.title;
    this.state.mode = defaultModeOf(settings.game);
    this.state.createdAtMs = Date.now();
    void this.setMetadata({
      gameId: this.state.gameId,
      title: this.state.title,
      mode: this.state.mode,
      phase: this.state.phase,
      open: this.state.open,
    });
    armIdleTimer(this, this.bag);
  }

  messages = {
    [HUB_MSG.START]: (client: Client): void => handleStart(this, this.bag, client),
    [PLAY_MSG.INPUT]: (client: Client, data: Record<string, unknown>): void => relayInput(this, client, data),
    [PLAY_MSG.HOST_SNAP]: (client: Client, data: Record<string, unknown>): void =>
      relaySnap(this, this.bag, client, data),
    [HUB_MSG.ROOM_TOGGLE]: (client: Client): void => handleRoomToggle(this, client),
    [HUB_MSG.SET_GAME]: (client: Client, data: Record<string, unknown>): void =>
      handleSetGame(this, client, data),
    [HUB_MSG.PING]: (client: Client, data: unknown): void => {client.send(HUB_MSG.PONG, data);},
    [HUB_MSG.PACK_PCT]: (client: Client, data: Record<string, unknown>): void =>
      handlePackPct(this, client, data),
  };

  onAuth(_client: Client, _options: Record<string, unknown>): boolean {
    if (!this.state.open) {throw new Error(KO.ROOM_CLOSED);}
    return true;
  }

  onJoin(client: Client, options: { name?: string }): void {
    const p = new PlayerSchema();
    p.slot = firstFreeSlot(this.state.players.map((s) => s.slot));
    p.sessionId = client.sessionId;
    p.name = parsePlayerName(options.name, HUB_CONFIG.maxNameLength, HUB_CONFIG.defaultName);
    this.state.players.push(p);
    this.syncHost();
  }

  async onDrop(client: Client, _code?: number): Promise<void> {
    await this.holdSeat(client);
  }

  onReconnect(client: Client): void {
    const player = this.state.players.find((p) => p.sessionId === client.sessionId);
    if (player) {player.connected = true;}
    this.syncHost();
  }

  onLeave(client: Client, _code?: number): void {
    this.removeSeat(client.sessionId);
  }

  private async holdSeat(client: Client): Promise<void> {
    const player = this.state.players.find((p) => p.sessionId === client.sessionId);
    if (player) {player.connected = false;}
    this.syncHost();
    try {
      await this.allowReconnection(client, graceSeconds(this.state.phase));
      return;
    } catch { /* expired */ }
    this.removeSeat(client.sessionId);
  }

  private removeSeat(sessionId: string): void {
    const wasHost = sessionId === this.state.hostSessionId;
    const playing = this.state.phase === "playing";
    const idx = this.state.players.findIndex((p) => p.sessionId === sessionId);
    if (idx >= 0) {this.state.players.splice(idx, 1);}
    if (playing && wasHost) {
      this.syncHost();
      if (this.state.hostSessionId === "") {resetToLobby(this, this.bag);}
      else {sendHostSnap(this, this.bag);}
    } else {
      this.syncHost();
    }
    if (this.state.players.length === 0) {void this.disconnect();}
  }

  onDispose(): void {
    clearIdleTimer(this, this.bag);
  }

  burstIdle(): void {
    fireIdleBurst(this);
  }

  private syncHost(): void {
    this.state.hostSessionId = pickHostSessionId(this.state.players);
    void this.setMetadata({ ...this.metadata });
  }
}
