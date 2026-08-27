// restart-dev.sh 파이프라인 계약 테스트.
// 스크립트 자체를 실행하지 않고 (CI에서 포트를 잡으면 안 되므로)
// 구성 요소인 revision 모듈과 서버 health/version 계약을 검증한다.
import { describe, expect, it } from "vitest";
import { existsSync, readFileSync } from "fs";
import { join } from "path";
import { revisionBody, revisionIdOf, isStaleRevision, pinOrDetectStale } from "@/lib/hub/revision";

const ROOT = process.cwd();

describe("계약: restart-dev 파이프라인", () => {
  it("restart-dev.sh 가 실행 가능 상태로 존재한다", () => {
    const script = join(ROOT, "scripts/restart-dev.sh");
    expect(existsSync(script), "scripts/restart-dev.sh 가 없다").toBe(true);
  });

  it("package.json 에 restart 스크립트가 등록되어 있다", () => {
    const pkg = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8")) as {
      scripts: Record<string, string>;
    };
    expect(pkg.scripts.restart).toContain("restart-dev.sh");
  });

  it("revisionBody 는 JSON id 를 반환한다", () => {
    const body = revisionBody("abc123");
    expect(JSON.parse(body)).toEqual({ id: "abc123" });
  });

  it("revisionIdOf 는 id/buildId/version 키를 인식한다", () => {
    expect(revisionIdOf({ id: "a" })).toBe("a");
    expect(revisionIdOf({ buildId: "b" })).toBe("b");
    expect(revisionIdOf({ version: "c" })).toBe("c");
    expect(revisionIdOf(null)).toBe("");
    expect(revisionIdOf("raw")).toBe("raw");
  });

  it("isStaleRevision 은 값이 달라야만 stale 이다", () => {
    expect(isStaleRevision("a", "a")).toBe(false);
    expect(isStaleRevision("a", "b")).toBe(true);
    expect(isStaleRevision("", "b")).toBe(false);
    expect(isStaleRevision("a", "")).toBe(false);
  });

  it("pinOrDetectStale 는 첫 응답으로 핀을 박고 이후 바뀌면 stale 이다", () => {
    const r1 = pinOrDetectStale("", "v1");
    expect(r1).toEqual({ pin: "v1", stale: false });
    const r2 = pinOrDetectStale(r1.pin, "v1");
    expect(r2).toEqual({ pin: "v1", stale: false });
    const r3 = pinOrDetectStale(r1.pin, "v2");
    expect(r3).toEqual({ pin: "v1", stale: true });
    const r4 = pinOrDetectStale("v1", "");
    expect(r4).toEqual({ pin: "v1", stale: false });
  });

  it("server.ts 에 /api/version 라우트가 있다", () => {
    const src = readFileSync(join(ROOT, "server.ts"), "utf8");
    expect(src).toContain("/api/version");
    expect(src).toContain("revisionBody");
  });

  it("server.ts 에 /health 라우트가 있다", () => {
    const src = readFileSync(join(ROOT, "server.ts"), "utf8");
    expect(src).toContain("/health");
    expect(src).toContain("healthBody");
  });
});
