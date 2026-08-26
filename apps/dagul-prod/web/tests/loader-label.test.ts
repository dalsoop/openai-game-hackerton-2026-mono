import { describe, expect, it } from "vitest";
import { loaderLabelKey } from "@/lib/godot/loader-label";
import type { LoaderState } from "@/hooks/useGodotLoader";

describe("loaderLabelKey — 상태→i18n 키 전수", () => {
  const cases: Array<[LoaderState, string]> = [
    ["downloading", "game.loading.downloading"],
    ["compiling", "game.loading.compiling"],
    ["ready", "game.loading.ready"],
    ["idle", "game.loading.preparing"],
    ["running", "game.loading.preparing"],
    ["error", "game.loading.preparing"],
  ];
  it.each(cases)("%s → %s", (state, key) => {
    expect(loaderLabelKey(state)).toBe(key);
  });
});
