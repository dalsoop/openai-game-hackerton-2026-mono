"use client";
/**
 * 연결 끊김 모달 — 허브가 오프라인일 때 화면 흐름 대신 이 대화상자가 소유권을 갖는다.
 * 인라인 status 메시지와 달리 "지금 진행할 수 없다"를 명시적으로 차단한다.
 */
import type { ReactNode } from "react";
import { useTranslations } from "next-intl";
import { Button, Modal } from "@/components/ui";

interface ConnectionLostModalProps {
  onReconnect: () => void;
  onExit: () => void;
}

export function ConnectionLostModal({ onReconnect, onExit }: ConnectionLostModalProps): ReactNode {
  const t = useTranslations();

  return (
    <Modal tone="error">
      <h2 className="modal-title">{t("game.serverConnectFailed")}</h2>
      <p className="modal-body">{t("connection.offline")}</p>
      <div className="modal-actions">
        <Button variant="primary" onClick={onReconnect} autoFocus>
          {t("game.reconnect")}
        </Button>
        <Button variant="ghost" onClick={onExit}>
          {t("game.back")}
        </Button>
      </div>
    </Modal>
  );
}
