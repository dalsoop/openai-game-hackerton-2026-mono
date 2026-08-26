/**
 * Modal 컴포넌트
 * 화면 흐름 위에 떠서 사용자 결정을 요구하는 대화상자 — 연결 끊김 등 복구 불능 상태 전용.
 * 닫기(X)는 제공하지 않는다: 이 모달을 쓰는 상태는 선택지 없이 진행이 막혔기 때문.
 */
import type { ReactNode } from "react";

interface ModalProps {
  tone?: "error" | "info";
  children: ReactNode;
}

export function Modal({ tone = "info", children }: ModalProps): ReactNode {
  return (
    <div className={`modal-overlay${tone === "error" ? " error" : ""}`} role="dialog" aria-modal="true">
      <div className="modal-card">{children}</div>
    </div>
  );
}
