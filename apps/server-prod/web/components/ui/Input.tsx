/**
 * Input 컴포넌트 — 스타일은 globals.css 의 .field-* 클래스가 담당한다.
 */
import type { JSX } from "react";
import { cn } from "@/lib/helpers";

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  fullWidth?: boolean;
}

export function Input({
  label,
  error,
  fullWidth = false,
  className,
  ...props
}: InputProps): JSX.Element {
  return (
    <div className={cn("field-wrap", fullWidth && "block")}>
      {label && <label className="field-label">{label}</label>}
      <input className={cn("field", error && "has-error", className)} {...props} />
      {error && <span className="field-error">{error}</span>}
    </div>
  );
}
