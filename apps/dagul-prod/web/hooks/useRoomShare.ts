import { useEffect, useState } from "react";
import { buildRoomShareUrl } from "@/lib/hub/room-link";

export function useRoomShare(roomId: string, password: string): {
  url: string;
  svg: string;
  copied: boolean;
  copy: () => void;
} {
  const url = typeof window === "undefined"
    ? ""
    : buildRoomShareUrl(window.location.origin, { roomId, password });
  const [svg, setSvg] = useState("");
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!url) {return;}
    let alive = true;
    void import("qrcode")
      .then((qr): Promise<string> => qr.toString(url, { type: "svg", margin: 1, width: 168 }))
      .then((out: string): void => {if (alive) {setSvg(out);}})
      .catch((): void => {if (alive) {setSvg("");}});
    return (): void => {alive = false;};
  }, [url]);

  return {
    url,
    svg,
    copied,
    copy: (): void => {
      void navigator.clipboard.writeText(url).then(() => {
        setCopied(true);
        window.setTimeout(() => {setCopied(false);}, 1500);
      });
    },
  };
}
