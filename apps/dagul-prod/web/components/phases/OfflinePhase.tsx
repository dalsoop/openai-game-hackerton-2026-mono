/**
 * OfflinePhase 컴포넌트
 * 닉네임 입력과 인트로 화면 — 세션 재개는 useGameFlow 마운트 시 자동 시도한다
 */
import type { JSX } from "react";
import { useLocale, useTranslations } from "next-intl";
import { Button } from "@/components/ui";
import { playOkButton } from "@/lib/ui-sfx";

interface OfflinePhaseProps {
  nickname: string;
  hasSavedName: boolean;
  onNameChange: (name: string) => void;
  onConnect: () => void;
  onResetName: () => void;
}

export function OfflinePhase({
  nickname,
  hasSavedName,
  onNameChange,
  onConnect,
  onResetName,
}: OfflinePhaseProps): JSX.Element {
  const t = useTranslations();
  const locale = useLocale();

  return (
    <div className="intro">
      <div className="banner-frame">
        {/* eslint-disable @next/next/no-img-element -- 인트로 정적 배너·로고, 반응형 폭 유지 */}
        <img src="/assets/title-animals.png" alt="" />
        <img
          className={locale === "ko" ? "intro-logo intro-logo-ko" : "intro-logo"}
          src={locale === "ko" ? "/assets/logo-animal-dagulz-ko.png" : "/assets/logo-animal-dagulz-en.png?v=2"}
          alt=""
        />
        {/* eslint-enable @next/next/no-img-element */}
      </div>

      <div className="intro-form">
        <div className="name-row">
          <input
            className="name-input"
            name="player-name"
            autoComplete="nickname"
            value={nickname}
            onChange={(e) => onNameChange(e.target.value)}
            placeholder={t("intro.namePlaceholder")}
            maxLength={12}
            onKeyDown={(e) => {
              if (e.key !== "Enter") {return;}
              playOkButton();
              onConnect();
            }}
            suppressHydrationWarning
          />
          {hasSavedName && (
            <button type="button" className="ghost btn-sm logout-btn" onClick={onResetName}>
              {t("intro.logout")}
            </button>
          )}
        </div>
        <Button
          className="cta block"
          data-sfx="ok"
          onClick={() => {
            playOkButton();
            onConnect();
          }}
        >
          {t("intro.startButton")}
        </Button>
      </div>
    </div>
  );
}
