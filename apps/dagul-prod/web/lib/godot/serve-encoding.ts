/** 원본보다 오래된 .br/.gz 는 쓰지 않는다. 패치한 index.js 위에 옛 압축본이 남으면
 * 브라우저가 Accept-Encoding: br 로 옛 glue 를 받아 패치 전 코드를 실행한다.
 * 파이프라인(발행·계약 검사) 쪽 정본은 encoding-freshness.mjs 의 같은 식이다. */
export function encodingIsCurrent(rawMtimeMs: number | null, encodedMtimeMs: number): boolean {
  if (rawMtimeMs === null) {return true;}
  return encodedMtimeMs >= rawMtimeMs;
}

/** 서빙: 원본이 없거나(고아 .br) 원본보다 오래되면 압축본을 건너뛴다. */
export function shouldServeEncoding(
  rawMtimeMs: number | null,
  encodedMtimeMs: number | null,
): boolean {
  if (encodedMtimeMs == null || rawMtimeMs == null) {return false;}
  return encodingIsCurrent(rawMtimeMs, encodedMtimeMs);
}

/** 무버전 Godot 파일은 엣지·브라우저에 남기지 않는다. ?v=해시만 불변 캐시다. */
export function godotCacheHeaders(versioned: boolean): Record<string, string> {
  if (versioned) {
    return { "cache-control": "public, max-age=31536000, immutable" };
  }
  return {
    "cache-control": "no-store",
    "cdn-cache-control": "no-store",
  };
}
