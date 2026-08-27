import { describe, expect, it } from "vitest";
import { encodingIsCurrent, godotCacheHeaders, shouldServeEncoding } from "@/lib/godot/serve-encoding";

describe("encodingIsCurrent", () => {
  it("원본이 없으면 압축본을 쓴다", () => {
    expect(encodingIsCurrent(null, 100)).toBe(true);
  });

  it("압축본이 원본보다 오래되면 버린다", () => {
    expect(encodingIsCurrent(200, 100)).toBe(false);
    expect(encodingIsCurrent(100, 100)).toBe(true);
    expect(encodingIsCurrent(100, 150)).toBe(true);
  });
});

describe("shouldServeEncoding", () => {
  it("원본이 없는 고아 압축본은 서빙하지 않는다", () => {
    expect(shouldServeEncoding(null, 100)).toBe(false);
    expect(shouldServeEncoding(100, null)).toBe(false);
  });

  it("원본보다 새거나 같은 압축본만 서빙한다", () => {
    expect(shouldServeEncoding(200, 100)).toBe(false);
    expect(shouldServeEncoding(100, 100)).toBe(true);
    expect(shouldServeEncoding(100, 150)).toBe(true);
  });
});

describe("godotCacheHeaders", () => {
  it("무버전은 엣지와 브라우저에 남기지 않는다", () => {
    expect(godotCacheHeaders(false)).toEqual({
      "cache-control": "no-store",
      "cdn-cache-control": "no-store",
    });
  });

  it("해시 버전만 불변 캐시다", () => {
    expect(godotCacheHeaders(true)).toEqual({
      "cache-control": "public, max-age=31536000, immutable",
    });
  });
});
