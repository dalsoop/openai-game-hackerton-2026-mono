export type RedisConn = string | {
  host: string;
  port: number;
  username?: string;
  password?: string;
  db: number;
  keyPrefix?: string;
};

/** 슬롯마다 키를 갈라 공용 Redis 에서 방 목록이 섞이지 않게 한다. */
export function redisConn(url: string, slot = process.env.SLOT_FOLDER ?? ""): RedisConn {
  const prefix = slot.trim();
  if (!prefix) {return url;}
  const parsed = new URL(url);
  const user = decodeURIComponent(parsed.username);
  const pass = decodeURIComponent(parsed.password);
  return {
    host: parsed.hostname,
    port: Number(parsed.port || 6379),
    ...(user ? { username: user } : {}),
    ...(pass ? { password: pass } : {}),
    db: Number(parsed.pathname.replace(/^\//, "") || 0),
    keyPrefix: `${prefix}:`,
  };
}
