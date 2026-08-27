// 오늘 실측한 사고들의 재발 방지 묶음 — 각 케이스가 대비하는 상황은 주석에 적는다.
import { existsSync, readFileSync, readdirSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";

const ROOT = process.cwd();
const sourceOf = (p: string): string => readFileSync(p, "utf8");

describe("계약: 인코드 버퍼 하한", () => {
  it("Encoder.BUFFER_SIZE 는 256KB 이상이다 — 스냅 송신 무음 실패 재발 방지", () => {
    const src = sourceOf(join(ROOT, "server.ts"));
    const m = /Encoder\.BUFFER_SIZE\s*=\s*(\d+)\s*\*\s*1024/.exec(src);
    expect(m, "server.ts 에서 Encoder.BUFFER_SIZE 설정을 못 찾음").not.toBeNull();
    expect(Number(m?.[1])).toBeGreaterThanOrEqual(256);
  });
});

describe("계약: 오디오 컨텍스트는 close 하지 않는다", () => {
  it("closeAudioContexts 는 close() 대신 suspend() 를 쓴다 — 산 엔진 SampleNode null 참조 재발 방지", () => {
    const src = sourceOf(join(ROOT, "lib/godot/unlock-audio.ts"));
    const fn = src.split("export function closeAudioContexts")[1]?.split(/\nexport function/)[0] ?? "";
    expect(fn).not.toMatch(/\bctx\.close\(/);
    expect(fn).toMatch(/ctx\.suspend\(/);
  });
});

describe("계약: 텍스처 VRAM 압축", () => {
  const importFiles = ((): string[] => {
    const root = join(ROOT, "..", "project");
    const out: string[] = [];
    const walk = (dir: string): void => {
      for (const name of readdirSync(dir, { withFileTypes: true })) {
        if (name.name === ".git" || name.name === "web") {continue;}
        const full = join(dir, name.name);
        if (name.isDirectory()) {walk(full);}
        else if (name.name.endsWith(".png.import") || name.name.endsWith(".jpg.import")) {out.push(full);}
      }
    };
    walk(root);
    return out;
  })();

  it("텍스처 .import 파일이 존재한다 — 스캔 대상 0건은 스캔이 깨졌다는 뜻", () => {
    expect(importFiles.length).toBeGreaterThan(50);
  });

  it("모든 텍스처는 VRAM 압축(mode=2)이다 — 원시/무압축이면 힙 크래시 재발", () => {
    const uncompressed = importFiles.filter((p) => {
      const src = sourceOf(p);
      const m = /compress\/mode=(\d+)/.exec(src);
      return m === null || m[1] !== "2";
    });
    expect(uncompressed.map((p) => p.slice(ROOT.length)), "mode=2 가 아닌 텍스처").toEqual([]);
  });

  it("project.godot 의 VRAM 압축 전역 플래그가 켜져 있다", () => {
    const src = sourceOf(join(ROOT, "..", "project", "project.godot"));
    expect(src).toMatch(/import_etc2_astc\s*=\s*true/);
    expect(src).toMatch(/import_s3tc_bptc\s*=\s*true/);
  });
});

describe("계약: godot 빌드 실패는 배포로 이어지지 않는다", () => {
  it("godot:ship 스크립트가 build→publish→restart 를 && 로 묶는다", () => {
    const pkg = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8")) as {
      scripts: Record<string, string>;
    };
    const ship = pkg.scripts["godot:ship"];
    expect(ship, "package.json 에 godot:ship 스크립트가 없다").toBeDefined();
    expect(ship).toContain("godot:build");
    expect(ship).toContain("godot:publish");
    expect(ship).toContain("&&");
    // build 실패(비정상 종료) 시 뒤 단계가 실행되면 안 되므로 ; 나 || 로 이어붙이지 않는다.
    expect(ship).not.toMatch(/godot:build\s*(;|\|\|)/);
  });

  it("build-godot.sh 는 set -e(오류 즉시 중단)를 쓴다", () => {
    const src = sourceOf(join(ROOT, "..", "..", "..", "deploy/scripts/build-godot.sh"));
    expect(src).toMatch(/set -[a-z]*e[a-z]*\b/);
  });

  it("압축은 glue strip 이후에만 돈다 — 옛 index.js.br 가 패치본을 덮는 재발 방지", () => {
    const src = sourceOf(join(ROOT, "..", "..", "..", "deploy/scripts/build-godot.sh"));
    expect(src.indexOf("prepare-godot-export.mjs")).toBeLessThan(src.indexOf("brotli -f"));
  });

  it("godot:build 가 stale 스탬프를 같이 찍는다 — 로컬 재익스포트 뒤에도 검사가 옛 스탬프를 들지 않는다", () => {
    const src = sourceOf(join(ROOT, "..", "..", "..", "deploy/scripts/build-godot.sh"));
    expect(src).toContain("check-godot-stale.mjs");
    expect(src).toContain("--write-stamp");
    expect(src.indexOf("gen-godot-manifest.mjs")).toBeLessThan(src.indexOf("--write-stamp"));
  });
});

describe("계약: 매치 재시작 시 잔존 상태를 지운다", () => {
  it("clearMatchState 는 존 좌표·시네·미드타워 전 필드를 지운다", () => {
    const src = sourceOf(join(ROOT, "lib/hub/match-schema-write.ts"));
    const fn = src.split("export function clearMatchState")[1]?.split(/\nexport function|\nfunction/)[0] ?? "";
    for (const field of ["zoneCX", "zoneCY", "zonePhase", "startCountdown", "wantedSlot"]) {
      expect(fn, `clearMatchState 에 ${field} 리셋 누락`).toContain(`match.${field}`);
    }
    expect(fn).toContain("clearFinishCine(match)");
    expect(fn).toContain("clearMidTower(match)");
  });

  it("GD reset_match_visuals 는 킬피드와 마지막 이벤트 id 를 지운다", () => {
    const src = sourceOf(join(ROOT, "..", "project", "games/dagul/hud/hud.gd"));
    const fn = src.split("func reset_match_visuals")[1]?.split(/\nfunc /)[0] ?? "";
    expect(fn).toContain("_kill_feed.clear()");
    expect(fn).toContain("_last_kill_event_id = 0");
  });
});

describe("계약: 닫힌 소켓엔 SNAP_ON 을 보내지 않는다 (0.18 API 호환)", () => {
  it("usePageBridge 는 connection.isOpen 가드 뒤에서만 SNAP_ON 을 보낸다", () => {
    const src = sourceOf(join(ROOT, "hooks/usePageBridge.ts"));
    expect(src).toContain("connection?.isOpen");
    expect(src).toMatch(/hubSocketOpen\([^)]*\)[\s\S]{0,120}MSG\.SNAP_ON/);
  });

  it("@colyseus/sdk 0.18 의 Connection 클래스가 isOpen getter 를 유지한다", () => {
    const dts = sourceOf(join(ROOT, "node_modules/@colyseus/sdk/build/Connection.d.ts"));
    expect(dts).toMatch(/get isOpen\(\)/);
  });
});

describe("계약: 서버 재시작 파이프라인 산출물이 실존한다", () => {
  it("engine_input_channel.gd · engine_predict.gd 모듈이 존재한다", () => {
    expect(existsSync(join(ROOT, "..", "project", "core/net/engine_input_channel.gd"))).toBe(true);
    expect(existsSync(join(ROOT, "..", "project", "core/net/engine_predict.gd"))).toBe(true);
  });

  it("EnginePredict 는 ENABLED 상수로 통째로 끌 수 있다 — 콘솔 스팸 원인 격리 스위치", () => {
    const src = sourceOf(join(ROOT, "..", "project", "core/net/engine_predict.gd"));
    expect(src).toContain("const ENABLED := true");
    expect(src).toContain("ENABLED and ClassDB.class_exists");
  });
});

describe("계약: 재접속·이어받기는 좌석 park 해제 + ack 리셋을 같이 한다", () => {
  it("resumePlayingSeat 호출부 3곳 모두 parkSeat(false)·resetSeatAck 를 같이 부른다", () => {
    // 한쪽만 빠지면: park 만 풀리고 ack 는 옛 값 그대로 남아 재접속 직후 프레임에
    // 리컨사일이 낡은 ack 기준으로 예측을 되감는다.
    const src = sourceOf(join(ROOT, "lib/hub/LobbyRoom.ts"));
    const callSites = [...src.matchAll(/this\.resumePlayingSeat\(/g)].length;
    expect(callSites, "resumePlayingSeat 호출부 수 회귀 — 새 재접속 경로가 이 계약을 안 타는지 확인").toBeGreaterThanOrEqual(3);
    const body = src.split("private resumePlayingSeat")[1]?.split(/\n  private |\n  async /)[0] ?? "";
    expect(body).toContain("parkSeat(this.bag, player.slot, false)");
    expect(body).toContain("resetSeatAck(this.bag, player.slot)");
  });
});
