import { HUB_CONFIG } from "./config";

export function idleLeftMs(
  createdAtMs: number,
  nowMs: number,
  budgetMs = HUB_CONFIG.idleStartMs,
): number {
  if (createdAtMs <= 0) {return 0;}
  return Math.max(0, createdAtMs + budgetMs - nowMs);
}

export function idleLeftSec(createdAtMs: number, nowMs: number, budgetMs = HUB_CONFIG.idleStartMs): number {
  return Math.ceil(idleLeftMs(createdAtMs, nowMs, budgetMs) / 1000);
}

export function shouldBurstIdle(createdAtMs: number, nowMs: number, budgetMs = HUB_CONFIG.idleStartMs): boolean {
  return createdAtMs > 0 && idleLeftMs(createdAtMs, nowMs, budgetMs) <= 0;
}
