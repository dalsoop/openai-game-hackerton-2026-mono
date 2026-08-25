// @vitest-environment jsdom
/**
 * 인트로(OfflinePhase) UI 계약 — 로그인 상태 칩.
 * 손검증 시나리오(2026-08-25)를 그대로 코드화:
 *   1. 첫 방문(이름 없음) → 칩 없음, 입력폼만
 *   2. 저장된 이름 → 「{name}으로 로그인됨」 칩 + 작은 로그아웃 버튼
 *   3. 로그아웃 클릭 → onResetName 호출 (세션 폐기는 상위 훅 담당)
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { OfflinePhase } from "@/components/phases/OfflinePhase";
import ko from "../../messages/ko.json";

const messages = { intro: ko.intro } as typeof ko;

type SetupProps = Parameters<typeof OfflinePhase>[0];
function setup(overrides: Partial<SetupProps> = {}): SetupProps {
  const props = {
    nickname: "체커",
    hasSavedName: true,
    onNameChange: vi.fn(),
    onConnect: vi.fn(),
    onResetName: vi.fn(),
    ...overrides,
  };
  render(
    <NextIntlClientProvider locale="ko" messages={messages}>
      <OfflinePhase {...props} />
    </NextIntlClientProvider>,
  );
  return props;
}

afterEach(cleanup);

describe("인트로 로그인 칩", () => {
  it("첫 방문(hasSavedName=false) — 칩 없음, 입력폼 렌더", () => {
    setup({ hasSavedName: false });
    expect(screen.queryByText(/로그인됨/)).toBeNull();
    expect(screen.getByPlaceholderText(ko.intro.namePlaceholder)).toBeTruthy();
    expect(screen.getByText(ko.intro.startButton)).toBeTruthy();
  });

  it("저장된 이름 — 「{name}으로 로그인됨」 칩 + 로그아웃 버튼, 입력폼은 유지", () => {
    setup({ hasSavedName: true, nickname: "체커" });
    expect(screen.getByText("체커으로 로그인됨")).toBeTruthy();
    expect(screen.getByText(ko.intro.logout)).toBeTruthy();
    // 칩이 진입을 가로채지 않는다 — 입력폼·시작 버튼 그대로
    expect(screen.getByPlaceholderText(ko.intro.namePlaceholder)).toBeTruthy();
    expect(screen.getByText(ko.intro.startButton)).toBeTruthy();
  });

  it("로그아웃 클릭 → onResetName 호출", () => {
    const props = setup();
    fireEvent.click(screen.getByText(ko.intro.logout));
    expect(props.onResetName).toHaveBeenCalledTimes(1);
  });

  it("시작하기 클릭 → onConnect 호출 (칩이 있어도 진입 가능)", () => {
    const props = setup();
    fireEvent.click(screen.getByText(ko.intro.startButton));
    expect(props.onConnect).toHaveBeenCalledTimes(1);
  });
});
