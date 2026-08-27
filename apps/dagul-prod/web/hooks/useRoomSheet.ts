import { useEffect, useState } from "react";

export type RoomSheetKind = "pin" | "share" | "game";

export function useRoomSheet(): {
  kind: RoomSheetKind | null;
  open: (kind: RoomSheetKind) => void;
  close: () => void;
} {
  const [kind, setKind] = useState<RoomSheetKind | null>(null);
  useEffect(() => {
    if (!kind) {return;}
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === "Escape") {setKind(null);}
    };
    window.addEventListener("keydown", onKey);
    return (): void => {window.removeEventListener("keydown", onKey);};
  }, [kind]);
  return {
    kind,
    open: (next: RoomSheetKind): void => {setKind(next);},
    close: (): void => {setKind(null);},
  };
}
