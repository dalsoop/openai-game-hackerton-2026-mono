import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";
import { afterEach, describe, expect, it } from "vitest";
import { isStaleRevision, pinOrDetectStale } from "@/lib/hub/revision";
import { godotFilesHash, liveRevisionId } from "@/lib/hub/revision-fs";
import { revisionWatchMs } from "@/hooks/useDeployRevision";

const temps: string[] = [];
afterEach(() => {
  for (const dir of temps) {rmSync(dir, { recursive: true, force: true });}
  temps.length = 0;
});

function packDir(filesHash: string): string {
  const root = mkdtempSync(join(tmpdir(), "rev-"));
  temps.push(root);
  mkdirSync(join(root, "public", "godot", "dagul"), { recursive: true });
  writeFileSync(
    join(root, "public", "godot", "dagul", "manifest.json"),
    JSON.stringify({ version: "1", filesHash, files: [] }),
  );
  return root;
}

describe("pinOrDetectStale", () => {
  it("첫 remote 를 핀으로 박고 stale 이 아니다", () => {
    expect(pinOrDetectStale("", "development:aaa")).toEqual({ pin: "development:aaa", stale: false });
  });

  it("같은 핀은 stale 이 아니다", () => {
    expect(pinOrDetectStale("development:aaa", "development:aaa")).toEqual({
      pin: "development:aaa", stale: false,
    });
  });

  it("팩 해시가 바뀌면 stale", () => {
    expect(pinOrDetectStale("development:aaa", "development:bbb")).toEqual({
      pin: "development:aaa", stale: true,
    });
  });

  it("빈 remote 는 무시", () => {
    expect(pinOrDetectStale("development:aaa", "")).toEqual({ pin: "development:aaa", stale: false });
  });
});

describe("isStaleRevision", () => {
  it("한쪽이 비면 비교하지 않는다", () => {
    expect(isStaleRevision("", "a")).toBe(false);
    expect(isStaleRevision("a", "")).toBe(false);
  });
});

describe("liveRevisionId", () => {
  it("Next 신원과 Godot filesHash 를 붙인다", () => {
    const cwd = packDir("deadbeef");
    expect(godotFilesHash(cwd)).toBe("deadbeef");
    expect(liveRevisionId(cwd, "development")).toBe("development:deadbeef");
  });
});

describe("revisionWatchMs", () => {
  it("로컬은 짧게 보고 배포는 길게 본다", () => {
    expect(revisionWatchMs("development").interval).toBe(5_000);
    expect(revisionWatchMs("production").minGap).toBe(60_000);
  });
});
