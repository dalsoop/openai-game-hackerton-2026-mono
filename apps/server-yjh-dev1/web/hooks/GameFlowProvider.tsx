"use client";
// 로비(/) 와 방 만들기(/create) 가 같은 허브 세션을 쓰도록 올린다.
import { createContext, useContext } from "react";
import type { JSX, ReactNode } from "react";
import { useTranslations } from "next-intl";
import { useGameFlow, type UseGameFlowResult } from "@/hooks/useGameFlow";

const GameFlowContext = createContext<UseGameFlowResult | null>(null);

export function GameFlowProvider({
  children,
  buildId = "",
}: {
  children: ReactNode;
  buildId?: string;
}): JSX.Element {
  const t = useTranslations("intro");
  const value = useGameFlow(t("defaultPlayer"), buildId);
  return <GameFlowContext.Provider value={value}>{children}</GameFlowContext.Provider>;
}

export function useGameFlowContext(): UseGameFlowResult {
  const ctx = useContext(GameFlowContext);
  if (!ctx) {
    throw new Error("useGameFlowContext requires GameFlowProvider");
  }
  return ctx;
}
