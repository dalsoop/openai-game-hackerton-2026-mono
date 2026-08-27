// 와이어 칸 이름·예측 층·SNAP 브리지 계약.
import { readdirSync, readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";

const ROOT = process.cwd();
const sourceOf = (p: string): string => readFileSync(p, "utf8");

function matchSchemaSrc(): string {
  const dir = join(ROOT, "lib/hub/match-schema");
  return readdirSync(dir)
    .filter((name) => name.endsWith(".ts") && name !== "index.ts")
    .map((name) => sourceOf(join(dir, name)))
    .join("\n");
}

describe("계약: JSON 스냅 키 = 스키마 필드", () => {
  it("packPlayerV2 리터럴이 hero·hud @type 이름과 같다", () => {
    const pack = sourceOf(join(ROOT, "lib/hub/match-authority-snap.ts"));
    const schema = matchSchemaSrc();
    const keys = [...pack.matchAll(/putOmit\(out,\s*"(\w+)"/g)].map((m) => m[1]);
    expect(keys.length).toBeGreaterThan(10);
    for (const key of keys) {
      expect(schema, key).toMatch(new RegExp(`@type\\([^)]+\\)\\s+${key}\\b`));
    }
  });

  it("hero·hud·event 스키마에 옛 줄임 칸이 없다", () => {
    const src = sourceOf(join(ROOT, "lib/hub/match-schema/hero.ts"))
      + sourceOf(join(ROOT, "lib/hub/match-schema/hero-hud.ts"))
      + sourceOf(join(ROOT, "lib/hub/match-schema/event.ts"));
    for (const banned of [
      "stunT", "rootT", "ccT", "guardT", "armorT", "spawnT", "launchT", "chargeT",
      "dmgOrbT", "woolT", "rouT", "rouRank", "rouPhase", "rouSpin", "rouLabel",
      "rouDesc", "springT", "slideT", "pullT", "pocketT", "hopT", "mobCd",
      "hitstunT", "comboCaptureT", "mvSpd",
    ]) {
      expect(src).not.toMatch(new RegExp(`@type\\([^)]+\\)\\s+${banned}\\b`));
    }
    expect(src).not.toMatch(/@type\("boolean"\)\s+elim\b/);
    expect(src).toContain('@type("uint32") tick');
    expect(src).toContain('@type("string") kind');
    expect(src).toContain('@type("int8") actor');
    expect(src).toContain('@type("int8") target');
    expect(src).toContain("@type(MatchEventDataSchema) data");
  });
});

describe("계약: 예측은 두 층이다", () => {
  it("Colyseus Predict 와 게스트 net_pred 를 합치지 않는다", () => {
    const predict = sourceOf(join(ROOT, "..", "project/core/net/engine_predict.gd"));
    const pred = sourceOf(join(ROOT, "..", "project/games/dagul/net/net_pred.gd"));
    const socket = sourceOf(join(ROOT, "..", "project/core/autoload/engine_socket.gd"));
    const world = sourceOf(join(ROOT, "..", "project/games/dagul/net/net_world.gd"));
    expect(predict).toContain("Colyseus.Predict.of");
    expect(predict).toMatch(/func tick\s*\(/);
    expect(pred).toContain("static func step(");
    expect(socket).toContain("_PredictScript");
    expect(socket).not.toContain("net_pred.gd");
    expect(world).toContain("res://games/dagul/net/net_pred.gd");
  });
});

describe("계약: 페이지 게스트는 MSG.SNAP 을 유지한다", () => {
  it("JSON 스냅 브리지를 삭제하지 않는다", () => {
    const wire = sourceOf(join(ROOT, "lib/contract/wire.ts"));
    expect(wire).toMatch(/SNAP:\s*"snap"/);
    expect(sourceOf(join(ROOT, "tests/config.test.ts"))).toContain("MSG.SNAP");
  });
});
