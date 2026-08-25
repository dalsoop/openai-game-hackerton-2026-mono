import { Room, Client } from "colyseus";
import { CONFIG, Phase, MSG } from "../config.js";
import { LL } from "../i18n/init.js";
import type { GamePlugin } from "../games/plugin.js";
import { getGame, defaultGame } from "../games/registry.js";

interface PlayerState {
  name: string;
  rtt: number;
  lastChatAt: number;
}

export class LobbyRoom extends Room {
  private game!: GamePlugin;
  private currentMode!: string;
  private phase: Phase = Phase.LOBBY;
  private hostSessionId: string | null = null;
  private gameTimer: ReturnType<typeof setTimeout> | null = null;
  private lastSnap: Record<string, unknown> | null = null;
  private prevSnap: Record<string, unknown> | null = null;
  private snapCount = 0;
  private players = new Map<string, PlayerState>();

  onCreate(options: { gameId?: string; mode?: string; title?: string }) {
    const requested = options.gameId ? getGame(options.gameId) : undefined;
    this.game = requested ? requested : defaultGame();
    this.maxClients = this.game.maxPlayers;
    this.currentMode = (options.mode && this.game.modes[options.mode])
      ? options.mode
      : this.game.defaultMode;

    const modeTitle = this.resolveKey(this.game.modes[this.currentMode]!.titleKey, this.currentMode);

    this.setMetadata({
      gameId: this.game.id,
      mode: this.currentMode,
      title: options.title
        ? this.sanitize(options.title, CONFIG.maxTitleLength)
        : `${modeTitle} #${this.roomId}`,
    });

    this.registerMessages();
  }

  onJoin(client: Client, options: { name?: string }) {
    const sanitized = this.sanitize(options.name, CONFIG.maxNameLength);
    const name = sanitized ? sanitized : LL.DEFAULT_NAME();
    this.players.set(client.sessionId, { name, rtt: 0, lastChatAt: 0 });

    client.send(MSG.JOINED, {
      you: this.slotOf(client.sessionId),
      room: this.roomPublic(),
      players: this.peersPayload(),
      game: this.gameInfo(),
    });

    this.broadcastPeers({ notice: LL.playerJoined({ name }) }, client);
  }

  async onLeave(client: Client, code?: number) {
    const consented = code === 1000;
    const player = this.players.get(client.sessionId);
    const name = player ? player.name : LL.DEFAULT_NAME();

    if (this.phase === Phase.PLAYING && !consented) {
      const grace = CONFIG.gracePlayMs;
      this.broadcastPeers({ notice: LL.playerDropped({ name, sec: Math.round(grace / 1000) }) });

      try {
        await this.allowReconnection(client, grace / 1000);
        this.broadcastPeers({ notice: LL.playerReconnected({ name }) });
        return;
      } catch {
        // reconnection timed out
      }
    }

    this.players.delete(client.sessionId);

    if (this.phase === Phase.PLAYING && client.sessionId === this.hostSessionId) {
      this.broadcastPeers({ notice: LL.hostLeftEnd({ name }) });
      this.resetToLobby();
      return;
    }

    if (this.clients.length === 0) {
      this.disconnect();
      return;
    }

    if (!consented) {
      this.broadcastPeers({ notice: LL.playerLeft({ name }) });
    }
  }

  onDispose() {
    if (this.gameTimer) clearTimeout(this.gameTimer);
  }

  private registerMessages() {
    this.onMessage(MSG.CHAT, (client, data) => {
      const player = this.players.get(client.sessionId);
      if (!player) return;
      const text = this.sanitize(data?.text, CONFIG.maxChatLength);
      if (!text) return;
      const now = Date.now();
      if (player.lastChatAt && now - player.lastChatAt < CONFIG.chatCooldownMs) return;
      player.lastChatAt = now;
      this.broadcast(MSG.CHAT, { from: player.name, slot: this.slotOf(client.sessionId), text });
    });

    this.onMessage(MSG.START, (client) => {
      if (this.phase !== Phase.LOBBY) return;
      if (this.hostSessionId !== client.sessionId && this.hostSessionId !== null) {
        client.send(MSG.ERROR, { msg: LL.HOST_ONLY_START() });
        return;
      }
      this.startMatch();
    });

    this.onMessage(MSG.KICK, (client, data) => {
      if (this.phase !== Phase.LOBBY) { client.send(MSG.ERROR, { msg: LL.CANNOT_KICK() }); return; }
      if (this.hostId() !== client.sessionId) { client.send(MSG.ERROR, { msg: LL.HOST_ONLY_KICK() }); return; }
      const slot = Number(data?.slot);
      const target = this.clientBySlot(slot);
      if (!target || target.sessionId === client.sessionId) return;
      const targetPlayer = this.players.get(target.sessionId);
      target.send(MSG.KICKED, { msg: LL.KICKED_MSG() });
      target.leave();
      if (targetPlayer) {
        this.broadcastPeers({ notice: LL.playerKicked({ name: targetPlayer.name }) });
      }
    });

    if (this.game.relay.inputRelay) {
      this.onMessage(MSG.INPUT, (client, data) => {
        if (this.phase !== Phase.PLAYING) return;
        if (!this.hostSessionId) return;
        if (client.sessionId === this.hostSessionId) return;
        const slot = this.slotOf(client.sessionId);
        if (slot < 0) return;
        const host = this.clients.find(c => c.sessionId === this.hostSessionId);
        if (!host) return;
        host.send(MSG.PEER_INPUT, { ...data, slot });
      });
    }

    if (this.game.relay.snapRelay) {
      this.onMessage(MSG.HOST_SNAP, (client, data) => {
        if (this.phase !== Phase.PLAYING) return;
        if (client.sessionId !== this.hostSessionId) return;
        const snapData = { ...data, t: MSG.SNAP };
        this.prevSnap = this.lastSnap;
        this.lastSnap = snapData;
        this.snapCount += 1;
        for (const c of this.clients) {
          if (c.sessionId !== client.sessionId) c.send(MSG.SNAP, snapData);
        }
        const isEnded = Boolean(snapData.result && snapData.result !== Phase.PLAYING);
        if (isEnded && (!this.prevSnap || this.prevSnap["result"] === Phase.PLAYING)) {
          if (this.gameTimer) clearTimeout(this.gameTimer);
          this.gameTimer = setTimeout(() => this.resetToLobby(), CONFIG.resetToLobbyDelayMs);
        } else if (snapData.result === Phase.PLAYING && this.gameTimer) {
          clearTimeout(this.gameTimer);
          this.gameTimer = null;
        }
      });
    }

    this.onMessage(MSG.MODE, (client, data) => {
      if (this.phase !== Phase.LOBBY) { client.send(MSG.ERROR, { msg: LL.CANNOT_CHANGE_MODE() }); return; }
      if (this.hostId() !== client.sessionId) { client.send(MSG.ERROR, { msg: LL.HOST_ONLY_MODE() }); return; }
      const next = this.game.modes[String(data?.mode)] ? String(data.mode) : this.currentMode;
      this.currentMode = next;
      this.setMetadata({ ...this.metadata, mode: next });
      this.broadcastPeers();
    });

    this.onMessage(MSG.PING, (client, data) => {
      client.send(MSG.PONG, { ts: data?.ts });
    });
  }

