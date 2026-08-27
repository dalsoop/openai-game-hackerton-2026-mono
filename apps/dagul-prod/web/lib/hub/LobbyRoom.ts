import { Room, type Client } from "colyseus";
import { HUB_CONFIG, KO } from "./config.js";
import { CLOSE_CODE, MSG } from "../contract/wire.js";
import { hubLimits, parsePlayerName, parseRoomSettings } from "./room-options.js";
import { defaultModeOf } from "../games/catalog.js";
import { LobbyState, PlayerSchema } from "./lobby-state.js";
import { firstFreeSlot, graceSeconds, pickHostSessionId, seatsPayloadOf } from "./lobby-seats.js";
import { startBodies } from "./lobby-relay.js";
import { parseSeatClaim, sameSeatClaim, type SeatClaim } from "../guest-identity.js";
import {
  isEngineJoin, playerJoinAllowed, seatClaimTakeover, slotOfEngineClaim,
} from "./match-engine.js";
import {
  armIdleTimer, burstIdle as fireIdleBurst, cancelHostLossReset, clearIdleTimer, handlePackPct,
  handleMatchReady, handleRoomToggle, handleSetCharacter, handleSetGame, handleStart, scheduleHostLossReset,
  type LobbyBag, type LobbyHandle,
} from "./lobby-waiting.js";
import {
  applyPlayInput, bootAuthority, parkSeat, resetSeatAck, tickAuthority, tryReleaseLoadBarrier,
} from "./lobby-play.js";
import { acceptPlayInput } from "./match-authority.js";

export { PlayerSchema, LobbyState, HeroSchema, BulletSchema } from "./lobby-state.js";

export class LobbyRoom extends Room implements LobbyHandle {
  state = new LobbyState();
  private bag: LobbyBag = {
    lastSnap: null, prevSnap: null, gameTimer: null, idleTimer: null, authority: null,
    hostLossTimer: null, loadWaitMs: 0,
  };
  /** sessionId → 좌석 이어받기 증명. 비공개 키라 state(schema)에 넣지 않는다. */
  private claims = new Map<string, SeatClaim>();
  /** Godot 엔진 보조 세션 — 좌석을 먹지 않는다. */
  private engineSessions = new Set<string>();
  private engineClaims = new Map<string, SeatClaim>();
  /** JSON SNAP 을 받지 않는 sessionId. 엔진 직결·SNAP_OFF. */
  snapOptOut = new Set<string>();

  onCreate(options: { game?: unknown; title?: unknown; name?: unknown }): void {
    this.maxClients = HUB_CONFIG.maxPlayers * 2;
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
    this.patchRate = 1000 / HUB_CONFIG.patchHz;
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
    [MSG.ROOM_TOGGLE]: (client: Client): void => handleRoomToggle(this, client),
    [MSG.SET_GAME]: (client: Client, data: Record<string, unknown>): void =>
      handleSetGame(this, client, data),
    [MSG.SET_CHARACTER]: (client: Client, data: Record<string, unknown>): void =>
      handleSetCharacter(this, client, data),
    [MSG.PING]: (client: Client, data: unknown): void => {client.send(MSG.PONG, data);},
    [MSG.PACK_PCT]: (client: Client, data: Record<string, unknown>): void =>
      handlePackPct(this, client, data),
    [MSG.READY]: (client: Client): void => {
      handleMatchReady(this, client);
      tryReleaseLoadBarrier(this, this.bag);
    },
    [MSG.SNAP_OFF]: (client: Client): void => {
      this.snapOptOut.add(client.sessionId);
    },
    [MSG.SNAP_ON]: (client: Client): void => {
      this.snapOptOut.delete(client.sessionId);
    },
  };

  onAuth(_client: Client, options: Record<string, unknown>): boolean {
    if (isEngineJoin(options)) {return true;}
    if (!this.state.open) {throw new Error(KO.ROOM_CLOSED);}
    const claim = parseSeatClaim(options);
    const takeover = seatClaimTakeover([...this.state.players], this.claims, claim);
    if (playerJoinAllowed(this.state.players.length, takeover)) {return true;}
    throw new Error(KO.ROOM_FULL);
  }

  onJoin(
    client: Client,
    options: { name?: string; guestId?: unknown; guestKey?: unknown; engine?: unknown },
  ): void {
    const claim = parseSeatClaim(options);
    if (isEngineJoin(options)) {
      this.attachEngine(client.sessionId, claim);
      return;
    }
    if (claim && this.takeOverSeat(client, claim)) {return;}
    const p = new PlayerSchema();
    p.slot = firstFreeSlot(this.state.players.map((s) => s.slot));
    p.sessionId = client.sessionId;
    p.name = parsePlayerName(options.name, HUB_CONFIG.maxNameLength, HUB_CONFIG.defaultName);
    this.state.players.push(p);
    if (claim) {this.claims.set(client.sessionId, claim);}
    this.syncHost();
    this.resumePlayingSeat(client, p);
  }

