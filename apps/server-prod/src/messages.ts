/** Korean UI strings — single source for i18n extraction. */
export const KO = {
  // Default / config
  DEFAULT_NAME: "손님",

  // Mode titles & blurbs
  MODE_CLASSIC: "클래식",
  MODE_CLASSIC_BLURB: "시작부터 각자 다른 총. 루팅 없음.",
  MODE_GUN_SEMI: "무기 · 단발",
  MODE_GUN_SEMI_BLURB: "전원 단발 권총. 처치하면 총을 줍는다.",
  MODE_GUN_AUTO: "무기 · 연발",
  MODE_GUN_AUTO_BLURB: "전원 연발 권총. 처치하면 총을 줍는다.",
  MODE_ITEM: "아이템",
  MODE_ITEM_BLURB: "총은 기본 권총 고정. 메드킷·부스터만 줍는다.",
  MODE_FULL: "합본",
  MODE_FULL_BLURB: "단발 권총 시작. 총과 아이템을 같이 줍는다.",

  // Room / lobby
  ROOM_NOT_FOUND: "방을 찾을 수 없습니다",
  ROOM_FULL: "방이 가득 찼습니다 (8)",
  CANNOT_CHANGE_MODE: "지금은 게임을 바꿀 수 없습니다",
  HOST_ONLY_MODE: "호스트만 게임을 바꿀 수 있습니다",
  HOST_ONLY_START: "호스트만 시작할 수 있습니다",
  CANNOT_KICK: "지금은 내보낼 수 없습니다",
  HOST_ONLY_KICK: "호스트만 내보낼 수 있습니다",
  KICKED_MSG: "호스트가 방에서 내보냈습니다.",
  HOST_BOOT_FAIL: "호스트가 게임을 시작하지 못했습니다.",
  GAME_END_LOBBY: "게임이 끝났습니다. 대기실로 돌아왔습니다.",
  RESUME_NOT_FOUND: "이전 자리를 찾지 못했습니다. 로비로 갑니다.",

  // Dynamic (template functions)
  playerJoined: (name: string) => `${name} 이(가) 들어왔습니다.`,
  playerKicked: (name: string) => `${name} 이(가) 내보내졌습니다.`,
  playerLeft: (name: string) => `${name} 이(가) 나갔습니다.`,
  playerReconnected: (name: string) => `${name} 이(가) 다시 연결되었습니다.`,
  hostLeftEnd: (name: string) => `호스트(${name})가 나가서 게임이 종료됩니다.`,
  hostDisconnectedEnd: (name: string) => `호스트(${name})의 연결이 끊겨 게임이 종료됩니다.`,
  playerDropped: (name: string, sec: number) =>
    `${name} 연결이 끊겼습니다. ${sec}초 안에 다시 들어오면 자리가 유지됩니다.`,
} as const;
