/**
 * OfflinePhase 컴포넌트
 * 닉네임 입력과 인트로 화면
 */
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { Button } from "@/components/ui";

interface OfflinePhaseProps {
  nickname: string;
  onNameChange: (name: string) => void;
  onConnect: () => void;
}

export function OfflinePhase({
  nickname,
  onNameChange,
  onConnect,
}: OfflinePhaseProps): JSX.Element {
  const t = useTranslations();

  return (
    <div className="intro">
      <div className="banner-frame">
        {/* eslint-disable-next-line @next/next/no-img-element -- 정적 장식 배너, 반응형 폭 유지 위해 img 유지 */}
        <img src="/assets/banner.png" alt="" />
      </div>

      <div className="intro-form">
        <input
          className="name-input"
          value={nickname}
          onChange={(e) => onNameChange(e.target.value)}
          placeholder={t("intro.namePlaceholder")}
          maxLength={12}
          onKeyDown={(e) => e.key === "Enter" && onConnect()}
        />
        <Button className="cta block" onClick={onConnect}>
          {t("intro.startButton")}
        </Button>
      </div>
    </div>
  );
}
