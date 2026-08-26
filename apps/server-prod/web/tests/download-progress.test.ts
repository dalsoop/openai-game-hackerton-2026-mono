import { describe, expect, it } from "vitest";
import { allSeatsReady, clampPct, overlaySelf, roomDownload, seatTag, seatsOf } from "@/lib/domain/download";
import { pctFromLoader, shouldReport } from "@/lib/hub/download-progress";

describe("download domain", () => {
  it("퍼센트를 0..100 정수로 자른다", () => {
    expect(clampPct(-4)).toBe(0);
    expect(clampPct(140)).toBe(100);
    expect(clampPct("37.4")).toBe(37);
    expect(clampPct("nope")).toBe(0);
  });

  it("접속 중인 좌석만 100 이어야 준비다", () => {
    expect(allSeatsReady(seatsOf([
      { slot: 0, dropped: false, dlPct: 100 },
      { slot: 1, dropped: true, dlPct: 0 },
    ]))).toBe(true);
    expect(allSeatsReady(seatsOf([
      { slot: 0, connected: true, dlPct: 40 },
      { slot: 1, connected: true, dlPct: 100 },
    ]))).toBe(false);
  });

  it("내 좌석만 로컬 진행률로 덮는다", () => {
    const seats = overlaySelf(seatsOf([
      { slot: 0, name: "나", dlPct: 0 },
      { slot: 1, name: "너", dlPct: 10 },
    ]), 0, 80);
    expect(seats[0]?.pct).toBe(80);
    expect(seats[1]?.pct).toBe(10);
  });

  it("목록과 칸에 같은 퍼센트를 붙인다", () => {
    const view = roomDownload([
      { slot: 0, name: "나", dlPct: 0 },
      { slot: 1, name: "너", dlPct: 10 },
    ], 0, 80);
    expect(view.seats[0]?.pct).toBe(80);
    expect(view.players[0]?.dlPct).toBe(80);
    expect(view.players[1]?.dlPct).toBe(10);
  });

  it("칸 태그는 받기 단계와 역할을 나눈다", () => {
    expect(seatTag(true, 0, false)).toBe("reconnect");
    expect(seatTag(false, 0, false)).toBe("pending");
    expect(seatTag(false, 40, false)).toBe("progress");
    expect(seatTag(false, 100, true)).toBe("host");
    expect(seatTag(false, 100, false)).toBe("waiting");
  });
});

describe("loader report", () => {
  it("로더 상태를 0·진행·100 으로 바꾼다", () => {
    expect(pctFromLoader("idle", 0.4)).toBe(0);
    expect(pctFromLoader("downloading", 0.42)).toBe(42);
    expect(pctFromLoader("compiling", 0.1)).toBe(100);
    expect(pctFromLoader("ready", 0)).toBe(100);
  });

  it("5퍼센트와 끝점만 올린다", () => {
    expect(shouldReport(null, 0)).toBe(true);
    expect(shouldReport(0, 3)).toBe(false);
    expect(shouldReport(0, 5)).toBe(true);
    expect(shouldReport(40, 100)).toBe(true);
    expect(shouldReport(100, 100)).toBe(false);
    expect(shouldReport(80, 0)).toBe(true);
  });
});
