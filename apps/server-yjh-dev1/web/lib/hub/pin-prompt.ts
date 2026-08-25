// 방 PIN 프롬프트 — 창 입력 정규화만 담 (useHub 복잡도 분산).
import { KO } from "@/lib/hub/config";
import { parsePin } from "@/lib/hub/room-options";

// PIN 규칙의 정본은 room-options — 여기선 창 입력만 받아 넘긴다.
function promptPin(message: string): string | null {
  return window.prompt(message);
}

/** 방 만들기 PIN(선택) — 숫자만 정규화해 돌려준다 (4자 미만=없음 취급은 호출자가). */
export function pinForCreate(): string {
  // 정본 규칙(room-options)으로 정규화 — 유효하지 않으면 잠금 없음("").
  return parsePin(promptPin(KO.PIN_CREATE_PROMPT)) ?? "";
}

/** 잠긴 방 입장 PIN — 취소면 null(입장 중단). */
export function pinForJoin(): string | null {
  // 유효 PIN 이면 그 값, 취소·불량이면 null (입장 중단).
  return parsePin(promptPin(KO.PIN_JOIN_PROMPT));
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
