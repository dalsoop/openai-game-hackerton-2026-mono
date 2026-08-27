import type { CcuSnapshot } from "./ccu-plan.js";

/** 라이브 프로브·Helm 이 같은 JSON 을 본다. fig/pjh 허브와 slot 필드가 같다. ccu 는 선택. */
export function healthBody(slot = process.env.SLOT_FOLDER ?? "", ccu?: CcuSnapshot): string {
  if (!ccu) {return JSON.stringify({ ok: true, slot });}
  return JSON.stringify({
    ok: true,
    slot,
    ccu: ccu.ccu,
    cap: ccu.cap,
    level: ccu.level,
    admit: ccu.admit,
  });
}
