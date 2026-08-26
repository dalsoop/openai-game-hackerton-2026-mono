"use client";
// 라우트 세그먼트 에러 경계 — Next 기본 "client-side exception" 폴백을 대체한다.
// 렌더 크래시를 여기서 잡아, 연결 계열 오류는 서버 상태로 안내한다.
import type { JSX } from "react";
import { useEffect } from "react";
import { useTranslations } from "next-intl";

// 연결 실패 계열 시그니처 — 서버 미기동·WS 거부·일시적 네트워크 단절.
const NET_ERROR_RE =
  /websocket|network|fetch|connect|econnrefused|503|abnormal closure/i;

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}): JSX.Element {
  const t = useTranslations("error");

  useEffect(() => {
    console.error(error);
  }, [error]);

  const isConnectionError =
    typeof navigator !== "undefined" &&
    (!navigator.onLine || NET_ERROR_RE.test(error.message));

  return (
    <main className="err-main">
      <div className="err-box">
        <h1>{t("title")}</h1>
        <p>{isConnectionError ? t("connection") : t("unknown")}</p>
        <button className="cta" onClick={() => reset()}>
          {t("retry")}
        </button>
      </div>
    </main>
  );
}
