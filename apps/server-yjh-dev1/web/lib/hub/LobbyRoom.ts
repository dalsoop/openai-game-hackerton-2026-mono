import { Room, type Client } from "colyseus";
import { Schema, ArraySchema, type } from "@colyseus/schema";
import { HUB_CONFIG, MSG, KO, GAME_ID, MODES } from "./config.js";

// 다굴 로비/대기실/릴레이 — Colyseus 상태 동기화로 표현한다.
// 방 상태(멤버·phase·호스트)는 state 가 전부이고,
// 커스텀 메시지는 start / input / host_snap / chat 뿐이다.

export class PlayerSchema extends Schema {
  @type("number") slot = -1;        // 고정 좌석 — 이탈해도 다른 좌석은 밀리지 않는다
  @type("string") sessionId = "";
  @type("string") name = "";
  @type("boolean") connected = true; // allowReconnection 유예 중 false
}

export class LobbyState extends Schema {
  @type("string") phase: "lobby" | "playing" = "lobby";
  @type("string") hostSessionId = "";
  @type("string") title = "";
  @type("string") mode = HUB_CONFIG.defaultMode;
  @type("number") seed = 0;
  @type([PlayerSchema]) players = new ArraySchema<PlayerSchema>();
}

export class LobbyRoom extends Room {
  state = new LobbyState();
  private gameTimer: ReturnType<typeof setTimeout> | null = null;
  private lastSnap: Record<string, unknown> | null = null;
  private prevSnap: Record<string, unknown> | null = null;

  onCreate(options: { title?: string; name?: string }): void {
    this.maxClients = HUB_CONFIG.maxPlayers;
    this.state.title = this.sanitize(options.title, HUB_CONFIG.maxTitleLength)
      || `${MODES[HUB_CONFIG.defaultMode]!.title} #${this.roomId}`;
    void this.setMetadata({ gameId: GAME_ID, title: this.state.title, mode: this.state.mode, phase: this.state.phase });

    this.onMessage(MSG.START, (client) => this.handleStart(client));
    this.onMessage(MSG.INPUT, (client, data: Record<string, unknown>) => this.relayInput(client, data));
    this.onMessage(MSG.HOST_SNAP, (client, data: Record<string, unknown>) => this.relaySnap(client, data));
  }

  onJoin(client: Client, options: { name?: string }): void {
    const p = new PlayerSchema();
    p.slot = this.freeSlot();
    p.sessionId = client.sessionId;
    p.name = this.sanitize(options.name, HUB_CONFIG.maxNameLength) || KO.DEFAULT_NAME;
    this.state.players.push(p);
    this.syncHost();
  }

  // 재접속 유예 안에서 같은 좌석 복귀를 시도한다. 성공하면 true.
  private async tryReclaimSeat(client: Client, player: PlayerSchema | undefined): Promise<boolean> {
    if (player) {player.connected = false;}
    try {
      await this.allowReconnection(client, HUB_CONFIG.gracePlayMs / 1000);
      if (player) {player.connected = true;} // 같은 좌석으로 복귀
      return true;
    } catch {
      return false; // 유예 만료
    }
  }

  async onLeave(client: Client, code?: number): Promise<void> {
    const player = this.playerOf(client.sessionId);
    if (this.state.phase === "playing" && code !== 1000) {
      if (await this.tryReclaimSeat(client, player)) {return;}
    }
    const idx = this.state.players.findIndex((p) => p.sessionId === client.sessionId);
    if (idx >= 0) {this.state.players.splice(idx, 1);}

    if (this.state.phase === "playing" && client.sessionId === this.state.hostSessionId) {
      this.resetToLobby(); // 호스트(권위 시뮬) 이탈 = 매치 종료
    }
    this.syncHost();
    if (this.state.players.length === 0) {void this.disconnect();}
  }

  onDispose(): void {
    if (this.gameTimer) {clearTimeout(this.gameTimer);}
  }

  // --- 메시지 ---

  private handleStart(client: Client): void {
    if (this.state.phase !== "lobby") {return;}
    if (client.sessionId !== this.state.hostSessionId) {
      client.send(MSG.ERROR, { msg: KO.HOST_ONLY_START });
      return;
    }
    this.state.phase = "playing";
    this.state.seed = Math.floor(Math.random() * HUB_CONFIG.seedMax) + 1;
    void this.setMetadata({ ...this.metadata, phase: this.state.phase });

    const seats = this.seatsPayload();
    for (const p of this.state.players) {
      this.clients.find((c) => c.sessionId === p.sessionId)
        ?.send(MSG.START, {
          you: p.slot,
          host: p.sessionId === this.state.hostSessionId,
          seed: this.state.seed,
          mode: this.state.mode,
          seats,
        });
    }

    this.gameTimer = setTimeout(() => {
      if (this.state.phase === "playing" && !this.lastSnap) {
        this.broadcast(MSG.ERROR, { msg: KO.HOST_BOOT_FAIL });
        this.resetToLobby();
      }
    }, HUB_CONFIG.hostBootTimeoutMs);
  }

  private relayInput(client: Client, data: Record<string, unknown>): void {
    if (this.state.phase !== "playing") {return;}
    if (client.sessionId === this.state.hostSessionId) {return;}
    const slot = this.slotOf(client.sessionId);
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
    const ended = Boolean(data.result && data.result !== "playing");
    if (ended && (!this.prevSnap || this.prevSnap["result"] === "playing")) {
      if (this.gameTimer) {clearTimeout(this.gameTimer);}
      this.gameTimer = setTimeout(() => this.resetToLobby(), HUB_CONFIG.resetToLobbyDelayMs);
    }
  }

  // --- 내부 ---

  private resetToLobby(): void {
    if (this.gameTimer) { clearTimeout(this.gameTimer); this.gameTimer = null; }
    this.lastSnap = null;
    this.prevSnap = null;
    this.state.phase = "lobby";
    this.state.seed = 0;
    void this.setMetadata({ ...this.metadata, phase: this.state.phase });
  }

  private syncHost(): void {
    const host = [...this.state.players]
      .filter((p) => p.connected)
      .sort((a, b) => a.slot - b.slot)[0];
    this.state.hostSessionId = host?.sessionId ?? "";
    void this.setMetadata({ ...this.metadata });
  }

  private playerOf(sessionId: string): PlayerSchema | undefined {
    return this.state.players.find((p) => p.sessionId === sessionId);
  }

  private slotOf(sessionId: string): number {
    return this.playerOf(sessionId)?.slot ?? -1;
  }

  private freeSlot(): number {
    const used = new Set(this.state.players.map((p) => p.slot));
    for (let s = 0; s < HUB_CONFIG.maxPlayers; s++) {if (!used.has(s)) {return s;}}
    return this.state.players.length;
  }

  private seatsPayload(): Array<{ slot: number; name: string; connected: boolean }> {
    return [...this.state.players]
      .sort((a, b) => a.slot - b.slot)
      .map((p) => ({ slot: p.slot, name: p.name, connected: p.connected }));
  }

  private sanitize(s: unknown, max: number): string {
    return (typeof s === "string" ? s : "").replace(/[<>&"'`]/g, "").trim().slice(0, max);
  }
}
