// 와이어 칸 이름·예측 층·SNAP 브리지 계약.
import { closeSync, existsSync, openSync, readdirSync, readFileSync, readSync } from "fs";
import { wasmHasDylinkSection } from "@/lib/godot/wasm-template.mjs";
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

const HAS_COLYSEUS = existsSync(join(ROOT, "..", "project/addons/colyseus/plugin.cfg"));

describe("계약: 예측은 두 층이다", () => {
  it("게스트 net_pred 가 독립 모듈이다", () => {
    const pred = sourceOf(join(ROOT, "..", "project/games/dagul/net/net_pred.gd"));
    const socket = sourceOf(join(ROOT, "..", "project/core/autoload/engine_socket.gd"));
    const world = sourceOf(join(ROOT, "..", "project/games/dagul/net/net_world.gd"));
    expect(pred).toContain("static func step(");
    expect(socket).toContain("_PredictScript");
    expect(socket).not.toContain("net_pred.gd");
    expect(world).toContain("res://games/dagul/net/net_pred.gd");
  });

  it.skipIf(!HAS_COLYSEUS)("Colyseus Predict 가 engine_predict 에 있다", () => {
    const predict = sourceOf(join(ROOT, "..", "project/core/net/engine_predict.gd"));
    expect(predict).toContain("Colyseus.Predict.of");
    expect(predict).toMatch(/func tick\s*\(/);
  });
});

describe("계약: GDExtension side.wasm 차단", () => {
  it("addons/colyseus 가 없다 — side.wasm 메모리 크래시 방지", () => {
    expect(existsSync(join(ROOT, "..", "project/addons/colyseus/plugin.cfg"))).toBe(false);
  });

  it("export_presets.cfg 에서 extensions_support 가 꺼져 있다", () => {
    const presets = sourceOf(join(ROOT, "..", "project/export_presets.cfg"));
    expect(presets).toContain("extensions_support=false");
    expect(presets).toContain("thread_support=false");
    expect(presets).toContain('custom_template/release=""');
    expect(presets).not.toContain("web_dlink");
  });

  it("public/godot 에 side.wasm 파일이 없다", () => {
    const dir = join(ROOT, "public/godot/dagul");
    for (const name of ["index.side.wasm", "index.side.wasm.br", "index.side.wasm.gz"]) {
      expect(existsSync(join(dir, name)), name).toBe(false);
    }
    const jsPath = join(dir, "index.js");
    // wasm/pck 는 git 에 없다. CI lint-web 은 익스포트 전에 돈다.
    if (!existsSync(jsPath)) {return;}
    expect(sourceOf(jsPath)).not.toContain(".side.wasm");
  });

  it("발행 wasm 은 dlink 템플릿이 아니다", () => {
    const wasm = join(ROOT, "public/godot/dagul/index.wasm");
    if (!existsSync(wasm)) {return;}
    expect(existsSync(wasm)).toBe(true);
    const fd = openSync(wasm, "r");
    const head = Buffer.alloc(64);
    try {
      readSync(fd, head, 0, 64, 0);
    } finally {
      closeSync(fd);
    }
    expect(wasmHasDylinkSection(head)).toBe(false);
  });

  it("runtime·config 가 side.wasm 을 로드하지 않는다", () => {
    const runtime = sourceOf(join(ROOT, "lib/godot/runtime.ts"));
    const config = sourceOf(join(ROOT, "lib/godot/engine-config.ts"));
    const store = sourceOf(join(ROOT, "lib/godot/asset-store.ts"));
    expect(runtime).not.toContain("sideWasm");
    expect(runtime).not.toContain("extLib");
    expect(runtime).not.toContain("extBuffer");
    expect(config).toContain("gdextensionLibs: []");
    expect(store).not.toContain("sideWasm");
    expect(store).not.toContain("extLibUrl");
  });

  it("public/godot 에 libcolyseus wasm 이 없다", () => {
    const lib = join(ROOT, "public/godot/dagul/libcolyseus_godot.web.wasm32.release.wasm");
    expect(existsSync(lib)).toBe(false);
  });

  it("이미지·서버가 libcolyseus 를 다시 실어 주지 않는다", () => {
    const docker = sourceOf(join(ROOT, "Dockerfile"));
    expect(docker).not.toContain("libcolyseus");
    expect(docker).not.toContain("addons/colyseus");
    const server = sourceOf(join(ROOT, "server.ts"));
    expect(server).not.toContain("libcolyseus");
    expect(sourceOf(join(ROOT, "lib/godot/asset-store.ts"))).not.toContain("libcolyseus");
  });

  it("gdextensionLibs 가 비어 있다", () => {
    const cfg = sourceOf(join(ROOT, "lib/godot/engine-config.ts"));
    expect(cfg).toContain("gdextensionLibs: []");
    expect(sourceOf(join(ROOT, "hooks/GameFlowProvider.tsx"))).toContain("useHostNoiseFilters");
  });
});

describe("계약: 낡은 Godot 압축본은 발행되지 않는다", () => {
  it("publish 는 존재만 보고 .br/.gz 를 복사하지 않는다", () => {
    const publish = sourceOf(join(ROOT, "scripts/publish-godot-assets.mjs"));
    expect(publish).toContain("shouldCopyName");
    expect(publish).toContain("prepareGodotExportDir");
    expect(publish).toContain("dropStaleEncodings");
    expect(publish).not.toMatch(/if \(!existsSync\(from\)\) \{continue;\}[\s\S]*copyFileSync\(from, to\)/);
  });

  it("build-godot 는 glue strip 뒤에 압축하고 side.wasm 은 압축하지 않는다", () => {
    const sh = sourceOf(join(ROOT, "..", "..", "..", "deploy/scripts/build-godot.sh"));
    const prep = sh.indexOf("prepare-godot-export.mjs");
    const brotli = sh.indexOf("brotli -f");
    expect(prep).toBeGreaterThan(-1);
    expect(brotli).toBeGreaterThan(prep);
    expect(sh).not.toContain("index.side.wasm");
    expect(sh).toMatch(/for f in index\.wasm index\.pck index\.js;/);
  });

  it("check-contract 가 발행 디렉터리의 낡은 압축본을 실패로 본다", () => {
    const src = sourceOf(join(ROOT, "scripts/check-contract.mjs"));
    expect(src).toContain("listStaleEncodings");
    expect(src).toContain("public/godot");
    expect(src).toContain("project/web");
    expect(src).toContain("assertNoSideWasmGlue");
    expect(src).toContain("assertNoDlinkWasm");
    expect(src).toContain("wasmHasDylinkSection");
  });

  it("이미지 빌드는 --link 심링크를 거부한다", () => {
    const docker = sourceOf(join(ROOT, "Dockerfile"));
    expect(docker).toContain("find public/godot -type l");
    expect(docker).toContain("not --link");
  });

  it("무버전 Godot 응답은 엣지에 남기지 않는다", () => {
    const src = sourceOf(join(ROOT, "server.ts"));
    expect(src).toContain("godotCacheHeaders");
    expect(sourceOf(join(ROOT, "lib/godot/serve-encoding.ts"))).toContain("cdn-cache-control");
    expect(sourceOf(join(ROOT, "lib/godot/serve-encoding.ts"))).toContain("no-store");
  });

  it("glue 를 고치면 매니페스트 해시도 다시 찍는다", () => {
    const src = sourceOf(join(ROOT, "scripts/prepare-godot-export.mjs"));
    expect(src).toContain("result.stripped");
    expect(src).toContain("gen-godot-manifest.mjs");
  });
});

describe("계약: 유틸 함수 SSOT", () => {
  function collectTsSources(dir: string): string[] {
    const out: string[] = [];
    for (const name of readdirSync(dir)) {
      const full = join(dir, name);
      if (name.endsWith(".ts") && !name.endsWith(".test.ts")) {out.push(full);}
    }
    return out;
  }

  it("syncLen·clamp01·moveToward 로컬 재구현이 없다", () => {
    const ssotFiles = new Set([
      join(ROOT, "lib/util/math.ts"),
      join(ROOT, "lib/hub/schema-util.ts"),
    ]);
    const dirs = [join(ROOT, "lib/hub"), join(ROOT, "lib/godot")];
    const banned = /function (syncLen|clamp01|moveToward)\b/;
    const files = dirs.flatMap(collectTsSources).filter((file) => !ssotFiles.has(file));
    for (const file of files) {
      const m = banned.exec(sourceOf(file));
      expect(m, `${file} 에 로컬 ${m?.[1]} 재구현`).toBeNull();
    }
  });
});

describe("계약: 페이지 게스트는 MSG.SNAP 을 유지한다", () => {
  it("JSON 스냅 브리지를 삭제하지 않는다", () => {
    const wire = sourceOf(join(ROOT, "lib/contract/wire.ts"));
    expect(wire).toMatch(/SNAP:\s*"snap"/);
    expect(sourceOf(join(ROOT, "tests/config.test.ts"))).toContain("MSG.SNAP");
  });
});
