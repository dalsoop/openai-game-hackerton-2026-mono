import type { CcuSnapshot } from "./ccu-plan.js";

function labelSlot(slot: string): string {
  return slot.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"");
}

/** Prometheus text for this process. Health stays JSON; scrape this on the cluster. */
export function ccuMetricsText(snap: CcuSnapshot, slot = process.env.SLOT_FOLDER ?? ""): string {
  const s = labelSlot(slot || "unknown");
  return [
    "# HELP dagul_ccu Connected clients on this hub process.",
    "# TYPE dagul_ccu gauge",
    `dagul_ccu{slot="${s}"} ${snap.ccu}`,
    "# HELP dagul_ccu_cap Server admission cap.",
    "# TYPE dagul_ccu_cap gauge",
    `dagul_ccu_cap{slot="${s}"} ${snap.cap}`,
    "# HELP dagul_ccu_admit 1 if the hub admits new players.",
    "# TYPE dagul_ccu_admit gauge",
    `dagul_ccu_admit{slot="${s}"} ${snap.admit ? 1 : 0}`,
    "",
  ].join("\n");
}
