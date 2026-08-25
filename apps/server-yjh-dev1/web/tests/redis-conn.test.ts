import { describe, expect, it } from "vitest";
import { redisConn } from "@/lib/hub/redis-conn";

describe("redisConn", () => {
  it("슬롯이 없으면 URL 을 그대로 둔다", () => {
    expect(redisConn("redis://127.0.0.1:6379", "")).toBe("redis://127.0.0.1:6379");
  });

  it("슬롯이 있으면 keyPrefix 를 붙인다", () => {
    expect(redisConn("redis://redis:6379", "server-yjh-dev1")).toEqual({
      host: "redis",
      port: 6379,
      db: 0,
      keyPrefix: "server-yjh-dev1:",
    });
  });
});
