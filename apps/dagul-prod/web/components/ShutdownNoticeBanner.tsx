import type { JSX } from "react";
import { useTranslations } from "next-intl";

interface ShutdownNoticeBannerProps {
  message: string | null;
  onDismiss: () => void;
  /** 게임 캔버스(.gc-overlay, z-index 100) 위에 띄울 때 — 화면 상단에 고정. */
  overCanvas?: boolean;
}

/** 배포 드레인 안내 — LobbyRoom.onBeforeShutdown 이 보낸 서버 문구를 그대로 보여준다.
 * 연결은 안 끊는다(매치가 자연히 끝나거나 드레인 시간이 차야 끊긴다) — 닫기만 가능. */
export function ShutdownNoticeBanner(
  { message, onDismiss, overCanvas = false }: ShutdownNoticeBannerProps,
): JSX.Element | null {
  const t = useTranslations("game");
  if (!message) {return null;}
  return (
    <div
      className={`status-msg info deploy-banner${overCanvas ? " shutdown-banner-fixed" : ""}`}
      role="status"
    >
      <span>{message}</span>
      <button type="button" className="ghost btn-sm" onClick={onDismiss}>
        {t("dismiss")}
      </button>
    </div>
  );
}
