import { Room, type Client } from "colyseus";
import { HUB_CONFIG, KO } from "./config.js";
import { MSG } from "../contract/wire.js";
import { hubLimits, parsePlayerName, parseRoomSettings } from "./room-options.js";
import { defaultModeOf } from "../games/catalog.js";
import { LobbyState, PlayerSchema } from "./lobby-state.js";
import { firstFreeSlot, graceSeconds, pickHostSessionId } from "./lobby-seats.js";
import {
  armIdleTimer, burstIdle as fireIdleBurst, cancelHostLossReset, clearIdleTimer, handlePackPct,
  handleRoomToggle, handleSetCharacter, handleSetGame, handleStart, scheduleHostLossReset,
  type LobbyBag, type LobbyHandle,
} from "./lobby-waiting.js";
import { applyPlayInput, bootAuthority, ignoreHostSnap, tickAuthority } from "./lobby-play.js";
import { acceptPlayInput } from "./match-authority.js";

export { PlayerSchema, LobbyState, HeroSchema, BulletSchema } from "./lobby-state.js";

export class LobbyRoom extends Room implements LobbyHandle {
  state = new LobbyState();
  private bag: LobbyBag = {
    lastSnap: null, prevSnap: null, gameTimer: null, idleTimer: null, authority: null,
    hostLossTimer: null,
  };

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
    this.setSimulationInterval((dt) => {tickAuthority(this, this.bag, dt);}, 1000 / 60);
  }

  messages = {
    [MSG.START]: (client: Client): void => {
      handleStart(this, this.bag, client);
      if (this.state.phase === "playing" && !this.bag.authority) {
        bootAuthority(this, this.bag);
      }
    },
    [MSG.INPUT]: (client: Client, data: Record<string, unknown>): void =>
      applyPlayInput(this, this.bag, client, data),
    [MSG.HOST_SNAP]: (): void => {ignoreHostSnap();},
    [MSG.ROOM_TOGGLE]: (client: Client): void => handleRoomToggle(this, client),
    [MSG.SET_GAME]: (client: Client, data: Record<string, unknown>): void =>
      handleSetGame(this, client, data),
    [MSG.SET_CHARACTER]: (client: Client, data: Record<string, unknown>): void =>
      handleSetCharacter(this, client, data),
    [MSG.PING]: (client: Client, data: unknown): void => {client.send(MSG.PONG, data);},
    [MSG.PACK_PCT]: (client: Client, data: Record<string, unknown>): void =>
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
      if (this.state.hostSessionId === "") {scheduleHostLossReset(this, this.bag);}
    } else {
      this.syncHost();
    }
    if (this.state.players.length === 0) {void this.disconnect();}
  }

  onDispose(): void {
    clearIdleTimer(this, this.bag);
    cancelHostLossReset(this.bag);
    if (this.bag.gameTimer) {this.bag.gameTimer.clear(); this.bag.gameTimer = null;}
  }

  burstIdle(): void {
    fireIdleBurst(this);
  }

  stepSim(dtMs = 50): void {
    tickAuthority(this, this.bag, dtMs);
  }

  pushTestInput(sessionId: string, data: Record<string, unknown>): boolean {
    return acceptPlayInput(
      this.state.phase,
      [...this.state.players],
      sessionId,
      data,
      this.bag.authority,
    );
  }

  private syncHost(): void {
    this.state.hostSessionId = pickHostSessionId(this.state.players);
    if (this.state.hostSessionId !== "") {cancelHostLossReset(this.bag);}
    void this.setMetadata({ ...this.metadata });
  }
}
