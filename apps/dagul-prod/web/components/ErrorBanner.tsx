import type { JSX } from "react";
import { useTranslations } from "next-intl";

interface ErrorBannerProps {
  message: string | null;
  onDismiss: () => void;
  /** 게임 캔버스(.gc-overlay, z-index 100) 위에 띄울 때 — 화면 상단에 고정. */
  overCanvas?: boolean;
}

/** hub.error(MSG.ERROR·방 접속 실패 등) 를 그대로 보여준다. 예전엔 이 state 를
 * 아무도 렌더링하지 않아서, 호스트 전용 거부·방 꽉 찼음·조인 실패가 전부
 * 화면 반응 없이 조용히 사라졌다. */
export function ErrorBanner({ message, onDismiss, overCanvas = false }: ErrorBannerProps): JSX.Element | null {
  const t = useTranslations("game");
  if (!message) {return null;}
  return (
    <div
      className={`status-msg error deploy-banner${overCanvas ? " shutdown-banner-fixed" : ""}`}
      role="alert"
    >
      <span>{message}</span>
      <button type="button" className="ghost btn-sm" onClick={onDismiss}>
        {t("dismiss")}
      </button>
    </div>
  );
}
