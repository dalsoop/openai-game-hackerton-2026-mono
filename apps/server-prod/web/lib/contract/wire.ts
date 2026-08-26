import { CloseCode } from "@colyseus/sdk";

export {
  HANDOFF, WEB_STORE, DOM_EVT, HUB_MSG, PLAY_MSG, PAGE_MSG, MSG,
} from "@dalsoop/hub-kernel";

export const CLOSE_CODE = {
  CONSENTED: CloseCode.CONSENTED,
  KICKED: CloseCode.CONSENTED,
} as const;

export const ROOM_LEAVE = {
  CONSENTED: true,
  HANDOFF: false,
} as const;
