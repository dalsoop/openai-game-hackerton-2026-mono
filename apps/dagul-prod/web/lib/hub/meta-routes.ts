/** Hub HTTP that must not go through next-intl [locale]. /ccu and /metrics were eaten as locale=ccu|metrics. */
export const HUB_META_SEGMENTS = [
  "api",
  "health",
  "healthz",
  "ccu",
  "metrics",
  "rooms",
  "matchmake",
] as const;

export type HubMetaSegment = (typeof HUB_META_SEGMENTS)[number];
