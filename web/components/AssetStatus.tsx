"use client";

import type { LoaderState } from "@/hooks/useGodotLoader";
import LoadingBar from "./LoadingBar";

interface Props {
  state: LoaderState;
  progress: number;
  bytesLoaded: number;
  bytesTotal: number;
  error: string | null;
}

const STATUS_TEXT: Record<LoaderState, string> = {
  idle: "",
  downloading: "게임 에셋 다운로드 중...",
  compiling: "게임 에셋 준비 중...",
  ready: "✓ 게임 준비 완료",
  running: "게임 실행 중",
  error: "다운로드 실패",
};

export default function AssetStatus({ state, progress, bytesLoaded, bytesTotal, error }: Props) {
  if (state === "idle") return null;

  if (state === "ready") {
    return (
      <div style={{ padding: "0.5rem 0", color: "#1f9d55", fontSize: "0.85rem", fontWeight: 600 }}>
        ✓ 게임 준비 완료 — 바로 시작할 수 있습니다
      </div>
    );
  }

  if (state === "error") {
    return (
      <div style={{ padding: "0.5rem 0", color: "#c0392b", fontSize: "0.85rem" }}>
        ✗ 다운로드 실패: {error || "알 수 없는 오류"}
      </div>
    );
  }

  if (state === "downloading" || state === "compiling") {
    return (
      <LoadingBar
        progress={progress}
        bytesLoaded={bytesLoaded}
        bytesTotal={bytesTotal}
        label={STATUS_TEXT[state]}
      />
    );
  }

  return null;
}
