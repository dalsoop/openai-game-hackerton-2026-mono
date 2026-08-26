// 대기실 유휴 시한 — unix 초(uint32)만 쓴다.
// Date.now() ms 를 schema number(float32) 에 넣으면 자리수가 뭉개진다.

import { HUB_CONFIG } from "./config";

export function nowUnixSec(nowMs = Date.now()): number {
  return Math.floor(nowMs / 1000);
}

export function idleBudgetSec(budgetMs = HUB_CONFIG.idleStartMs): number {
  return Math.floor(budgetMs / 1000);
}

/** 서버가 state.idleUntilSec 에 심는 마감(unix 초). */
export function idleUntilSecOf(nowSec: number, budgetMs = HUB_CONFIG.idleStartMs): number {
  return nowSec + idleBudgetSec(budgetMs);
}

export function idleLeftFromUntil(untilSec: number, nowSec: number): number {
  if (untilSec <= 0) {return 0;}
  return Math.max(0, untilSec - nowSec);
}

export function shouldBurstIdle(untilSec: number, nowSec: number): boolean {
  return untilSec > 0 && idleLeftFromUntil(untilSec, nowSec) <= 0;
}
