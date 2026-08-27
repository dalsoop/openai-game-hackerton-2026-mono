import { describe, expect, it } from "vitest";
import { congestionOf } from "@/lib/hub/ccu-plan";
import { ccuMetricsText } from "@/lib/hub/ccu-metrics";

describe("ccuMetricsText", () => {
  it("emits gauges for ccu, cap, and admit", () => {
    const text = ccuMetricsText(congestionOf(12, 100), "dagul-prod");
    expect(text).toContain('dagul_ccu{slot="dagul-prod"} 12');
    expect(text).toContain('dagul_ccu_cap{slot="dagul-prod"} 100');
    expect(text).toContain('dagul_ccu_admit{slot="dagul-prod"} 1');
  });

  it("sets admit 0 when the server is full", () => {
    const text = ccuMetricsText(congestionOf(100, 100), "dagul-prod");
    expect(text).toContain('dagul_ccu_admit{slot="dagul-prod"} 0');
  });

  it("escapes quotes in the slot label", () => {
    const text = ccuMetricsText(congestionOf(0, 100), 'ab"c');
    expect(text).toContain('dagul_ccu{slot="ab\\"c"} 0');
  });
});
