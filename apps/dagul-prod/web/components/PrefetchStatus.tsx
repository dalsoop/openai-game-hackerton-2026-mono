"use client";
// 에셋 프리로드 상태 표시 — 로딩 중엔 진행 바 스트립, 완료엔 컴팩트 배지.
// 문구 키 매핑은 순수 함수(loaderLabelKey), 여기선 표현만.
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { loaderLabelKey } from "@/lib/godot/loader-label";
import type { LoaderState } from "@/hooks/useGodotLoader";

interface PrefetchStatusProps {
  state: LoaderState;
  pct: number;
}

export function PrefetchStatus({ state, pct }: PrefetchStatusProps): JSX.Element {
  const t = useTranslations();

  if (state === "ready") {
    return (
      <div className="ready-badge">
        <span className="ready-dot" />
        {t("game.loading.ready")}
      </div>
    );
  }
  return (
    <div className="prefetch-strip">
      <span className="prefetch-txt">{t(loaderLabelKey(state), { pct })}</span>
      <div className="bar-track">
        {/* 진행률은 동적 값 — width만 인라인 불가피 */}
        <div
          className="bar-fill"
          // eslint-disable-next-line react/forbid-dom-props -- 진행률 동적 값
          style={{ width: `${pct}%` }}
        />
      </div>
    </div>
  );
}
