// 로더 상태 → i18n 키 매핑 — 순수 함수 (tests 대상).
import type { LoaderState } from "@/hooks/useGodotLoader";

/** 다운로드 키는 {pct} 치환을 쓴다. */
export function loaderLabelKey(state: LoaderState): string {
  if (state === "downloading") {return "game.loading.downloading";}
  if (state === "compiling") {return "game.loading.compiling";}
  if (state === "ready") {return "game.loading.ready";}
  return "game.loading.preparing"; // idle·running·error 폴백
}
