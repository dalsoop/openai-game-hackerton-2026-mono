/**
 * 애니메이션 상수
 * CSS keyframes와 대응하는 문자열 상수
 * 인라인 스타일 하드코딩 제거용
 */

export const ANIMATIONS = {
  /** 위로 페이드 인 */
  fadeUp: 'fadeUp 0.35s ease both',

  /** 슬롯 카드 스케일 인 */
  slotIn: 'slotIn 0.25s ease both',

  /** 연결 상태 점멸 */
  pulse: 'pulse 2s infinite',

  /** 결과 카드 등장 */
  riseIn: 'riseIn 0.3s ease both',

  /** 승리 아바타 플로팅 */
  float: 'float 3s ease-in-out infinite',

  /** 토스트 슬라이드 인 */
  toastIn: 'toastIn 0.2s ease both',

  /** 토스트 슬라이드 아웃 */
  toastOut: 'toastOut 0.2s ease both',

  /** 커튼 전환 효과 */
  curtainAnim: 'curtainAnim 0.4s ease both',
} as const;

/**
 * 접근성 고려 트랜지션 상수
 */
export const TRANSITIONS = {
  fast: '0.12s ease',
  normal: '0.15s ease',
  slow: '0.2s ease',
} as const;

export type AnimationKey = keyof typeof ANIMATIONS;
export type TransitionKey = keyof typeof TRANSITIONS;
