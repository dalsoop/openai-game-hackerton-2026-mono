/** HPA 상한. 평소 복제는 1 대이고, 이 값까지만 올린다. */
export function hubReplicaCount(targetCcu: number, perProcess: number): number {
  const cap = Math.max(1, Math.floor(perProcess));
  const want = Math.max(0, Math.floor(targetCcu));
  return Math.max(1, Math.ceil(want / cap));
}

/** 입장 한도 기본값. 공식은 matchMaker.stats CCU 와 이 값을 비교한다. */
export const DEFAULT_ADMISSION_CCU = 100;

export type CongestionLevel = "quiet" | "busy" | "very_busy" | "full";

export type CcuSnapshot = {
  ccu: number;
  cap: number;
  level: CongestionLevel;
  admit: boolean;
};

export function parseAdmissionCcu(raw: string | undefined): number {
  const n = Number(raw ?? DEFAULT_ADMISSION_CCU);
  if (!Number.isFinite(n) || n < 1) {return DEFAULT_ADMISSION_CCU;}
  return Math.floor(n);
}

/** 런타임 조회 — 테스트가 env 를 바꿔도 반영되게 매 호출마다 읽는다. */
export function admissionCcu(raw = process.env.DAGUL_CCU_CAP): number {
  return parseAdmissionCcu(raw);
}

/**
 * 한도 대비 혼잡. 원활 <50%, 혼잡 <75%, 매우혼잡 <100%, 꽉참 = 한도 이상.
 * admit 은 새 소켓을 받을지. 한도에 닿으면 false.
 */
export function congestionOf(ccu: number, cap = DEFAULT_ADMISSION_CCU): CcuSnapshot {
  const n = Math.max(0, Math.floor(Number.isFinite(ccu) ? ccu : 0));
  const c = Math.max(1, Math.floor(Number.isFinite(cap) && cap >= 1 ? cap : DEFAULT_ADMISSION_CCU));
  const ratio = n / c;
  let level: CongestionLevel = "quiet";
  if (n >= c) {level = "full";}
  else if (ratio >= 0.75) {level = "very_busy";}
  else if (ratio >= 0.50) {level = "busy";}
  return { ccu: n, cap: c, level, admit: n < c };
}
