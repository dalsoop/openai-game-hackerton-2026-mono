import { describe, expect, it } from "vitest";
import { buildRoomSharePath, buildRoomShareUrl, parseRoomShare, savePendingJoin, takePendingJoin } from "@/lib/hub/room-link";

describe("parseRoomShare", () => {
  it("room 쿼리가 없으면 null", () => {
    expect(parseRoomShare("")).toBeNull();
    expect(parseRoomShare("?pw=x")).toBeNull();
  });

  it("공개 방·비밀번호 방을 읽는다", () => {
    expect(parseRoomShare("?room=abc")).toEqual({ roomId: "abc", password: "" });
    expect(parseRoomShare("room=abc&pw=s3")).toEqual({ roomId: "abc", password: "s3" });
    expect(parseRoomShare("?room= r1 &pw=0420")).toEqual({ roomId: "r1", password: "0420" });
    expect(parseRoomShare("?room=")).toBeNull();
  });
});

describe("buildRoomSharePath", () => {
  it("비밀번호가 있을 때만 pw 를 붙인다", () => {
    expect(buildRoomSharePath({ roomId: "r1", password: "" })).toBe("/?room=r1");
    expect(buildRoomSharePath({ roomId: "r1", password: "s3" })).toBe("/?room=r1&pw=s3");
  });

  it("origin 과 합쳐 절대 URL 을 만든다", () => {
    expect(buildRoomShareUrl("https://dagul-prod.external.kr/", { roomId: "r1", password: "" }))
      .toBe("https://dagul-prod.external.kr/?room=r1");
    expect(buildRoomShareUrl("https://dagul-prod.external.kr", { roomId: "r1", password: "0420" }))
      .toBe("https://dagul-prod.external.kr/?room=r1&pw=0420");
  });
});

describe("pending join 저장", () => {
  it("쓰고 한 번 꺼내면 지운다", () => {
    const mem = new Map<string, string>();
    const store = {
      getItem: (k: string): string | null => mem.get(k) ?? null,
      setItem: (k: string, v: string): void => {mem.set(k, v);},
      removeItem: (k: string): void => {mem.delete(k);},
    };
    savePendingJoin(store, "k", { roomId: "r1", password: "pw" });
    expect(takePendingJoin(store, "k")).toEqual({ roomId: "r1", password: "pw" });
    expect(takePendingJoin(store, "k")).toBeNull();
  });

  it("깨진 JSON·방 id 없는 값은 버린다", () => {
    const mem = new Map<string, string>([["bad", "{"], ["empty", "{\"roomId\":\"\"}"], ["num", "{\"roomId\":1}"]]);
    const store = {
      getItem: (k: string): string | null => mem.get(k) ?? null,
      setItem: (k: string, v: string): void => {mem.set(k, v);},
      removeItem: (k: string): void => {mem.delete(k);},
    };
    expect(takePendingJoin(store, "missing")).toBeNull();
    expect(takePendingJoin(store, "bad")).toBeNull();
    expect(takePendingJoin(store, "empty")).toBeNull();
    expect(takePendingJoin(store, "num")).toBeNull();
  });

  it("password 가 문자열이 아니면 빈 값으로 정규화한다", () => {
    const mem = new Map<string, string>([["k", "{\"roomId\":\"r1\",\"password\":12}"]]);
    const store = {
      getItem: (k: string): string | null => mem.get(k) ?? null,
      setItem: (k: string, v: string): void => {mem.set(k, v);},
      removeItem: (k: string): void => {mem.delete(k);},
    };
    expect(takePendingJoin(store, "k")).toEqual({ roomId: "r1", password: "" });
  });
});
