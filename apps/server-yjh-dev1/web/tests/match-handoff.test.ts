// 매치 핸드오프 소비 시점 — 부트 씬에서 KEY_MATCH 를 먼저 지우면
// match_started 가 리스너 없이 사라지고 godot-match-start 가 영구히 안 온다.
import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";
import { GAME_CATALOG } from "@/lib/games/catalog";

const PROJECT = join(process.cwd(), "..", "project");
const webGd = (rel: string): string => readFileSync(join(PROJECT, rel), "utf8");

function funcBody(src: string, name: string): string {
  const re = new RegExp(`func ${name}\\([^)]*\\)[^{\\n]*\\n`);
  const m = src.match(re);
  if (!m || m.index === undefined) {return "";}
  const start = m.index + m[0].length;
  const rest = src.slice(start);
  const next = rest.search(/\nfunc /);
  return next < 0 ? rest : rest.slice(0, next);
}

describe("계약: KEY_MATCH 소비는 셸 연결 이후", () => {
  const nm = webGd("core/autoload/network_manager.gd");
  const shell = webGd("core/shell/match_shell.gd");
  const boot = webGd("core/shell/boot.gd");

  it("부트 씬은 트리가 잠긴 _ready 에서 즉시 씬을 바꾸지 않는다", () => {
    const ready = funcBody(boot, "_ready").replace(/#.*$/gm, "");
    expect(ready).toMatch(/call_deferred\(\s*"change_scene_to_file"/);
    expect(ready).not.toMatch(/change_scene_to_file\s*\(/);
  });

  it("오토로드 _ready 는 소켓을 열지 않는다", () => {
    const ready = funcBody(nm, "_ready").replace(/#.*$/gm, "");
    expect(ready).not.toMatch(/_connect|start_handoff/);
  });

  it("_connect 는 재접속만 하고 MATCH 를 소비하지 않는다", () => {
    const code = funcBody(nm, "_connect").replace(/#.*$/gm, "");
    expect(code).not.toMatch(/consume_pending_match/);
  });

  it("소비는 재접속 합류 또는 셸 _ready 에서만 일어난다", () => {
    const join = funcBody(nm, "_on_joined");
    const ready = funcBody(shell, "_ready");
    const fromJoin = /consume_pending_match/.test(join);
    const fromShell = /consume_pending_match/.test(ready);
    expect(fromJoin || fromShell, "합류·셸 어느 쪽에서도 소비하지 않음").toBe(true);
  });

  it("셸은 신호를 붙인 뒤 핸드오프를 연다", () => {
    const ready = funcBody(shell, "_ready");
    const connectAt = ready.indexOf("match_started.connect");
    const handoffAt = ready.indexOf("start_handoff");
    const consumeAt = ready.indexOf("consume_pending_match");
    expect(connectAt).toBeGreaterThanOrEqual(0);
    expect(handoffAt).toBeGreaterThan(connectAt);
    if (consumeAt >= 0) {expect(consumeAt).toBeGreaterThan(handoffAt);}
  });
});

describe("계약: 카탈로그 표시명 키는 번역 정본에 있다", () => {
  it("titleKey 는 lobby 네임스페이스 아래 ko.json 에 실재한다", () => {
    const ko = JSON.parse(readFileSync(join(process.cwd(), "messages/ko.json"), "utf8")) as {
      lobby?: Record<string, unknown>;
    };
    const flatten = (obj: Record<string, unknown>, prefix = ""): string[] =>
      Object.entries(obj).flatMap(([k, v]) =>
        typeof v === "object" && v !== null
          ? flatten(v as Record<string, unknown>, `${prefix}${k}.`)
          : [`${prefix}${k}`],
      );
    const known = new Set(flatten(ko.lobby ?? {}));
    const missing = GAME_CATALOG.map((g) => g.titleKey).filter((k) => !known.has(k));
    expect(missing, "Lobby 가 t(titleKey) 로 조회하는 키").toEqual([]);
  });
});
