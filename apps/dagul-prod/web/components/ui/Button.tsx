/**
 * Button 컴포넌트 — variants 는 globals.css 의 .btn-* 클래스가 담당한다.
 */
import type { JSX } from "react";
import { cn } from "@/lib/helpers";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "green" | "muted" | "ghost";
  size?: "sm" | "md" | "lg";
  fullWidth?: boolean;
  children: React.ReactNode;
}

export function Button({
  variant = "primary",
  size = "md",
  fullWidth = false,
  className,
  children,
  disabled,
  ...props
}: ButtonProps): JSX.Element {
  return (
    <button
      className={cn(
        "btn",
        `btn-${variant}`,
        `btn-${size}`,
        fullWidth && "btn-block",
        className,
      )}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
}
