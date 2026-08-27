// START 페이로드 경계 — 서버·React·Godot 가 같은 형태로만 핸드오프한다.
import { describe, expect, it } from "vitest";
import {
  matchInfoFromPlayingState, matchInfoFromStoredStart, parseStartPayload, startPayloadFromPlayingState,
} from "@/lib/hub/start-payload";

const valid = {
  you: 0,
  host: true,
  seed: 42,
  mode: "full",
  seats: [
    { slot: 0, name: "호스트", connected: true, characterId: "unknown" },
    { slot: 1, name: "게스트", connected: false, characterId: "unknown" },
  ],
};

describe("parseStartPayload", () => {
  it("정상 본문은 필드가 확정된 타입으로 나온다", () => {
    const p = parseStartPayload(valid);
    expect(p).toEqual(valid);
  });

  it("시드·좌석 번호가 없으면 거절한다 — 매치 시작으로 쓸 수 없다", () => {
    expect(parseStartPayload(null)).toBeNull();
    expect(parseStartPayload("start")).toBeNull();
    expect(parseStartPayload({ you: 0, host: true, mode: "full" })).toBeNull();
    expect(parseStartPayload({ ...valid, seed: 0 })).toBeNull();
    expect(parseStartPayload({ ...valid, you: "x" })).toBeNull();
  });

  it("저장된 MATCH 로 브릿지용 matchInfo 를 복원한다", () => {
    const info = matchInfoFromStoredStart(JSON.stringify(valid), {
      roomId: "r1",
      reconnectionToken: "tok",
      gameId: "sparring",
    }, "호스트");
    expect(info).toEqual({
      roomId: "r1",
      name: "호스트",
      slot: 0,
      resumeToken: "tok",
      match: valid,
      gameId: "sparring",
    });
  });

  it("반전: 깨진 MATCH 는 복원하지 않는다", () => {
    const room = { roomId: "r1", reconnectionToken: "tok" };
    expect(matchInfoFromStoredStart(null, room, "A")).toBeNull();
    expect(matchInfoFromStoredStart("{", room, "A")).toBeNull();
    expect(matchInfoFromStoredStart(JSON.stringify({ you: 0, seed: 0 }), room, "A")).toBeNull();
  });

  it("불량 좌석은 버리고, connected 생략은 접속 중으로 본다", () => {
    const p = parseStartPayload({
      ...valid,
      seats: [{ slot: 2, name: "둘" }, { name: "번호없음" }, null],
    });
    expect(p?.seats).toEqual([{ slot: 2, name: "둘", connected: true, characterId: "unknown" }]);
  });

  it("engineJoin 은 roomId 가 있을 때만 남긴다", () => {
    expect(parseStartPayload({ ...valid, engineJoin: { roomId: "abc" } })?.engineJoin)
      .toEqual({ roomId: "abc" });
    expect(parseStartPayload({
      ...valid, engineJoin: { roomId: "abc", endpoint: "https://play.example" },
    })?.engineJoin).toEqual({ roomId: "abc", endpoint: "https://play.example" });
    expect(parseStartPayload({ ...valid, engineJoin: { roomId: "" } })?.engineJoin)
      .toBeUndefined();
  });

  it("playing 스키마에서 START 동등 본문을 다시 만든다", () => {
    const payload = startPayloadFromPlayingState({
      phase: "playing",
      seed: 42,
      mode: "full",
      hostSessionId: "s1",
      players: [
        { slot: 1, sessionId: "s1", name: "호스트", connected: true, characterId: "a3" },
        { slot: 2, sessionId: "s2", name: "게스트", connected: true },
      ],
    }, "s1", "r1");
    expect(payload?.you).toBe(1);
    expect(payload?.host).toBe(true);
    expect(payload?.seed).toBe(42);
    expect(payload?.engineJoin).toEqual({ roomId: "r1" });
    expect(payload?.seats.map((s) => s.slot)).toEqual([1, 2]);
    const info = matchInfoFromPlayingState({
      phase: "playing", seed: 42, mode: "full", hostSessionId: "s0", gameId: "dagul",
      players: [{ slot: 0, sessionId: "me", name: "나", connected: true }],
    }, "me", { roomId: "r9", reconnectionToken: "tok", gameId: "sparring" }, "나");
    expect(info?.slot).toBe(0);
    expect(info?.match.you).toBe(0);
    expect(info?.gameId).toBe("sparring");
  });

  it("반전: lobby·시드 없음·내 좌석 없으면 재구성하지 않는다", () => {
    const playing = {
      phase: "playing", seed: 42, mode: "full", hostSessionId: "s1",
      players: [{ slot: 0, sessionId: "s1", name: "호스트", connected: true }],
    };
    expect(startPayloadFromPlayingState({ ...playing, phase: "lobby" }, "s1", "r1")).toBeNull();
    expect(startPayloadFromPlayingState({ ...playing, seed: 0 }, "s1", "r1")).toBeNull();
    expect(startPayloadFromPlayingState(playing, "other", "r1")).toBeNull();
    expect(matchInfoFromPlayingState(playing, "", { roomId: "r1", reconnectionToken: "t" }, "A")).toBeNull();
  });

  it("좌석 characterId 는 카탈로그만 통과하고 그 외는 기본값이다", () => {
    const p = parseStartPayload({
      ...valid,
      seats: [
        { slot: 0, name: "호스트", connected: true, characterId: "a3" },
        { slot: 1, name: "게스트", connected: true, characterId: "??? " },
      ],
    });
    expect(p?.seats.map((s) => s.characterId)).toEqual(["a3", "unknown"]);
  });
});
