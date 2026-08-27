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

  it("로컬 기동은 DAGUL_SKILLS 기본 on 이다", () => {
    const pkg = JSON.parse(readFileSync(join(ROOT, "package.json"), "utf8")) as {
      scripts: Record<string, string>;
    };
    expect(pkg.scripts.dev).toContain("DAGUL_SKILLS=${DAGUL_SKILLS:-on}");
    const script = readFileSync(join(ROOT, "scripts/restart-dev.sh"), "utf8");
    expect(script).toContain('DAGUL_SKILLS="${DAGUL_SKILLS:-on}"');
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

  it("server.ts 에 /ccu 라우트가 있다", () => {
    const src = readFileSync(join(ROOT, "server.ts"), "utf8");
    expect(src).toContain('pathname === "/ccu"');
    expect(src).toContain("/api/ccu");
    expect(src).toContain("ccuHttpBody");
    expect(src).toContain("getGlobalCCU");
  });

  it("로케일 미들웨어는 /ccu 를 페이지로 안 보낸다", () => {
    const src = readFileSync(join(ROOT, "middleware.ts"), "utf8");
    expect(src).toContain("ccu");
  });

  // 회귀: lsof -ti 만으로는 CLOSED 소켓 잔재(예: VS Code 헬퍼가 예전에 이 포트에
  // 붙었던 흔적)까지 잡혀, 죽여야 할 노드 서버 대신 남의 프로세스를 골라버린다.
  it("포트 조회는 전부 LISTEN 상태로만 필터링한다", () => {
    const script = readFileSync(join(ROOT, "scripts/restart-dev.sh"), "utf8");
    const lsofCalls = [...script.matchAll(/lsof -ti :"\$PORT"[^\n]*/g)].map((m) => m[0]);
    expect(lsofCalls.length).toBeGreaterThan(0);
    for (const call of lsofCalls) {
      expect(call, `LISTEN 필터 없는 lsof 호출: ${call}`).toContain("-sTCP:LISTEN");
    }
  });

  // 회귀: 재시작이 바로 kill -9(SIGKILL)를 쏘면 Colyseus Server 의 기본
  // gracefullyShutdown(SIGTERM 에서 matchMaker.gracefullyShutdown 호출 → Redis
  // 방 등록 해제)을 건너뛴다. 그러면 재배포마다 Redis 에 낡은 방 등록이 쌓여서
  // 다음 프로세스가 새 스키마로 그 방을 잘못 이어받는 사고로 이어진다.
  // kill_old() 는 반드시 SIGTERM 을 먼저 보내고, 끝날 시간을 기다린 뒤에만
  // SIGKILL 로 넘어가야 한다.
  it("kill_old 는 SIGKILL 전에 SIGTERM 으로 graceful shutdown 시간을 준다", () => {
    const script = readFileSync(join(ROOT, "scripts/restart-dev.sh"), "utf8");
    const fnStart = script.indexOf("kill_old()");
    expect(fnStart, "kill_old 함수가 없다").toBeGreaterThanOrEqual(0);
    const fnEnd = script.indexOf("\n}", fnStart);
    const body = script.slice(fnStart, fnEnd);

    const termIdx = body.search(/kill\s+-TERM\b/);
    const killNineIdx = body.indexOf("kill -9");
    expect(termIdx, "kill_old 안에 SIGTERM 이 없다").toBeGreaterThanOrEqual(0);
    expect(killNineIdx, "kill_old 안에 SIGKILL 폴백이 없다").toBeGreaterThanOrEqual(0);
    expect(termIdx, "SIGTERM 이 SIGKILL 보다 먼저 나와야 한다").toBeLessThan(killNineIdx);

    // SIGTERM 과 SIGKILL 사이에 실제로 기다리는 루프(while/sleep)가 있어야
    // graceful shutdown 이 끝날 시간을 준다 — 즉시 이어지는 SIGKILL 은 무의미하다.
    const between = body.slice(termIdx, killNineIdx);
    expect(between, "SIGTERM 뒤에 대기 없이 바로 SIGKILL 한다").toMatch(/while|sleep/);
  });

  it("server.ts 는 Colyseus 기본 gracefullyShutdown 을 끄지 않는다", () => {
    const src = readFileSync(join(ROOT, "server.ts"), "utf8");
    expect(src).not.toMatch(/gracefullyShutdown\s*:\s*false/);
  });
});
