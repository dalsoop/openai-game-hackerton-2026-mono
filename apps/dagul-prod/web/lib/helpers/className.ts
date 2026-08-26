/**
 * 클래스명 유틸리티
 * clsx/classnames 라이브러리 대체용
 */

/**
 * 조건부 클래스명 조립
 * @param classes - 클래스명 배열 (string, boolean, undefined, null)
 * @returns 조립된 클래스명 문자열
 *
 * @example
 * cn('foo', true && 'bar', false && 'baz', undefined, null)
 * // => 'foo bar'
 */
export function cn(...classes: (string | boolean | undefined | null)[]): string {
  return classes.filter(Boolean).join(' ');
}

/**
 * BEM 클래스명 생성 (선택적)
 * @param block - BEM block
 * @param element - BEM element (optional)
 * @param modifier - BEM modifier (optional)
 *
 * @example
 * bem('card', 'header', 'active')
 * // => 'card__header--active'
 */
export function bem(block: string, element?: string, modifier?: string): string {
  let className = block;
  if (element) {
    className += `__${element}`;
  }
  if (modifier) {
    className += `--${modifier}`;
  }
  return className;
}

/**
 * 조건부 클래스명 (cn alias)
 */
export function classNames(...classes: (string | boolean | undefined | null)[]): string {
  return cn(...classes);
}
