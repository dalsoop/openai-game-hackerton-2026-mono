import { mkdtempSync, mkdirSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";
import { describe, expect, it } from "vitest";
import { isStaleRevision, revisionBody, revisionIdOf } from "@/lib/hub/revision";
import { deployedBuildId } from "@/lib/hub/revision-fs";
import { healthBody } from "@/lib/hub/health";

describe("revision 계약", () => {
  it("id 만 담는다", () => {
    expect(JSON.parse(revisionBody("abc"))).toEqual({ id: "abc" });
  });

  it("/health 와 필드를 섞지 않는다", () => {
    expect(JSON.parse(healthBody("slot"))).not.toHaveProperty("id");
    expect(JSON.parse(revisionBody("abc"))).not.toHaveProperty("ok");
  });

  it("본문에서 id·buildId·version 을 읽는다", () => {
    expect(revisionIdOf({ id: "a" })).toBe("a");
    expect(revisionIdOf({ buildId: "b" })).toBe("b");
    expect(revisionIdOf({ version: "c" })).toBe("c");
    expect(revisionIdOf("d")).toBe("d");
    expect(revisionIdOf({})).toBe("");
  });

  it("양쪽이 비어 있지 않고 다를 때만 낡다", () => {
    expect(isStaleRevision("a", "b")).toBe(true);
    expect(isStaleRevision("a", "a")).toBe(false);
    expect(isStaleRevision("", "b")).toBe(false);
    expect(isStaleRevision("a", "")).toBe(false);
  });

  it("BUILD_ID 파일을 읽는다", () => {
    const cwd = mkdtempSync(join(tmpdir(), "rev-"));
    mkdirSync(join(cwd, ".next"));
    writeFileSync(join(cwd, ".next", "BUILD_ID"), "ship-1\n");
    expect(deployedBuildId(cwd)).toBe("ship-1");
    expect(deployedBuildId(join(cwd, "missing"), "production")).toBe("");
    expect(deployedBuildId(join(cwd, "missing"), "development")).toBe("development");
  });
});
