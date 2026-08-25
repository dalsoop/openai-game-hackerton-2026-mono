// 방 PIN 프롬프트 — 창 입력 정규화만 담 (useHub 복잡도 분산).
import { KO } from "@/lib/hub/config";

/** 숫자만 남긴다. 취소(null)는 빈 문자열로 흡수한다. */
function promptDigits(message: string): string {
  const raw = window.prompt(message) ?? "";
  return raw.replace(/\D/g, "");
}

/** 방 만들기 PIN(선택) — 숫자만 정규화해 돌려준다 (4자 미만=없음 취급은 호출자가). */
export function pinForCreate(): string {
  return promptDigits(KO.PIN_CREATE_PROMPT);
}

/** 잠긴 방 입장 PIN — 취소면 null(입장 중단). */
export function pinForJoin(): string | null {
  const pin = promptDigits(KO.PIN_JOIN_PROMPT);
  return pin === "" ? null : pin;
}

/** 입장 요청 조립 — 잠긴 방이면 PIN 을 묻고, 취소면 null. */
export function buildJoinRequest(id: string, locked: boolean | undefined): { kind: "join"; id: string; pin?: string } | null {
  if (!locked) {return { kind: "join", id };}
  const pin = pinForJoin();
  return pin === null ? null : { kind: "join", id, pin };
}

/** 생성 요청 조립 — PIN(선택)·게임(선택)만 붙인다. */
export function buildCreateRequest(game?: string): { kind: "create"; game?: string; pin?: string } {
  const pin = pinForCreate();
  return { kind: "create", ...(game ? { game } : {}), ...(pin.length >= 4 ? { pin } : {}) };
}
