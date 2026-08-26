/** Colyseus 공식 Redis 연결 — URL 문자열만 넘긴다.
 * ioredis keyPrefix 는 pub/sub·예약 키를 갈라 조인이 4002 로 죽는다.
 * 슬롯 격리는 REDIS_URL 의 logical DB (/N) 와 slotRoomName 이 담당한다.
 */
export function redisConn(url: string, _slot = process.env.SLOT_FOLDER ?? ""): string {
  return url;
}
