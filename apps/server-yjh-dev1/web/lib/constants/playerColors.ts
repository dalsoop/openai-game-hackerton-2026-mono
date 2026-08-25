/**
 * 플레이어 색상 상수
 * 8개 플레이어 슬롯용 색상 배열
 * Room.tsx와 Lobby.tsx 중복 제거용
 */

export const PLAYER_COLORS = [
  '#5bc0eb', // P1 - Blue
  '#9bc53d', // P2 - Green
  '#e55934', // P3 - Red
  '#fa7921', // P4 - Orange
  '#b084cc', // P5 - Purple
  '#70e7ff', // P6 - Cyan
  '#ffd166', // P7 - Yellow
  '#ff8dac', // P8 - Pink
] as const;

/**
 * CSS 변수 참조 (인라인 스타일용)
 */
export const PLAYER_CSS_VARS = [
  'var(--player-1)',
  'var(--player-2)',
  'var(--player-3)',
  'var(--player-4)',
  'var(--player-5)',
  'var(--player-6)',
  'var(--player-7)',
  'var(--player-8)',
] as const;

/**
 * 슬롯 번호로 플레이어 색상 가져오기
 * @param slot - 0-based 슬롯 인덱스
 * @returns 플레이어 색상 (hex)
 */
export function getPlayerColor(slot: number): string {
  return PLAYER_COLORS[slot % PLAYER_COLORS.length];
}

/**
 * 슬롯 번호로 CSS 변수 가져오기
 * @param slot - 0-based 슬롯 인덱스
 * @returns CSS 변수 문자열
 */
export function getPlayerColorVar(slot: number): string {
  return PLAYER_CSS_VARS[slot % PLAYER_CSS_VARS.length];
}

export type PlayerSlot = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7;
export type PlayerColor = typeof PLAYER_COLORS[number];
