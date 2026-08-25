/** 프로세스당 안전 CCU 로 복제 수를 정한다. */
export function hubReplicaCount(targetCcu: number, perProcess: number): number {
  const cap = Math.max(1, Math.floor(perProcess));
  const want = Math.max(0, Math.floor(targetCcu));
  return Math.max(1, Math.ceil(want / cap));
}
