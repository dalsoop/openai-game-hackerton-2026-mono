import { describe, it } from "node:test";
import assert from "node:assert/strict";

import { CONFIG, Phase, MSG, ROUTES, MIME_TYPES } from "../src/config.ts";
import { MODES, ARENA } from "../src/modes.ts";

/* ------------------------------------------------------------------ */
/*  1. config.ts                                                      */
/* ------------------------------------------------------------------ */

describe("config.ts", () => {
  it("Phase has LOBBY and PLAYING", () => {
    assert.equal(Phase.LOBBY, "lobby");
    assert.equal(Phase.PLAYING, "playing");
  });

  it("MSG has at least 10 message types", () => {
    const keys = Object.keys(MSG);
    assert.ok(keys.length >= 10, `MSG has only ${keys.length} keys`);
  });

  it("every MSG value is a non-empty string", () => {
    for (const [k, v] of Object.entries(MSG)) {
      assert.equal(typeof v, "string", `MSG.${k} is not a string`);
      assert.ok(v.length > 0, `MSG.${k} is empty`);
    }
  });

  it("CONFIG.maxPayload is a positive number", () => {
    assert.equal(typeof CONFIG.maxPayload, "number");
    assert.ok(CONFIG.maxPayload > 0);
  });

  it("CONFIG has expected defaults", () => {
    assert.equal(CONFIG.defaultMode, "classic");
    assert.equal(CONFIG.defaultName, "손님");
    assert.equal(CONFIG.maxNameLength, 12);
  });

  it("ROUTES has health, metrics, status arrays", () => {
    for (const key of ["health", "metrics", "status"] as const) {
      assert.ok(Array.isArray(ROUTES[key]), `ROUTES.${key} is not an array`);
      assert.ok(ROUTES[key].length > 0, `ROUTES.${key} is empty`);
    }
  });

  it("MIME_TYPES covers common extensions", () => {
    for (const ext of [".html", ".js", ".css", ".json", ".png"]) {
      assert.ok(ext in MIME_TYPES, `missing MIME for ${ext}`);
    }
  });
});

/* ------------------------------------------------------------------ */
/*  2. modes.ts                                                       */
/* ------------------------------------------------------------------ */

describe("modes.ts", () => {
  it("ARENA dimensions", () => {
    assert.equal(ARENA.w, 7840);
    assert.equal(ARENA.h, 4760);
    assert.equal(ARENA.cx, 3920);
    assert.equal(ARENA.cy, 2380);
  });

  it("MODES has classic, gun-semi, gun-auto, item, full", () => {
    const expected = ["classic", "gun-semi", "gun-auto", "item", "full"];
    for (const id of expected) {
      assert.ok(id in MODES, `missing mode: ${id}`);
    }
  });

  it("every mode has title and blurb", () => {
    for (const [id, mode] of Object.entries(MODES)) {
      assert.ok(typeof mode.title === "string" && mode.title.length > 0, `${id}.title missing`);
      assert.ok(typeof mode.blurb === "string" && mode.blurb.length > 0, `${id}.blurb missing`);
    }
  });

  it("every mode has a startWeapon", () => {
    for (const [id, mode] of Object.entries(MODES)) {
      assert.ok(mode.startWeapon.length > 0, `${id}.startWeapon empty`);
    }
  });

});
