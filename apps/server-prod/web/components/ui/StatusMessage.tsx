/**
 * StatusMessage 컴포넌트 — 스타일은 globals.css 의 .status-msg-* 클래스가 담당한다.
 */
import type { JSX } from "react";
import { cn } from "@/lib/helpers";

interface StatusMessageProps {
  variant?: "error" | "success" | "info";
  children: React.ReactNode;
  className?: string;
}

export function StatusMessage({
  variant = "info",
  children,
  className,
}: StatusMessageProps): JSX.Element {
  return (
    <div className={cn("status-msg", variant, className)}>
      {children}
    </div>
  );
}
