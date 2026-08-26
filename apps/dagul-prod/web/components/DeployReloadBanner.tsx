import type { JSX } from "react";
import { useTranslations } from "next-intl";

interface DeployReloadBannerProps {
  visible: boolean;
  onReload: () => void;
}

export function DeployReloadBanner({ visible, onReload }: DeployReloadBannerProps): JSX.Element | null {
  const t = useTranslations("update");
  if (!visible) {return null;}
  return (
    <div className="status-msg info deploy-banner" role="status">
      <span>{t("available")}</span>
      <button type="button" className="ghost btn-sm" onClick={onReload}>
        {t("reload")}
      </button>
    </div>
  );
}
