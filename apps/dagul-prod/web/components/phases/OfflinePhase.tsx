/**
 * OfflinePhase 컴포넌트
 * 닉네임 입력과 인트로 화면 — 세션 재개는 useGameFlow 마운트 시 자동 시도한다
 */
import type { JSX } from "react";
import { useTranslations } from "next-intl";
import { Button } from "@/components/ui";
import { CongestionBanner } from "@/components/CongestionBanner";
import { playOkButton } from "@/lib/ui-sfx";
import type { CcuSnapshot } from "@/lib/hub/ccu-plan";
import { HUB_CONFIG } from "@/lib/hub/config";

interface OfflinePhaseProps {
  nickname: string;
  hasSavedName: boolean;
  onNameChange: (name: string) => void;
  onConnect: () => void;
  onResetName: () => void;
  ccu?: CcuSnapshot | null;
}

export function OfflinePhase({
  nickname,
  hasSavedName,
  onNameChange,
  onConnect,
  onResetName,
  ccu = null,
}: OfflinePhaseProps): JSX.Element {
  const t = useTranslations();
  const blocked = ccu !== null && !ccu.admit;

  return (
    <div className="intro">
      <div className="banner-frame">
        {/* eslint-disable @next/next/no-img-element -- 인트로 정적 배너·로고, 반응형 폭 유지 */}
        <img className="banner-art" src="/assets/title-animals.png" alt="" />
        <img
          className={t("logo.className")}
          src={t("logo.src")}
          alt=""
        />
        {/* eslint-enable @next/next/no-img-element */}
      </div>

      <div className="intro-form">
        <CongestionBanner snap={ccu} />
        {blocked && <p className="ccu-hint">{t("congestion.fullHint")}</p>}
        <div className="name-row">
          <input
            className="name-input"
            name="player-name"
            autoComplete="nickname"
            value={nickname}
            onChange={(e) => onNameChange(e.target.value)}
            placeholder={t("intro.namePlaceholder")}
            maxLength={HUB_CONFIG.maxNameLength}
            onKeyDown={(e) => {
              if (e.key !== "Enter" || blocked) {return;}
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
          disabled={blocked}
          onClick={() => {
            if (blocked) {return;}
            playOkButton();
            onConnect();
          }}
        >
          {blocked ? t("congestion.full") : t("intro.startButton")}
        </Button>
      </div>
    </div>
  );
}
