import { Room, type Client } from "colyseus";
import { Schema, ArraySchema, type } from "@colyseus/schema";
import { HUB_CONFIG, MSG, KO, MODES } from "./config.js";
import { asGameId } from "../games/catalog.js";

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
  @type("string") gameId = asGameId(undefined); // 유즈맵 — 이 방에서 플레이할 게임
  @type("string") phase: "lobby" | "playing" = "lobby";
  @type("string") hostSessionId = "";
  @type("string") title = "";
  @type("string") mode = HUB_CONFIG.defaultMode;
  @type("number") seed = 0;
  @type([PlayerSchema]) players = new ArraySchema<PlayerSchema>();
}

export class LobbyRoom extends Room {
  state = new LobbyState();
  private gameTimer: { clear(): void } | null = null;
  private lastSnap: Record<string, unknown> | null = null;
  private prevSnap: Record<string, unknown> | null = null;
  private pin = "";

  onCreate(options: { game?: string; title?: string; name?: string; pin?: string }): void {
    this.maxClients = HUB_CONFIG.maxPlayers;
    this.state.gameId = asGameId(options.game); // 카탈로그 등재 게임만 확정
    this.state.title = this.sanitize(options.title, HUB_CONFIG.maxTitleLength)
      || `${MODES[HUB_CONFIG.defaultMode].title} #${this.roomId}`;
    this.pin = this.sanitizePin(options.pin);
    void this.setMetadata({ gameId: this.state.gameId, title: this.state.title, mode: this.state.mode, phase: this.state.phase, locked: this.pin !== "" });
  }

  // 공식 0.17 선언적 메시지 핸들러 — onCreate 의 this.onMessage 등록을 대체한다.
  messages = {
    [MSG.START]: (client: Client): void => this.handleStart(client),
    [MSG.INPUT]: (client: Client, data: Record<string, unknown>): void => this.relayInput(client, data),
    [MSG.HOST_SNAP]: (client: Client, data: Record<string, unknown>): void => this.relaySnap(client, data),
  };

  // 입장 인증(공식 onAuth) — 잠긴 방은 PIN 일치만 통과.
  // create 첫 입장은 options.pin 으로 방을 만들었으므로 자동으로 일치한다.
  onAuth(_client: Client, options: { pin?: string }): boolean {
    if (this.pin === "") {return true;}
    if (this.sanitizePin(options.pin) === this.pin) {return true;}
    throw new Error(KO.WRONG_PIN);
  }

  onJoin(client: Client, options: { name?: string }): void {
    const p = new PlayerSchema();
    p.slot = this.freeSlot();
    p.sessionId = client.sessionId;
    p.name = this.sanitize(options.name, HUB_CONFIG.maxNameLength) || KO.DEFAULT_NAME;
    this.state.players.push(p);
    this.syncHost();
  }

  // 공식 0.17 라이프사이클 — 재접속 대상 단절은 onDrop, 동의 퇴장은 onLeave.
  // 유예 길이는 페이즈별: 플레이 중 180초, 대기실 60초 (HUB_CONFIG).
  async onDrop(client: Client, _code?: number): Promise<void> {
    const player = this.playerOf(client.sessionId);
    const graceMs = this.state.phase === "playing" ? HUB_CONFIG.gracePlayMs : HUB_CONFIG.graceLobbyMs;
    if (player) {player.connected = false;}
    try {
      await this.allowReconnection(client, graceMs / 1000);
      return; // 복귀 성공 — onReconnect 가 connected 를 되돌린다
    } catch { /* 유예 만료 — 좌석 정리로 */ }
    this.removeSeat(client.sessionId);
  }

  // allowReconnection 성공 직후 호출(공식) — 같은 좌석 복귀 확정.
  onReconnect(client: Client): void {
    const player = this.playerOf(client.sessionId);
    if (player) {player.connected = true;}
  }

  // 동의 퇴장(leave) — 유예 없이 즉시 좌석 반납.
  onLeave(client: Client, _code?: number): void {
    this.removeSeat(client.sessionId);
  }

  private removeSeat(sessionId: string): void {
    const idx = this.state.players.findIndex((p) => p.sessionId === sessionId);
    if (idx >= 0) {this.state.players.splice(idx, 1);}

    if (this.state.phase === "playing" && sessionId === this.state.hostSessionId) {
      this.resetToLobby(); // 호스트(권위 시뮬) 이탈 = 매치 종료
    }
    this.syncHost();
    if (this.state.players.length === 0) {void this.disconnect();}
  }

  onDispose(): void {
    // gameTimer 는 this.clock 소속 — 방 폐기 시 자동 정리된다 (공식 문서).
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
    // afterNextPatch: phase=playing 패치가 먼저 도착한 뒤 START 가 가게 한다
    // (공식 문서 — 상태 변경 적용 후 메시지 도착 순서 보장).
    for (const p of this.state.players) {
      this.clients.find((c) => c.sessionId === p.sessionId)
        ?.send(MSG.START, {
          you: p.slot,
          host: p.sessionId === this.state.hostSessionId,
          seed: this.state.seed,
          mode: this.state.mode,
          seats,
        }, { afterNextPatch: true });
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
      if (this.gameTimer) {this.gameTimer.clear();}
      this.gameTimer = this.clock.setTimeout(() => this.resetToLobby(), HUB_CONFIG.resetToLobbyDelayMs);
    }
  }

  // --- 내부 ---

  private resetToLobby(): void {
    if (this.gameTimer) { this.gameTimer.clear(); this.gameTimer = null; }
    this.lastSnap = null;
    this.prevSnap = null;
    this.state.phase = "lobby";
    this.state.seed = 0;
    void this.setMetadata({ ...this.metadata, phase: this.state.phase });
  }

  private syncHost(): void {
    const host = [...this.state.players]
      .filter((p) => p.connected)
      .sort((a, b) => a.slot - b.slot).at(0);
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

  // PIN — 숫자 4~8자리만. 빈 값이면 잠금 없음.
  private sanitizePin(s: unknown): string {
    const v = (typeof s === "string" ? s : "").replace(/\D/g, "");
    return v.length >= 4 && v.length <= 8 ? v : "";
  }
}
