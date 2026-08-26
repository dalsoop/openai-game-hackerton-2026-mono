/**
 * 색상 상수
 * CSS 변수와 TypeScript 간 일관성 유지
 */

export const COLORS = {
  bg: {
    base: '#0b0e14',
    card: '#141820',
    input: '#1a1f2a',
    hover: '#252b38',
    base3: '#2d3446',
  },
  text: {
    primary: '#e8e6e1',
    secondary: '#7a8194',
    muted: '#555555',
  },
  accent: {
    primary: '#d4a843',
    blue: '#2f6bff',
    green: '#1f9d55',
    red: '#c0392b',
    cyan: '#70e7ff',
    dim: '#4a5568',
  },
} as const;

/**
 * CSS 변수 참조 헬퍼
 * 스타일 객체에서 var() 사용을 위한 상수
 */
export const CSS_VARS = {
  bg: {
    base: 'var(--bg-base)',
    card: 'var(--bg-card)',
    input: 'var(--bg-input)',
    hover: 'var(--bg-hover)',
    base3: 'var(--bg-3)',
  },
  text: {
    primary: 'var(--text-primary)',
    secondary: 'var(--text-secondary)',
    muted: 'var(--text-muted)',
  },
  accent: {
    primary: 'var(--accent-primary)',
    blue: 'var(--accent-blue)',
    green: 'var(--accent-green)',
    red: 'var(--accent-red)',
    cyan: 'var(--accent-cyan)',
    dim: 'var(--accent-dim)',
  },
} as const;

export type ColorKey = keyof typeof COLORS;
export type AccentColor = keyof typeof COLORS.accent;
