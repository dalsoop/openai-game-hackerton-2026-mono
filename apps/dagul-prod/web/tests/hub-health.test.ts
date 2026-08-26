import { describe, expect, it } from "vitest";
import { healthBody } from "@/lib/hub/health";

describe("healthBody", () => {
  it("returns the live-hosts slot contract", () => {
    expect(JSON.parse(healthBody("server-yjh-dev1"))).toEqual({
      ok: true,
      slot: "server-yjh-dev1",
    });
  });

  it("is not plain ok text", () => {
    expect(healthBody("server-prod")).not.toBe("ok");
  });
});