  /** 같은 브라우저(증명 일치)의 새 창이 좌석을 이어받는다 — 기존 창은 안내 후 종료. */
  private takeOverSeat(client: Client, claim: SeatClaim): boolean {
    const player = this.state.players.find((p) => sameSeatClaim(this.claims.get(p.sessionId), claim));
    if (!player) {return false;}
    const oldId = player.sessionId;
    const oldClient = this.clients.find((c) => c.sessionId === oldId);
    player.sessionId = client.sessionId;
    player.connected = true;
    player.matchReady = false; // 새 창은 WASM 을 다시 띄우므로 ready 를 다시 받는다.
    this.claims.delete(oldId);
    this.claims.set(client.sessionId, claim);
    this.syncHost();
    oldClient?.send(MSG.KICKED, { msg: KO.TAKEOVER_MSG, reason: "takeover" });
    oldClient?.leave(CLOSE_CODE.KICKED);
    this.resumePlayingSeat(client, player);
    return true;
  }

  /**
   * 매치 중 좌석에 앉으면 parked 시체를 깨우고 START 를 다시 보낸다.
   * 유예 만료 후 onJoin·이어받기·재접속이 같은 경로를 탄다.
   */
  private resumePlayingSeat(client: Client, player: PlayerSchema): void {
    parkSeat(this.bag, player.slot, false);
    resetSeatAck(this.bag, player.slot);
    if (this.state.phase !== "playing") {return;}
    this.resendStart(client, player);
  }

  /** 플레이 중 이어받기 — 새 세션이 매치에 붙도록 START 본문을 다시 보낸다. */
  private resendStart(client: Client, player: PlayerSchema): void {
    const seats = seatsPayloadOf(this.state.players);
    const engineJoin = this.roomId ? { roomId: this.roomId } : undefined;
    const body = startBodies(
      [player], this.state.hostSessionId, this.state.seed, this.state.mode, seats, engineJoin,
    )[0];
    client.send(body.type, body.payload, { afterNextPatch: true });
  }

  async onDrop(client: Client, _code?: number): Promise<void> {
    if (this.dropEngine(client.sessionId)) {return;}
    await this.holdSeat(client);
  }

  onReconnect(client: Client): void {
    const player = this.state.players.find((p) => p.sessionId === client.sessionId);
    if (!player) {
      // 좌석이 이미 다른 창으로 넘어간 옛 세션의 재접속 — 유령 클라이언트로 두지 않는다.
      client.send(MSG.KICKED, { msg: KO.TAKEOVER_MSG, reason: "takeover" });
      client.leave(CLOSE_CODE.KICKED);
      return;
    }
    player.connected = true;
    // 직전 세션이 SNAP_OFF 였으면 같은 sessionId 가 opt-out 에 남는다.
    // 새 WASM 은 JSON SNAP 이 다시 와야 HUD·카메라가 산다.
    this.snapOptOut.delete(client.sessionId);
    this.syncHost();
    this.resumePlayingSeat(client, player);
  }

  onLeave(client: Client, _code?: number): void {
    this.snapOptOut.delete(client.sessionId);
    if (this.dropEngine(client.sessionId)) {return;}
    this.removeSeat(client.sessionId);
  }

  private async holdSeat(client: Client): Promise<void> {
    const player = this.state.players.find((p) => p.sessionId === client.sessionId);
    if (player) {
      player.connected = false;
      parkSeat(this.bag, player.slot, true);
    }
    this.syncHost();
    try {
      await this.allowReconnection(client, graceSeconds(this.state.phase));
      return;
    } catch { /* expired */ }
    this.removeSeat(client.sessionId);
  }

  private removeSeat(sessionId: string): void {
    this.claims.delete(sessionId);
    const wasHost = sessionId === this.state.hostSessionId;
    const playing = this.state.phase === "playing";
    const idx = this.state.players.findIndex((p) => p.sessionId === sessionId);
    if (idx >= 0) {
      parkSeat(this.bag, this.state.players[idx].slot, true);
      this.state.players.splice(idx, 1);
    }
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
      this.slotOfSession(sessionId),
    );
  }

  slotOfSession(sessionId: string): number {
    const seated = this.state.players.find((p) => p.sessionId === sessionId);
    if (seated) {return seated.slot;}
    return slotOfEngineClaim([...this.state.players], this.claims, this.engineClaims.get(sessionId));
  }

  private attachEngine(sessionId: string, claim: SeatClaim | null): void {
    this.engineSessions.add(sessionId);
    this.snapOptOut.add(sessionId);
    if (claim) {this.engineClaims.set(sessionId, claim);}
  }

  private dropEngine(sessionId: string): boolean {
    if (!this.engineSessions.has(sessionId)) {return false;}
    this.engineSessions.delete(sessionId);
    this.engineClaims.delete(sessionId);
    this.snapOptOut.delete(sessionId);
    return true;
  }

  private syncHost(): void {
    this.state.hostSessionId = pickHostSessionId(this.state.players);
    if (this.state.hostSessionId !== "") {cancelHostLossReset(this.bag);}
    void this.setMetadata({ ...this.metadata });
  }
}
