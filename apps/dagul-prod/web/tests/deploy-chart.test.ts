/**
 * 회귀: LobbyRoom.onBeforeShutdown 이 진행 중 매치를 HUB_CONFIG.shutdownDrainMs
 * 만큼 봐주게 고쳤는데, k8s StatefulSet 의 terminationGracePeriodSeconds 가
 * 그보다 짧으면(기본 30s) kubelet 이 먼저 SIGKILL 해서 이 드레인이 무의미해진다.
 * helm template 로 실제 렌더링해서 두 값이 서로 안 어긋나는지 직접 확인한다.
 */
import { spawnSync } from "child_process";
import { join } from "path";
import { describe, expect, it } from "vitest";
import { HUB_CONFIG } from "@/lib/hub/config";

const CHART = join(process.cwd(), "..", "..", "..", "deploy/chart");
const TEST_VALUES = "hubs: [{folder: dagul-prod, id: dagul-prod}]\nredis: {enabled: false}\n";

function helmTemplate(): string | null {
  const result = spawnSync("helm", ["template", "test", CHART, "-f", "-"], {
    input: TEST_VALUES, encoding: "utf8",
  });
  if (result.error || result.status !== 0) {return null;}
  return result.stdout;
}

describe("계약: 배포 차트 graceful shutdown 예산", () => {
  const rendered = helmTemplate();

  it.skipIf(rendered === null)("hub StatefulSet 의 terminationGracePeriodSeconds 가 있다", () => {
    const m = rendered?.match(/terminationGracePeriodSeconds:\s*(\d+)/);
    expect(m, "hub.yaml 에 terminationGracePeriodSeconds 없음").not.toBeNull();
  });

  it.skipIf(rendered === null)(
    "terminationGracePeriodSeconds 가 HUB_CONFIG.shutdownDrainMs 보다 짧지 않다",
    () => {
      const m = rendered?.match(/terminationGracePeriodSeconds:\s*(\d+)/);
      const graceSeconds = Number(m?.[1]);
      const drainSeconds = HUB_CONFIG.shutdownDrainMs / 1000;
      expect(
        graceSeconds,
        `k8s grace(${graceSeconds}s) < 앱 드레인(${drainSeconds}s) — kubelet 이 먼저 SIGKILL 한다`,
      ).toBeGreaterThanOrEqual(drainSeconds);
    },
  );
});
