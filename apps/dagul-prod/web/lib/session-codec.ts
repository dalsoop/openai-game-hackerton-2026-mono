// 닉네임 정규화 순수 로직 — useSession 과 테스트가 같이 쓴다.
// localStorage 반영 여부는 훅이, "무엇이 유효한 닉네임인가"는 여기서 판정한다.

/** 표시용 닉네임 — 앞뒤 공백 제거. */
export function normalizeNickname(raw: string): string {
  return raw.trim();
}

/** 저장 가능한 닉네임 — 공백만 있으면 null (저장 금지). */
export function persistableNickname(raw: string): string | null {
  const trimmed = normalizeNickname(raw);
  return trimmed === "" ? null : trimmed;
}
