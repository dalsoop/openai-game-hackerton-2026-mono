import { describe, it } from "node:test";
import assert from "node:assert/strict";

import { CONFIG, Phase, MSG, ROUTES, MIME_TYPES } from "../src/config.ts";
import { getGame, allGames, defaultGame } from "../src/games/registry.ts";
import { LL } from "../src/i18n/init.ts";

describe("config.ts", () => {
  it("Phase has LOBBY and PLAYING", () => {
    assert.equal(Phase.LOBBY, "lobby");
    assert.equal(Phase.PLAYING, "playing");
  });

  it("MSG has at least 10 message types", () => {
    assert.ok(Object.keys(MSG).length >= 10);
  });

  it("every MSG value is a non-empty string", () => {
    for (const [k, v] of Object.entries(MSG)) {
      assert.equal(typeof v, "string", `MSG.${k} is not a string`);
      assert.ok(v.length > 0, `MSG.${k} is empty`);
    }
  });

  it("CONFIG.maxPayload is a positive number", () => {
    assert.ok(CONFIG.maxPayload > 0);
  });

  it("ROUTES has health, metrics, status arrays", () => {
    for (const key of ["health", "metrics", "status"] as const) {
      assert.ok(Array.isArray(ROUTES[key]));
      assert.ok(ROUTES[key].length > 0);
    }
  });

  it("MIME_TYPES covers common extensions", () => {
    for (const ext of [".html", ".js", ".css", ".json", ".png"]) {
      assert.ok(ext in MIME_TYPES, `missing MIME for ${ext}`);
    }
  });
});

describe("games/registry", () => {
  it("allGames returns at least 1 game", () => {
    assert.ok(allGames().length >= 1);
  });

  it("defaultGame returns a valid game", () => {
    const game = defaultGame();
    assert.ok(game.id.length > 0);
    assert.ok(game.maxPlayers > 0);
    assert.ok(Object.keys(game.modes).length > 0);
  });

  it("getGame returns registered games", () => {
    for (const game of allGames()) {
      const found = getGame(game.id);
      assert.ok(found);
      assert.equal(found.id, game.id);
    }
  });

  it("getGame returns undefined for unknown id", () => {
    assert.equal(getGame("nonexistent"), undefined);
  });

  it("every game has valid relay config", () => {
    for (const game of allGames()) {
      assert.equal(typeof game.relay.snapRelay, "boolean");
      assert.equal(typeof game.relay.inputRelay, "boolean");
      assert.equal(typeof game.relay.gameServerNotify, "boolean");
    }
  });

  it("every game mode has titleKey and blurbKey", () => {
    for (const game of allGames()) {
      for (const [modeId, mode] of Object.entries(game.modes)) {
        assert.ok(mode.titleKey.length > 0, `${game.id}/${modeId} missing titleKey`);
        assert.ok(mode.blurbKey.length > 0, `${game.id}/${modeId} missing blurbKey`);
      }
    }
  });
});

describe("i18n", () => {
  it("LL.DEFAULT_NAME returns a string", () => {
    assert.equal(typeof LL.DEFAULT_NAME(), "string");
    assert.ok(LL.DEFAULT_NAME().length > 0);
  });

  it("LL.playerJoined formats correctly", () => {
    const result = LL.playerJoined({ name: "테스트" });
    assert.ok(result.includes("테스트"));
  });

  it("LL.playerDropped formats with name and sec", () => {
    const result = LL.playerDropped({ name: "철수", sec: 30 });
    assert.ok(result.includes("철수"));
    assert.ok(result.includes("30"));
  });

  it("every game titleKey resolves in LL", () => {
    for (const game of allGames()) {
      const key = game.titleKey as keyof typeof LL;
      assert.ok(key in LL, `missing i18n key: ${game.titleKey}`);
    }
  });
});
