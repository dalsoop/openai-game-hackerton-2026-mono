// Roster 도메인 값객체 단위 테스트 — 좌석 배정의 핵심 파생 규칙을 검증한다.
import { describe, expect, it } from "vitest";
import { Roster, type RosterSnapshot } from "@/lib/domain/roster";

function snap(partial: Partial<RosterSnapshot>): RosterSnapshot {
  return {
    phase: "lobby",
    hostSessionId: "",
    players: [],
    ...partial,
  };
}

describe("Roster.fromSnapshot", () => {
  it("부분 스냅샷(players 미동기)을 빈 명단으로 소화한다", () => {
    const roster = Roster.fromSnapshot(
      { phase: "lobby", hostSessionId: "", players: undefined } as unknown as RosterSnapshot,
      "me",
    );
    expect(roster.seats).toEqual([]);
    expect(roster.you).toBe(-1);
    expect(roster.isHost).toBe(false);
  });

  it("좌석을 slot 순으로 정렬한다", () => {
    const roster = Roster.fromSnapshot(
      snap({
        players: [
          { slot: 3, sessionId: "c", name: "셋", connected: true },
          { slot: 1, sessionId: "a", name: "하나", connected: true },
          { slot: 2, sessionId: "b", name: "둘", connected: true },
        ],
      }),
      "a",
    );
    expect(roster.seats.map((s) => s.slot)).toEqual([1, 2, 3]);
  });

  it("hostSessionId 로 호스트를 가리고 me 로 내 좌석을 찾는다", () => {
    const roster = Roster.fromSnapshot(
      snap({
        hostSessionId: "b",
        players: [
          { slot: 1, sessionId: "a", name: "하나", connected: true },
          { slot: 2, sessionId: "b", name: "둘", connected: true },
        ],
      }),
      "a",
    );
    expect(roster.host?.playerId).toBe("b");
    expect(roster.me?.slot).toBe(1);
    expect(roster.you).toBe(1);
    expect(roster.isHost).toBe(false);
  });

  it("내가 호스트면 isHost 참, phase=playing 이면 playing 참", () => {
    const roster = Roster.fromSnapshot(
      snap({
        phase: "playing",
        hostSessionId: "a",
        players: [{ slot: 0, sessionId: "a", name: "하나", connected: true }],
      }),
      "a",
    );
    expect(roster.isHost).toBe(true);
    expect(roster.playing).toBe(true);
  });

  it("단절(connected=false) 좌석을 유지하되 연결 상태로 반영한다", () => {
    const roster = Roster.fromSnapshot(
      snap({
        players: [
          { slot: 0, sessionId: "a", name: "하나", connected: false },
          { slot: 1, sessionId: "b", name: "둘", connected: true },
        ],
      }),
      "a",
    );
    expect(roster.seats).toHaveLength(2); // 좌석은 밀리지 않는다
    expect(roster.seats[0]?.connected).toBe(false);
    expect(roster.seats[1]?.connected).toBe(true);
  });

  it("좌석 dlPct 를 0..100 으로 자른다", () => {
    const roster = Roster.fromSnapshot(
      snap({
        players: [
          { slot: 0, sessionId: "a", name: "하나", connected: true, dlPct: 140 },
          { slot: 1, sessionId: "b", name: "둘", connected: true },
        ],
      }),
      "a",
    );
    expect(roster.seats[0]?.dlPct).toBe(100);
    expect(roster.seats[1]?.dlPct).toBe(0);
  });
});

describe("Roster 엣지 케이스", () => {
  it("호스트가 명단에 없으면 host 는 null 이다", () => {
    const roster = Roster.fromSnapshot(
      snap({
        hostSessionId: "ghost",
        players: [{ slot: 0, sessionId: "a", name: "하나", connected: true }],
      }),
      "a",
    );
    expect(roster.host).toBeNull();
    expect(roster.isHost).toBe(false);
  });

  it("내 세션이 명단에 없으면 you=-1, me=null 이다", () => {
    const roster = Roster.fromSnapshot(
      snap({ players: [{ slot: 0, sessionId: "a", name: "하나", connected: true }] }),
      "stranger",
    );
    expect(roster.me).toBeNull();
    expect(roster.you).toBe(-1);
  });

  it("phase=lobby 면 playing 거짓 — 매치 밖 상태", () => {
    const roster = Roster.fromSnapshot(snap({ phase: "lobby" }), "a");
    expect(roster.playing).toBe(false);
  });
});
