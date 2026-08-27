import { describe, expect, it } from "vitest";
import {
  generateRoomPin, hasRoomPassword, joinPasswordOk, parseLockFlag, parseRoomPassword,
  passwordMatches, resolveCreatePassword, resolveSetPassword, PIN_LENGTH,
} from "@/lib/hub/room-password";

describe("generateRoomPin", () => {
  it("항상 4자리 숫자 문자열", () => {
    expect(generateRoomPin(() => 0)).toBe("0000");
    expect(generateRoomPin(() => 0.1234)).toBe("1234");
    expect(generateRoomPin(() => 0.9999)).toMatch(/^\d{4}$/);
    expect(generateRoomPin()).toHaveLength(PIN_LENGTH);
  });
});

describe("parseRoomPassword", () => {
  it("숫자 4자리만 인정", () => {
    expect(parseRoomPassword("1234")).toBe("1234");
    expect(parseRoomPassword(" 12-34 ")).toBe("1234");
    expect(parseRoomPassword("04-20")).toBe("0420");
    expect(parseRoomPassword(1234)).toBe("1234");
    expect(parseRoomPassword("12")).toBe("");
    expect(parseRoomPassword("12345")).toBe("");
    expect(parseRoomPassword("abcd")).toBe("");
    expect(parseRoomPassword("")).toBe("");
    expect(parseRoomPassword(null)).toBe("");
    expect(parseRoomPassword(undefined)).toBe("");
  });
});

describe("parseLockFlag", () => {
  it("켜짐·꺼짐 값을 가린다", () => {
    expect(parseLockFlag(true)).toBe(true);
    expect(parseLockFlag("true")).toBe(true);
    expect(parseLockFlag("on")).toBe(true);
    expect(parseLockFlag(1)).toBe(true);
    expect(parseLockFlag("1")).toBe(true);
    expect(parseLockFlag(false)).toBe(false);
    expect(parseLockFlag("false")).toBe(false);
    expect(parseLockFlag("off")).toBe(false);
    expect(parseLockFlag(0)).toBe(false);
    expect(parseLockFlag("0")).toBe(false);
    expect(parseLockFlag("yes")).toBe(false);
    expect(parseLockFlag(null)).toBe(false);
    expect(parseLockFlag(undefined)).toBe(false);
  });
});

describe("passwordMatches", () => {
  it("저장된 PIN 과 같아야 통과", () => {
    expect(passwordMatches("0420", "0420")).toBe(true);
    expect(passwordMatches("0420", "04-20")).toBe(true);
    expect(passwordMatches("0420", "4-20")).toBe(false);
    expect(passwordMatches("0420", "0000")).toBe(false);
    expect(passwordMatches("", "1234")).toBe(false);
    expect(passwordMatches("12", "12")).toBe(false);
  });

  it("hasRoomPassword 는 하이픈 없는 4자리만", () => {
    expect(hasRoomPassword("0000")).toBe(true);
    expect(hasRoomPassword("0420")).toBe(true);
    expect(hasRoomPassword("12")).toBe(false);
    expect(hasRoomPassword("12-34")).toBe(false);
    expect(hasRoomPassword("12345")).toBe(false);
    expect(hasRoomPassword("")).toBe(false);
  });
});

describe("joinPasswordOk", () => {
  it("방 만든 사람과 이어받기는 PIN 없이 통과", () => {
    expect(joinPasswordOk("0420", "", { isCreator: true, takeover: false })).toBe(true);
    expect(joinPasswordOk("0420", "", { isCreator: false, takeover: true })).toBe(true);
  });

  it("다른 사람은 4자리가 맞아야 한다", () => {
    expect(joinPasswordOk("0420", "0420", { isCreator: false, takeover: false })).toBe(true);
    expect(joinPasswordOk("0420", "0000", { isCreator: false, takeover: false })).toBe(false);
    expect(joinPasswordOk("0420", "", { isCreator: false, takeover: false })).toBe(false);
  });

  it("공개 방은 PIN 없이 들어온다", () => {
    expect(joinPasswordOk("", "", { isCreator: false, takeover: false })).toBe(true);
    expect(joinPasswordOk("", "1234", { isCreator: false, takeover: false })).toBe(true);
  });
});

describe("resolveCreatePassword", () => {
  it("토글이 꺼져 있으면 PIN 이 없다", () => {
    expect(resolveCreatePassword({})).toBe("");
    expect(resolveCreatePassword({ lock: false })).toBe("");
    expect(resolveCreatePassword({ lock: "off", password: "12" })).toBe("");
  });

  it("토글이 켜져 있으면 4자리를 만든다", () => {
    expect(resolveCreatePassword({ lock: true }, () => "7777")).toBe("7777");
    expect(resolveCreatePassword({ lock: "on" }, () => "0001")).toBe("0001");
  });

  it("토글이 꺼져 있어도 이미 4자리면 그 값을 쓴다", () => {
    expect(resolveCreatePassword({ lock: false, password: "12-34" })).toBe("1234");
  });

  it("토글이 켜져 있고 4자리가 오면 새로 뽑지 않는다", () => {
    expect(resolveCreatePassword({ lock: true, password: "4242" }, () => "9999")).toBe("4242");
  });
});

describe("resolveSetPassword", () => {
  it("끄면 비우고 켜면 새로 뽑는다", () => {
    expect(resolveSetPassword({ enabled: false })).toBe("");
    expect(resolveSetPassword({ enabled: false, password: "4242" })).toBe("");
    expect(resolveSetPassword({ enabled: true }, () => "4242")).toBe("4242");
    expect(resolveSetPassword({ password: "9999" })).toBe("9999");
    expect(resolveSetPassword({ enabled: true, password: "12-34" }, () => "0000")).toBe("1234");
    expect(resolveSetPassword({})).toBe("");
    expect(resolveSetPassword({ password: "12" })).toBe("");
    expect(resolveSetPassword({ enabled: "yes" })).toBe("");
  });
});
