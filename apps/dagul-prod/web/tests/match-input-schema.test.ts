import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";
import { ARENA_SIZE } from "@/lib/hub/match-covers";
import { inputOwnerSession } from "@/lib/hub/match-engine";
import {
  idleHoldFrame, MATCH_INPUT_SANITIZE, MatchInputSchema, matchInputFromFrame,
} from "@/lib/hub/match-input-schema";

const ROOT = process.cwd();
const sourceOf = (p: string): string => readFileSync(p, "utf8");

describe("MatchInputSchema", () => {
  it("엔진 입력 채널은 필드 목록을 복제하지 않고 seq 만 건너뛴다", () => {
    // engine_socket.gd 는 defineInput 프레임 전송을 core/net/engine_input_channel.gd 로,
    // Predict PoC 를 core/net/engine_predict.gd 로 위임한다(모듈 분리 — 디버깅 격리 스위치).
    const channel = sourceOf(join(ROOT, "..", "project", "core/net/engine_input_channel.gd"));
    expect(channel).toContain('if str(key) == "seq"');
    expect(channel).not.toContain("_INPUT_FLOATS");
    expect(channel).not.toContain("TEMP DIAGNOSTIC");
    expect(channel).toContain("for key in msg");
    const predict = sourceOf(join(ROOT, "..", "project", "core/net/engine_predict.gd"));
    expect(predict).toContain("int(_native.tick())");
    const socket = sourceOf(join(ROOT, "..", "project", "core/autoload/engine_socket.gd"));
    expect(socket).toContain("_input.flush(_room)");
    expect(socket).toContain("_PredictScript.bind(_room)");
    expect(socket).not.toContain("send_message(WebContract.MSG_INPUT");
  });

  it("sanitize 범위가 아레나를 덮는다", () => {
    expect(MATCH_INPUT_SANITIZE.aimX[1]).toBe(ARENA_SIZE.x);
    expect(MATCH_INPUT_SANITIZE.mx).toEqual([-1, 1]);
  });

  it("프레임을 MatchInput 으로 옮기고 0.5 초과를 참으로 본다", () => {
    const frame = new MatchInputSchema();
    frame.mx = 0.4;
    frame.firePressed = 1;
    frame.dash = 0;
    frame.mobility = 1;
    frame.emote = 2;
    const cmd = matchInputFromFrame(frame, 7);
    expect(cmd.mx).toBe(0.4);
    expect(cmd.firePressed).toBe(true);
    expect(cmd.dash).toBe(true);
    expect(cmd.seq).toBe(7);
    expect(cmd.emote).toBe(2);
  });

  it("아이들 홀드는 이동을 남기고 에지를 끈다", () => {
    const latest = new MatchInputSchema();
    latest.mx = 1;
    latest.fire = 1;
    latest.firePressed = 1;
    latest.aimX = 100;
    const idle = idleHoldFrame(latest);
    expect(idle).not.toBe(true);
    if (idle === true) {return;}
    expect(idle.mx).toBe(1);
    expect(idle.fire).toBe(1);
    expect(idle.firePressed).toBeUndefined();
    expect(idle.emote).toBe(-1);
  });
});

describe("inputOwnerSession", () => {
  const claim = { guestId: 1, guestKey: "k" };
  it("엔진 claim 이 있으면 엔진 세션이 주인이다", () => {
    const players = [{ sessionId: "page", slot: 0 }];
    const claims = new Map([["page", claim]]);
    const engines = new Map([["eng", claim]]);
    expect(inputOwnerSession(0, players, claims, engines)).toBe("eng");
  });

  it("엔진이 없으면 좌석 세션이다", () => {
    const players = [{ sessionId: "page", slot: 0 }];
    expect(inputOwnerSession(0, players, new Map(), new Map())).toBe("page");
  });
});
