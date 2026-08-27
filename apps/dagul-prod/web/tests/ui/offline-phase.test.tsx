// @vitest-environment jsdom
/**
 * 인트로(OfflinePhase) UI 계약 — 저장된 이름 상태.
 *   1. 첫 방문(이름 없음) → 로그아웃 버튼 없음, 입력폼만
 *   2. 저장된 이름 → 입력폼 옆 작은 로그아웃 버튼 (별도 칩 문구는 두지 않는다)
 *   3. 로그아웃 클릭 → onResetName 호출 (세션 폐기는 상위 훅 담당)
 */
import { afterEach, describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent, cleanup } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { OfflinePhase } from "@/components/phases/OfflinePhase";
import ko from "../../messages/ko.json";

const messages = { intro: ko.intro, congestion: ko.congestion, logo: ko.logo } as typeof ko;

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

describe("인트로 저장된 이름 상태", () => {
  it("첫 방문(hasSavedName=false) — 로그아웃 버튼 없음, 입력폼 렌더", () => {
    setup({ hasSavedName: false });
    expect(screen.queryByText(ko.intro.logout)).toBeNull();
    const input = screen.getByPlaceholderText(ko.intro.namePlaceholder);
    expect(input.getAttribute("name")).toBe("player-name");
    expect(screen.getByText(ko.intro.startButton)).toBeTruthy();
  });

  it("저장된 이름 — 로그아웃 버튼, 입력폼은 유지", () => {
    setup({ hasSavedName: true, nickname: "체커" });
    expect(screen.getByText(ko.intro.logout)).toBeTruthy();
    // 로그아웃 버튼이 진입을 가로채지 않는다 — 입력폼·시작 버튼 그대로
    expect(screen.getByPlaceholderText(ko.intro.namePlaceholder)).toBeTruthy();
    expect(screen.getByText(ko.intro.startButton)).toBeTruthy();
  });

  it("로그아웃 클릭 → onResetName 호출", () => {
    const props = setup();
    fireEvent.click(screen.getByText(ko.intro.logout));
    expect(props.onResetName).toHaveBeenCalledTimes(1);
  });

  it("배너 아트는 잘리지 않게 banner-art 로 둔다", () => {
    setup({ hasSavedName: false });
    const art = document.querySelector("img.banner-art");
    expect(art).toBeTruthy();
    expect(art?.getAttribute("src")).toBe("/assets/title-animals.png");
    const logo = document.querySelector("img.intro-logo");
    expect(logo?.getAttribute("src")).toBe(ko.logo.src);
    expect(logo?.getAttribute("class")).toBe(ko.logo.className);
  });

  it("시작하기 클릭 → onConnect 호출 (저장된 이름이 있어도 진입 가능)", () => {
    const props = setup();
    fireEvent.click(screen.getByText(ko.intro.startButton));
    expect(props.onConnect).toHaveBeenCalledTimes(1);
  });

  it("원활이면 시작하기를 막지 않는다", () => {
    const props = setup({
      ccu: { ccu: 12, cap: 100, level: "quiet", admit: true },
    });
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.capLabel);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.quiet);
    fireEvent.click(screen.getByText(ko.intro.startButton));
    expect(props.onConnect).toHaveBeenCalledTimes(1);
  });

  it("꽉참이면 시작 버튼을 막고 안내를 보여 준다", () => {
    const props = setup({
      ccu: { ccu: 100, cap: 100, level: "full", admit: false },
    });
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.capLabel);
    expect(screen.getByRole("status").textContent).toContain(ko.congestion.full);
    expect(screen.getByText(ko.congestion.fullHint)).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: ko.congestion.full }));
    expect(props.onConnect).not.toHaveBeenCalled();
  });
});
