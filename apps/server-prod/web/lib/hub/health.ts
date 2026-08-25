/** 라이브 프로브·Helm 이 같은 JSON 을 본다. fig/pjh 허브와 slot 필드가 같다. */
export function healthBody(slot = process.env.SLOT_FOLDER ?? ""): string {
  return JSON.stringify({ ok: true, slot });
}
