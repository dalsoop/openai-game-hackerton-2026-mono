/**
 * Redis HyperLogLog 기반 DAU + SET 기반 D1/D7 리텐션.
 * REDIS_URL 이 없으면 인메모리 폴백(ops-metrics 기존 동작).
 *
 * 키 구조:
 *   dagul:dau:2026-08-30        — HyperLogLog (PFADD/PFCOUNT), TTL 30일
 *   dagul:first-seen:<playerId> — 첫 접속 날짜 문자열, TTL 30일
 */
import Redis from "ioredis";

const KEY_PREFIX = "dagul:";
const DAU_TTL = 30 * 86400;

let redis: Redis | null = null;
let connectAttempted = false;

function getRedis(): Redis | null {
  if (redis) { return redis; }
  if (connectAttempted) { return null; }
  connectAttempted = true;
  const url = process.env.REDIS_URL;
  if (!url) { return null; }
  try {
    redis = new Redis(url, {
      maxRetriesPerRequest: 1,
      lazyConnect: true,
      enableOfflineQueue: false,
    });
    redis.on("error", () => {});
    void redis.connect().catch(() => { redis = null; });
    return redis;
  } catch {
    return null;
  }
}

function todayKey(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function dateNDaysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

export async function recordPlayerRedis(playerId: string): Promise<void> {
  const r = getRedis();
  if (!r) { return; }
  const today = todayKey();
  const dauKey = `${KEY_PREFIX}dau:${today}`;
  const firstSeenKey = `${KEY_PREFIX}first-seen:${playerId}`;
  try {
    const pipe = r.pipeline();
    pipe.pfadd(dauKey, playerId);
    pipe.expire(dauKey, DAU_TTL);
    pipe.setnx(firstSeenKey, today);
    pipe.expire(firstSeenKey, DAU_TTL);
    await pipe.exec();
  } catch { /* 실패해도 게임 진행에 영향 없음 */ }
}

export async function getDau(): Promise<number | null> {
  const r = getRedis();
  if (!r) { return null; }
  try {
    return await r.pfcount(`${KEY_PREFIX}dau:${todayKey()}`);
  } catch {
    return null;
  }
}

export async function getRetention(): Promise<{ d1: number | null; d7: number | null }> {
  const r = getRedis();
  if (!r) { return { d1: null, d7: null }; }
  try {
    const d1Key = `${KEY_PREFIX}dau:${dateNDaysAgo(1)}`;
    const d7Key = `${KEY_PREFIX}dau:${dateNDaysAgo(7)}`;
    const todayDauKey = `${KEY_PREFIX}dau:${todayKey()}`;

    const [yesterdayCount, weekAgoCount, todayCount] = await Promise.all([
      r.pfcount(d1Key),
      r.pfcount(d7Key),
      r.pfcount(todayDauKey),
    ]);

    return {
      d1: yesterdayCount > 0 ? todayCount / yesterdayCount : null,
      d7: weekAgoCount > 0 ? todayCount / weekAgoCount : null,
    };
  } catch {
    return { d1: null, d7: null };
  }
}

// ── 캐시: /metrics 에서 매번 Redis 질의하면 느리므로 30초 캐시 ──

let cachedDau = 0;
let cachedD1: number | null = null;
let cachedD7: number | null = null;
let cacheUpdatedAt = 0;
const CACHE_TTL_MS = 30_000;

export async function refreshDauCache(): Promise<void> {
  const now = Date.now();
  if (now - cacheUpdatedAt < CACHE_TTL_MS) { return; }
  cacheUpdatedAt = now;
  const dau = await getDau();
  if (dau !== null) { cachedDau = dau; }
  const ret = await getRetention();
  cachedD1 = ret.d1;
  cachedD7 = ret.d7;
}

export function getCachedDau(): number { return cachedDau; }
export function getCachedD1(): number | null { return cachedD1; }
export function getCachedD7(): number | null { return cachedD7; }
