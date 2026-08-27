// @vitest-environment jsdom
import { describe, expect, it, vi } from "vitest";
import { fireEvent, render } from "@testing-library/react";
import PinBoxes from "@/components/PinBoxes";

describe("PinBoxes", () => {
  it("숫자 키를 칸마다 채운다", () => {
    const onChange = vi.fn();
    const { container } = render(<PinBoxes value="" onChange={onChange} />);
    const boxes = container.querySelectorAll("input");
    expect(boxes).toHaveLength(4);
    fireEvent.keyDown(boxes[0], { key: "1" });
    expect(onChange).toHaveBeenCalledWith("1");
  });

  it("붙여넣으면 4자리를 한 번에 넣는다", () => {
    const onChange = vi.fn();
    const { container } = render(<PinBoxes value="" onChange={onChange} />);
    fireEvent.paste(container.querySelectorAll("input")[0], {
      clipboardData: { getData: () => "42-42" },
    });
    expect(onChange).toHaveBeenCalledWith("4242");
  });

  it("다섯 자리를 붙여넣으면 앞 4자리만 남긴다", () => {
    const onChange = vi.fn();
    const { container } = render(<PinBoxes value="" onChange={onChange} />);
    fireEvent.paste(container.querySelectorAll("input")[0], {
      clipboardData: { getData: () => "987654" },
    });
    expect(onChange).toHaveBeenCalledWith("9876");
  });

  it("Backspace 는 그 칸을 비운다", () => {
    const onChange = vi.fn();
    const { container } = render(<PinBoxes value="12" onChange={onChange} />);
    fireEvent.keyDown(container.querySelectorAll("input")[1], { key: "Backspace" });
    expect(onChange).toHaveBeenCalledWith("1");
  });

  it("글자 키는 무시한다", () => {
    const onChange = vi.fn();
    const { container } = render(<PinBoxes value="" onChange={onChange} />);
    fireEvent.keyDown(container.querySelectorAll("input")[0], { key: "a" });
    expect(onChange).not.toHaveBeenCalled();
  });

  it("disabled 면 키를 받아도 값이 안 바뀐다", () => {
    const onChange = vi.fn();
    const { container } = render(<PinBoxes value="0420" onChange={onChange} disabled />);
    const boxes = container.querySelectorAll("input");
    expect((boxes[0] as HTMLInputElement).disabled).toBe(true);
    fireEvent.keyDown(boxes[0], { key: "9" });
    expect(onChange).not.toHaveBeenCalled();
  });
});
