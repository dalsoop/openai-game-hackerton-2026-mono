/**
 * 크기 및 간격 상수
 * 레이아웃 관련 매직 넘버 제거용
 */

export const SPACING = {
  xs: '0.25rem',
  sm: '0.5rem',
  md: '1rem',
  lg: '1.5rem',
  xl: '2rem',
  '2xl': '3rem',
} as const;

export const BORDER_RADIUS = {
  sm: 8,
  md: 10,
  lg: 14,
} as const;

export const MAX_WIDTH = {
  container: 960,
  narrow: 420,
  input: 420,
} as const;

export const HEADER_HEIGHT = 60;

export const FONT_SIZES = {
  xs: 11,
  sm: 12,
  md: 13,
  base: 16,
  lg: 17,
  xl: 20,
  '2xl': 24,
} as const;

/**
 * z-index 계층 구조
 */
export const Z_INDEX = {
  base: 1,
  dropdown: 10,
  sticky: 20,
  modal: 100,
  toast: 200,
} as const;

export type SpacingKey = keyof typeof SPACING;
export type RadiusKey = keyof typeof BORDER_RADIUS;
export type FontSizeKey = keyof typeof FONT_SIZES;
