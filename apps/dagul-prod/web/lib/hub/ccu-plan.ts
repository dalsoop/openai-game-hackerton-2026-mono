/** HPA 상한. 평소 복제는 1 대이고, 이 값까지만 올린다. */
export function hubReplicaCount(targetCcu: number, perProcess: number): number {
  const cap = Math.max(1, Math.floor(perProcess));
  const want = Math.max(0, Math.floor(targetCcu));
  return Math.max(1, Math.ceil(want / cap));
}
