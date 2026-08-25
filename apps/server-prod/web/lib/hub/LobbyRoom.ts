import { Room, type Client } from "colyseus";
import { HUB_CONFIG, KO } from "./config.js";
import { MSG, CLOSE_CODE } from "../contract/wire.js";
import { hubLimits, parsePlayerName, parseRoomSettings } from "./room-options.js";
import { defaultModeOf } from "../games/catalog.js";
import { LobbyState, PlayerSchema } from "./lobby-state.js";
import { firstFreeSlot, graceSeconds, pickHostSessionId, seatsPayloadOf } from "./lobby-seats.js";
import { matchJustEnded, startBodies } from "./lobby-relay.js";

export { PlayerSchema, LobbyState } from "./lobby-state.js";

export class LobbyRoom extends Room {
  state = new LobbyState();
  private gameTimer: { clear(): void } | null = null;
  private lastSnap: Record<string, unknown> | null = null;
  private prevSnap: Record<string, unknown> | null = null;

  onCreate(options: { game?: unknown; title?: unknown; name?: unknown }): void {
    this.maxClients = HUB_CONFIG.maxPlayers;
    const settings = parseRoomSettings(
      options,
      hubLimits(KO.roomTitleFallback(this.roomId)),
    );
    this.state.gameId = settings.game;
    this.state.title = settings.title;
    this.state.mode = defaultModeOf(settings.game);
    void this.setMetadata({
      gameId: this.state.gameId,
      title: this.state.title,
      mode: this.state.mode,
      phase: this.state.phase,
      open: this.state.open,
    });
  }

  messages = {
    [MSG.START]: (client: Client): void => this.handleStart(client),
    [MSG.INPUT]: (client: Client, data: Record<string, unknown>): void => this.relayInput(client, data),
    [MSG.HOST_SNAP]: (client: Client, data: Record<string, unknown>): void => this.relaySnap(client, data),
    [MSG.ROOM_TOGGLE]: (client: Client): void => this.handleRoomToggle(client),
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
    const player = this.playerOf(client.sessionId);
    if (player) {player.connected = true;}
  }

  onLeave(client: Client, _code?: number): void {
    this.removeSeat(client.sessionId);
  }

  private async holdSeat(client: Client): Promise<void> {
    const player = this.playerOf(client.sessionId);
    if (player) {player.connected = false;}
    try {
      await this.allowReconnection(client, graceSeconds(this.state.phase));
      return;
    } catch { /* 유예 만료 — 좌석 정리로 */ }
    this.removeSeat(client.sessionId);
  }

  private removeSeat(sessionId: string): void {
    const wasHost = sessionId === this.state.hostSessionId;
    const playing = this.state.phase === "playing";
    const idx = this.state.players.findIndex((p) => p.sessionId === sessionId);
    if (idx >= 0) {this.state.players.splice(idx, 1);}
    if (playing && wasHost) {
      this.transferHostOrEnd();
    } else {
      this.syncHost();
    }
    if (this.state.players.length === 0) {void this.disconnect();}
  }

  private transferHostOrEnd(): void {
    this.syncHost();
    if (this.state.hostSessionId === "") {
      this.resetToLobby();
      return;
    }
    if (!this.lastSnap) {return;}
    this.clients.find((c) => c.sessionId === this.state.hostSessionId)
      ?.send(MSG.SNAP, this.lastSnap);
  }

  onDispose(): void {
    // gameTimer 는 this.clock 소속 — 방 폐기 시 자동 정리된다.
  }

  private handleRoomToggle(client: Client): void {
    if (client.sessionId !== this.state.hostSessionId) {
      client.send(MSG.ERROR, { msg: KO.HOST_ONLY_TOGGLE });
      return;
    }
    this.state.open = !this.state.open;
    void this.setMetadata({ ...this.metadata, open: this.state.open });
    if (this.state.open) {return;}
    for (const c of this.clients) {
      if (c.sessionId === this.state.hostSessionId) {continue;}
      c.send(MSG.KICKED, { msg: KO.KICKED_MSG });
      c.leave(CLOSE_CODE.KICKED);
    }
  }

  private handleStart(client: Client): void {
    if (this.state.phase !== "lobby") {return;}
    if (client.sessionId !== this.state.hostSessionId) {
      client.send(MSG.ERROR, { msg: KO.HOST_ONLY_START });
      return;
    }
    this.state.phase = "playing";
    this.state.seed = Math.floor(Math.random() * HUB_CONFIG.seedMax) + 1;
    void this.setMetadata({ ...this.metadata, phase: this.state.phase });
    const seats = seatsPayloadOf(this.state.players);
    for (const body of startBodies(
      [...this.state.players], this.state.hostSessionId, this.state.seed, this.state.mode, seats,
    )) {
      this.clients.find((c) => c.sessionId === body.sessionId)
        ?.send(body.type, body.payload, { afterNextPatch: true });
    }
    this.gameTimer = this.clock.setTimeout(() => {
      if (this.state.phase === "playing" && !this.lastSnap) {
        this.broadcast(MSG.ERROR, { msg: KO.HOST_BOOT_FAIL });
        this.resetToLobby();
      }
    }, HUB_CONFIG.hostBootTimeoutMs);
  }

  private relayInput(client: Client, data: Record<string, unknown>): void {
    if (this.state.phase !== "playing") {return;}
    if (client.sessionId === this.state.hostSessionId) {return;}
    const slot = this.playerOf(client.sessionId)?.slot ?? -1;
    if (slot < 0) {return;}
    this.clients.find((c) => c.sessionId === this.state.hostSessionId)
      ?.send(MSG.PEER_INPUT, { ...data, slot });
  }

  private relaySnap(client: Client, data: Record<string, unknown>): void {
    if (this.state.phase !== "playing" || client.sessionId !== this.state.hostSessionId) {return;}
    this.prevSnap = this.lastSnap;
    this.lastSnap = data;
    for (const c of this.clients) {
      if (c.sessionId !== client.sessionId) {c.send(MSG.SNAP, data);}
    }
    if (matchJustEnded(data, this.prevSnap)) {
      if (this.gameTimer) {this.gameTimer.clear();}
      this.resetToLobby();
    }
  }

  private resetToLobby(): void {
    if (this.gameTimer) { this.gameTimer.clear(); this.gameTimer = null; }
    this.lastSnap = null;
    this.prevSnap = null;
    this.state.phase = "lobby";
    this.state.seed = 0;
    void this.setMetadata({ ...this.metadata, phase: this.state.phase });
  }

  private syncHost(): void {
    this.state.hostSessionId = pickHostSessionId(this.state.players);
    void this.setMetadata({ ...this.metadata });
  }

  private playerOf(sessionId: string): PlayerSchema | undefined {
    return this.state.players.find((p) => p.sessionId === sessionId);
  }
}
