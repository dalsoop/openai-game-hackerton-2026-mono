import { describe, expect, it } from "vitest";
import { healthBody } from "@/lib/hub/health";

describe("healthBody", () => {
  it("returns the live-hosts slot contract", () => {
    expect(JSON.parse(healthBody("server-yjh-dev1"))).toEqual({
      ok: true,
      slot: "server-yjh-dev1",
    });
    expect(JSON.parse(healthBody("dagul-prod", {
      ccu: 12, cap: 100, level: "quiet", admit: true,
    }))).toEqual({
      ok: true,
      slot: "dagul-prod",
      ccu: 12,
      cap: 100,
      level: "quiet",
      admit: true,
    });
  });

  it("is not plain ok text", () => {
    expect(healthBody("server-prod")).not.toBe("ok");
  });
});
