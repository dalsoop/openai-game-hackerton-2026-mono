import { describe, expect, it } from "vitest";
import { redisConn } from "@/lib/hub/redis-conn";

describe("redisConn", () => {
  it("returns the official URL string even when a slot is set", () => {
    expect(redisConn("redis://redis:6379", "server-yjh-dev1")).toBe("redis://redis:6379");
  });

  it("does not wrap the URL in an ioredis keyPrefix object", () => {
    expect(typeof redisConn("redis://127.0.0.1:6379", "server-prod")).toBe("string");
  });
});
