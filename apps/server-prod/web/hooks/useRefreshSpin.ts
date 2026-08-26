"use client";
// Refresh icon: spin clockwise while the request is in flight, then finish the current turn so it lands upright.
import { useState } from "react";

export function useRefreshSpin(refreshing: boolean): {
  className: string;
  onAnimationIteration: () => void;
} {
  const [spinning, setSpinning] = useState(refreshing);

  if (refreshing && !spinning) {
    setSpinning(true);
  }

  const finishing = spinning && !refreshing;

  return {
    className: spinning ? "refresh-icon-box refresh-spin" : "refresh-icon-box",
    onAnimationIteration: (): void => {
      if (!finishing) {return;}
      setSpinning(false);
    },
  };
}
