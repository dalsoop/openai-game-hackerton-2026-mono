"use client";
import { useRef, type JSX, type KeyboardEvent } from "react";
import { PIN_LENGTH } from "@/lib/hub/room-password";

interface Props {
  value: string;
  onChange: (next: string) => void;
  disabled?: boolean;
  labelledBy?: string;
  autoFocus?: boolean;
}

export default function PinBoxes({
  value, onChange, disabled = false, labelledBy, autoFocus = false,
}: Props): JSX.Element {
  const digits = value.replace(/\D/g, "").slice(0, PIN_LENGTH).split("");
  while (digits.length < PIN_LENGTH) {digits.push("");}
  const refs = useRef<Array<HTMLInputElement | null>>([]);

  const setAt = (index: number, digit: string): void => {
    const next = digits.slice();
    next[index] = digit;
    onChange(next.join(""));
  };

  const onKey = (index: number, e: KeyboardEvent<HTMLInputElement>): void => {
    if (disabled) {return;}
    if (e.key === "Backspace") {
      e.preventDefault();
      setAt(index, "");
      refs.current[Math.max(0, index - 1)]?.focus();
      return;
    }
    if (e.key.length === 1 && /\d/.test(e.key)) {
      e.preventDefault();
      setAt(index, e.key);
      refs.current[Math.min(PIN_LENGTH - 1, index + 1)]?.focus();
    }
  };

  return (
    <div className="pin-boxes" role="group" aria-labelledby={labelledBy}>
      {digits.map((d, i) => (
        <input
          // eslint-disable-next-line react/no-array-index-key -- PIN 칸 순서가 곧 자리 값이다
          key={i}
          ref={(el) => {refs.current[i] = el;}}
          className="pin-box"
          type="text"
          inputMode="numeric"
          autoComplete="one-time-code"
          maxLength={1}
          value={d}
          disabled={disabled}
          autoFocus={autoFocus && i === 0}
          onChange={() => undefined}
          onKeyDown={(e) => {onKey(i, e);}}
          onPaste={(e) => {
            e.preventDefault();
            if (disabled) {return;}
            const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, PIN_LENGTH);
            if (pasted) {onChange(pasted);}
          }}
        />
      ))}
    </div>
  );
}
