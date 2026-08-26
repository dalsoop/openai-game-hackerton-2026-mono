/**
 * Card 컴포넌트 — variants 는 globals.css 의 .card-* 클래스가 담당한다.
 */
import type { JSX } from "react";
import { cn } from "@/lib/helpers";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  interactive?: boolean;
  variant?: "default" | "elevated" | "bordered";
}

export function Card({
  interactive = false,
  variant = "default",
  className,
  children,
  ...props
}: CardProps): JSX.Element {
  return (
    <div
      className={cn(
        "card",
        variant !== "default" && `card-${variant}`,
        interactive && "card-interactive",
        className,
      )}
      {...props}
    >
      {children}
    </div>
  );
}
