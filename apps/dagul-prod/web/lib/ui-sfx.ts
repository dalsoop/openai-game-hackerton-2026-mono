export const OK_BUTTON_SRC = "/assets/ok-button.mp3";
const OK_VOL = 0.85;

/** jsdom 의 play() 는 Promise 가 아닐 수 있다. */
export function playMedia(el: { play: () => unknown }): void {
  void Promise.resolve(el.play()).catch(() => { /* autoplay 거절 */ });
}

/** 인트로 「시작하기」·대기실 「게임 시작」. 제스처 안이면 play 가 바로 난다. */
export function playOkButton(): void {
  if (typeof Audio === "undefined") {return;}
  const a = new Audio(OK_BUTTON_SRC);
  a.volume = OK_VOL;
  playMedia(a);
}
