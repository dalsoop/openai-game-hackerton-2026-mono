"use client";
// 루트 레이아웃(로케일 프로바이더 포함) 자체가 깨졌을 때의 최후 경계.
// 프로바이더를 신뢰할 수 없으므로 ko.json 을 직접 import 한다 — next-intl 와 무관.
import type { JSX } from "react";
import { useEffect } from "react";
import ko from "../messages/ko.json";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}): JSX.Element {
  useEffect(() => {
    console.error(error);
  }, [error]);

  const t = ko.error;

  // 최후의 경계 — 레이아웃이 죽어 globals.css 를 신뢰할 수 없으므로 인라인 스타일이 정당하다.
  return (
    <html lang="ko">
      <body style={{ display: "grid", placeItems: "center", minHeight: "100dvh" }}>
        <main style={{ textAlign: "center" }}>
          <h1>{t.title}</h1>
          <p>{t.unknown}</p>
          <button onClick={() => reset()}>{t.retry}</button>
        </main>
      </body>
    </html>
  );
}
