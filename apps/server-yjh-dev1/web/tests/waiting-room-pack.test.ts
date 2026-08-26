import { describe, expect, it } from "vitest";
import {
  allPacksReceived, clampPackPct, overlayOwnPackPct, packSeatTag, packSeatsOf, waitingRoomPackView,
} from "@/lib/domain/waiting-room-pack";
import { packPctFromLoader, shouldSendPackPct } from "@/lib/hub/loader-pack-pct";

describe("대기실 팩 도메인", () => {
  it("퍼센트를 0..100 정수로 자른다", () => {
    expect(clampPackPct(-4)).toBe(0);
    expect(clampPackPct(140)).toBe(100);
    expect(clampPackPct("37.4")).toBe(37);
    expect(clampPackPct("nope")).toBe(0);
  });

  it("접속 중인 좌석만 100 이어야 팩을 다 받은 것이다", () => {
    expect(allPacksReceived(packSeatsOf([
      { slot: 0, dropped: false, packPct: 100 },
      { slot: 1, dropped: true, packPct: 0 },
    ]))).toBe(true);
    expect(allPacksReceived(packSeatsOf([
      { slot: 0, connected: true, packPct: 40 },
      { slot: 1, connected: true, packPct: 100 },
    ]))).toBe(false);
  });

  it("내 좌석만 로컬 팩 진행률로 덮는다", () => {
    const seats = overlayOwnPackPct(packSeatsOf([
      { slot: 0, name: "나", packPct: 0 },
      { slot: 1, name: "너", packPct: 10 },
    ]), 0, 80);
    expect(seats[0]?.pct).toBe(80);
    expect(seats[1]?.pct).toBe(10);
  });

  it("목록과 칸에 같은 퍼센트를 붙인다", () => {
    const view = waitingRoomPackView([
      { slot: 0, name: "나", packPct: 0 },
      { slot: 1, name: "너", packPct: 10 },
    ], 0, 80);
    expect(view.seats[0]?.pct).toBe(80);
    expect(view.players[0]?.packPct).toBe(80);
    expect(view.players[1]?.packPct).toBe(10);
  });

  it("칸 태그는 팩 단계와 역할을 나눈다", () => {
    expect(packSeatTag(true, 0, false)).toBe("reconnect");
    expect(packSeatTag(false, 0, false)).toBe("pending");
    expect(packSeatTag(false, 40, false)).toBe("progress");
    expect(packSeatTag(false, 100, true)).toBe("host");
    expect(packSeatTag(false, 100, false)).toBe("waiting");
  });
});

describe("로더 → 팩 보고", () => {
  it("로더 상태를 0·진행·100 으로 바꾼다", () => {
    expect(packPctFromLoader("idle", 0.4)).toBe(0);
    expect(packPctFromLoader("downloading", 0.42)).toBe(42);
    expect(packPctFromLoader("compiling", 0.1)).toBe(100);
    expect(packPctFromLoader("ready", 0)).toBe(100);
  });

  it("5퍼센트와 끝점만 올린다", () => {
    expect(shouldSendPackPct(null, 0)).toBe(true);
    expect(shouldSendPackPct(0, 3)).toBe(false);
    expect(shouldSendPackPct(0, 5)).toBe(true);
    expect(shouldSendPackPct(40, 100)).toBe(true);
    expect(shouldSendPackPct(100, 100)).toBe(false);
    expect(shouldSendPackPct(80, 0)).toBe(true);
  });
});
