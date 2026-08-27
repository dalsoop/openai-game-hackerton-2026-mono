// 로비 방 목록 검색 — 제목·방 id 부분 일치. 빈 질의는 전부 통과.
export function roomMatchesQuery(
  room: { id: string; title: string },
  query: string,
): boolean {
  const q = query.trim().toLowerCase();
  if (!q) {return true;}
  return room.title.toLowerCase().includes(q) || room.id.toLowerCase().includes(q);
}

export function filterRoomsByQuery<T extends { id: string; title: string }>(
  rooms: readonly T[],
  query: string,
): T[] {
  return rooms.filter((room) => roomMatchesQuery(room, query));
}
