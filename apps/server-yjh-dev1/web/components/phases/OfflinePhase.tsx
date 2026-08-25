/**
 * OfflinePhase 컴포넌트
 * 재방문(저장된 이름) — 환영 뷰 + 작은 이름 변경 버튼 / 첫 방문 — 닉네임 입력 폼
 */
import type { JSX } from "react";
import { useState } from "react";
import { useTranslations } from "next-intl";
import { Button } from "@/components/ui";

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
  const [editing, setEditing] = useState(false);

  return (
    <div className="intro">
      <div className="banner-frame">
        {/* eslint-disable-next-line @next/next/no-img-element -- 정적 장식 배너, 반응형 폭 유지 위해 img 유지 */}
        <img src="/assets/banner.png" alt="" />
      </div>

      {hasSavedName && !editing ? (
        <div className="intro-form">
          <div className="welcome-box">
            <div className="welcome-name">{t("intro.welcomeBack", { name: nickname })}</div>
            <Button className="cta block" onClick={onConnect}>
              {t("intro.continue")}
            </Button>
            <button
              className="btn-text"
              onClick={() => {
                onResetName();
                setEditing(true);
              }}
            >
              {t("intro.changeName")}
            </button>
          </div>
        </div>
      ) : (
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
      )}
    </div>
  );
}
