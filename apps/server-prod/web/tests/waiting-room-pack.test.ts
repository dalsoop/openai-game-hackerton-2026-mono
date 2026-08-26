import { describe, expect, it } from "vitest";
import {
  Seat, clampPackPct, connectedSeatsPacked, overlayOwnPackPct, packKind, shouldSendPackPct, slotBadge,
} from "@dalsoop/hub-kernel";
import { packPctFromLoader } from "@/lib/hub/loader-pack-pct";

function seat(
  slot: number, name: string, connected: boolean, packPct: number, isHost = false,
): Seat {
  return new Seat(slot, `p${slot}`, name, isHost, connected, packPct);
}

describe("대기실 팩 도메인", () => {
  it("퍼센트를 0..100 정수로 자른다", () => {
    expect(clampPackPct(-4)).toBe(0);
    expect(clampPackPct(140)).toBe(100);
    expect(clampPackPct("37.4")).toBe(37);
    expect(clampPackPct("nope")).toBe(0);
  });

  it("접속 중인 좌석만 100 이어야 팩을 다 받은 것이다", () => {
    expect(connectedSeatsPacked([
      seat(0, "나", true, 100),
      seat(1, "너", false, 0),
    ])).toBe(true);
    expect(connectedSeatsPacked([
      seat(0, "나", true, 40),
      seat(1, "너", true, 100),
    ])).toBe(false);
  });

  it("내 좌석만 로컬 팩 진행률로 덮는다", () => {
    const seats = overlayOwnPackPct([
      seat(0, "나", true, 0),
      seat(1, "너", true, 10),
    ], 0, 80);
    expect(seats[0]?.packPct).toBe(80);
    expect(seats[1]?.packPct).toBe(10);
  });

  it("칸 배지는 단절을 팩보다 먼저 본다", () => {
    expect(slotBadge(seat(0, "나", false, 0))).toBe("reconnect");
    expect(slotBadge(seat(0, "나", true, 0))).toBe("pending");
    expect(slotBadge(seat(0, "나", true, 40))).toBe("progress");
    expect(slotBadge(seat(0, "나", true, 100, true))).toBe("host");
    expect(slotBadge(seat(0, "나", true, 100))).toBe("waiting");
  });

  it("팩 단계는 퍼센트만 본다", () => {
    expect(packKind(0)).toBe("pending");
    expect(packKind(40)).toBe("progress");
    expect(packKind(100)).toBe("ready");
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
