"use client";
import type { JSX, ReactNode } from "react";
import { MaterialIcon } from "@/components/MaterialIcon";

interface Props {
  labelledBy: string;
  closeLabel: string;
  onClose: () => void;
  children: ReactNode;
}

export default function RoomSheet({ labelledBy, closeLabel, onClose, children }: Props): JSX.Element {
  return (
    <div className="room-sheet" role="dialog" aria-modal="true" aria-labelledby={labelledBy}>
      <button type="button" className="room-sheet-backdrop" aria-label={closeLabel} onClick={onClose} />
      <div className="room-sheet-card">
        <button type="button" className="ghost btn-icon room-sheet-close" onClick={onClose} aria-label={closeLabel}>
          <MaterialIcon name="close" />
        </button>
        {children}
      </div>
    </div>
  );
}