  private startMatch() {
    this.phase = Phase.PLAYING;
    this.hostSessionId = this.hostId();
    const seed = Math.floor(Math.random() * CONFIG.seedMax) + 1;

    for (const [i, client] of this.clients.entries()) {
      client.send(MSG.START, {
        you: i,
        host: client.sessionId === this.hostSessionId,
        room: this.roomPublic(),
        game: this.gameInfo(),
        gameServerUrl: "",
        seed,
      });
    }

    if (this.game.relay.gameServerNotify) {
      this.notifyGameServer(seed);
    }

    this.gameTimer = setTimeout(() => {
      if (this.phase === Phase.PLAYING && !this.lastSnap) {
        this.broadcast(MSG.ERROR, { msg: LL.HOST_BOOT_FAIL() });
        this.resetToLobby();
      }
    }, CONFIG.hostBootTimeoutMs);
  }

  private resetToLobby() {
    if (this.gameTimer) { clearTimeout(this.gameTimer); this.gameTimer = null; }
    this.hostSessionId = null;
    this.lastSnap = null;
    this.prevSnap = null;
    this.snapCount = 0;
    this.phase = Phase.LOBBY;

    if (this.clients.length === 0) {
      this.disconnect();
      return;
    }

    this.broadcast(MSG.LOBBY, {});
    this.broadcastPeers({ notice: LL.GAME_END_LOBBY() });
  }

  private notifyGameServer(seed: number) {
    const players = this.clients.map((c, slot) => {
      const p = this.players.get(c.sessionId);
      return { slot, name: p ? p.name : LL.DEFAULT_NAME(), resume_token: c.sessionId };
    });
    fetch(`${CONFIG.gameServerUrl}/start-match`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ room_id: this.roomId, players, mode: this.currentMode, seed, gameId: this.game.id }),
      signal: AbortSignal.timeout(CONFIG.gameServerTimeoutMs),
    }).catch(() => {});
  }

  private resolveKey(key: string, fallback: string): string {
    if (key in LL) {
      const fn = (LL as unknown as Record<string, () => string>)[key];
      return fn();
    }
    return fallback;
  }

  private gameInfo() {
    return {
      id: this.game.id,
      title: this.resolveKey(this.game.titleKey, this.game.id),
      maxPlayers: this.game.maxPlayers,
      modes: Object.fromEntries(
        Object.entries(this.game.modes).map(([k, m]) => [k, {
          id: m.id,
          title: this.resolveKey(m.titleKey, k),
          blurb: this.resolveKey(m.blurbKey, ""),
        }]),
      ),
    };
  }

  private hostId(): string {
    const first = this.clients[0];
    return first ? first.sessionId : "";
  }

  private slotOf(sessionId: string): number {
    return this.clients.findIndex(c => c.sessionId === sessionId);
  }

  private clientBySlot(slot: number): Client | undefined {
    return this.clients[slot];
  }

  private roomPublic() {
    return {
      id: this.roomId,
      gameId: this.game.id,
      mode: this.currentMode,
      title: this.metadata.title,
      count: this.clients.length,
      max: this.maxClients,
      phase: this.phase,
    };
  }

  private peersPayload() {
    return this.clients.map((c, i) => {
      const p = this.players.get(c.sessionId);
      return {
        slot: i,
        id: c.sessionId,
        name: p ? p.name : LL.DEFAULT_NAME(),
        host: c.sessionId === this.hostId(),
        dropped: false,
      };
    });
  }

  private broadcastPeers(extra?: Record<string, unknown>, exclude?: Client) {
    const payload = { t: MSG.PEERS, players: this.peersPayload(), room: this.roomPublic(), ...extra };
    this.broadcast(MSG.PEERS, payload, { except: exclude });
  }

  private sanitize(s: unknown, max: number): string {
    const raw = typeof s === "string" ? s : "";
    return raw.replace(/[<>&"'`]/g, "").trim().slice(0, max);
  }
}
