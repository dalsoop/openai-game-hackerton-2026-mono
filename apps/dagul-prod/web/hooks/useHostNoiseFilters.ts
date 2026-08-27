"use client";
import { useEffect } from "react";
import { installRuntimeNoiseFilter } from "@/lib/helpers/runtime-noise";
import { installWasmErrorMonitor } from "@/lib/godot/wasm-error-monitor";

if (typeof window !== "undefined") {
  installRuntimeNoiseFilter();
  installWasmErrorMonitor();
}

/** 모듈 로드 시점에 필터를 걸고, 언마운트해도 페이지 전역 필터는 유지한다. */
export function useHostNoiseFilters(): void {
  useEffect(() => {
    installRuntimeNoiseFilter();
    installWasmErrorMonitor();
  }, []);
}
