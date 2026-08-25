/** Colyseus 공식 Redis 연결 — URL 문자열만 넘긴다.
 * ioredis keyPrefix 는 pub/sub·예약 키를 갈라 조인이 4002 로 죽는다.
 * 슬롯 격리는 룸 이름과 processId 가 담당한다 (docs.colyseus.io/scalability).
 */
export function redisConn(url: string, _slot = process.env.SLOT_FOLDER ?? ""): string {
  return url;
}
