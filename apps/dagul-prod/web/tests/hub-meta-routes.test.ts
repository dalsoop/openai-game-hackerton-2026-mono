import { readFileSync } from "fs";
import { join } from "path";
import { describe, expect, it } from "vitest";
import { HUB_META_SEGMENTS } from "@/lib/hub/meta-routes";
import { ccuMetricsText } from "@/lib/hub/ccu-metrics";
import { congestionOf } from "@/lib/hub/ccu-plan";

const ROOT = process.cwd();

function matcherSkipTokens(src: string): string[] {
  const m = src.match(/\/\(\(\?!([^)]+)\)/);
  if (!m) {throw new Error("middleware matcher negative lookahead 없음");}
  return m[1].split("|").map((t) => t.replace(/\\/g, ""));
}

describe("허브 메타 경로는 locale 페이지가 아니다", () => {
  it("next-intl matcher 가 HUB_META_SEGMENTS 전부를 건너뛴다", () => {
    const src = readFileSync(join(ROOT, "middleware.ts"), "utf8");
    const skip = matcherSkipTokens(src);
    for (const seg of HUB_META_SEGMENTS) {
      expect(skip, `/ ${seg} 가 locale 로 먹으면 구버전 HTML 이 나온다`).toContain(seg);
    }
  });

  it("server.ts serveMeta 가 /metrics 를 Next 보다 먼저 받는다", () => {
    const src = readFileSync(join(ROOT, "server.ts"), "utf8");
    const meta = src.split("function serveMeta", 2)[1]?.split("function serveRoomsList", 1)[0] ?? "";
    expect(meta.indexOf('pathname === "/metrics"')).toBeGreaterThanOrEqual(0);
    expect(meta.indexOf("ccuMetricsText")).toBeGreaterThanOrEqual(0);
    expect(src.indexOf("function serveMeta")).toBeLessThan(src.indexOf("void handle(req, res)"));
  });

  it("프로메테우스 본문은 HTML 이 아니다", () => {
    const body = ccuMetricsText(congestionOf(0, 100), "dagul-prod");
    expect(body).toContain('dagul_ccu{slot="dagul-prod"}');
    expect(body.toLowerCase()).not.toContain("<html");
    expect(body).not.toContain("__next");
  });
});
