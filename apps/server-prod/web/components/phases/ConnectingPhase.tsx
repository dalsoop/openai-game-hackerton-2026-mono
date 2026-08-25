/**
 * ConnectingPhase 컴포넌트
 * 연결 중 상태 표시
 */
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { StatusMessage } from "@/components/ui";

interface ConnectingPhaseProps {
  message?: string;
}

export function ConnectingPhase({ message }: ConnectingPhaseProps): JSX.Element {
  const t = useTranslations();
  const displayMessage = message ?? t("game.serverConnecting");

  return (
    <div className="fade-in">
      <StatusMessage variant="info">{displayMessage}</StatusMessage>
    </div>
  );
}
