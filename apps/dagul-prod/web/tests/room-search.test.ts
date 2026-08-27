import { describe, expect, it } from "vitest";
import { filterRoomsByQuery, roomMatchesQuery } from "@/lib/hub/room-search";

const rooms = [
  { id: "aa", title: "저녁 한 판" },
  { id: "bb", title: "스파링" },
];

describe("roomMatchesQuery", () => {
  it("빈 질의는 전부 통과", () => {
    expect(roomMatchesQuery(rooms[0], "")).toBe(true);
    expect(roomMatchesQuery(rooms[0], "   ")).toBe(true);
  });

  it("제목·id 부분 일치", () => {
    expect(roomMatchesQuery(rooms[0], "저녁")).toBe(true);
    expect(roomMatchesQuery(rooms[0], "AA")).toBe(true);
    expect(roomMatchesQuery(rooms[0], "스파")).toBe(false);
  });
});

describe("filterRoomsByQuery", () => {
  it("맞는 방만 남긴다", () => {
    expect(filterRoomsByQuery(rooms, "스파").map((r) => r.id)).toEqual(["bb"]);
    expect(filterRoomsByQuery(rooms, "").map((r) => r.id)).toEqual(["aa", "bb"]);
  });
});
