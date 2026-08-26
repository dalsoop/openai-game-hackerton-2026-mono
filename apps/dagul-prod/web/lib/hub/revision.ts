/** Next 빌드 신원 — 열린 탭이 낡은 셸인지 비교할 때 쓰는 계약. /health 와 섞지 않는다. */
export const VERSION_PATH = "/api/version";

export function revisionBody(id: string): string {
  return JSON.stringify({ id });
}

export function revisionIdOf(body: unknown): string {
  if (typeof body === "string" && body !== "") {return body;}
  if (body === null || typeof body !== "object") {return "";}
  const rec = body as Record<string, unknown>;
  for (const key of ["id", "buildId", "version"] as const) {
    const value = rec[key];
    if (typeof value === "string" && value !== "") {return value;}
  }
  return "";
}

export function isStaleRevision(current: string, remote: string): boolean {
  return current !== "" && remote !== "" && current !== remote;
}

/** 첫 응답으로 핀을 박고, 이후 값이 바뀌면 stale. 빈 remote 는 무시. */
export function pinOrDetectStale(
  pinned: string,
  remote: string,
): { pin: string; stale: boolean } {
  if (remote === "") {return { pin: pinned, stale: false };}
  if (pinned === "") {return { pin: remote, stale: false };}
  return { pin: pinned, stale: isStaleRevision(pinned, remote) };
}
