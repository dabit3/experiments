import React from "react";
import { useCurrentFrame } from "remotion";
import { enter } from "../motion";

type Props = {
  durationInFrames: number;
  /** Frame (within the scene) at which the wipe begins; usually 0. */
  from?: number;
  direction?: "left" | "right" | "down";
  children: React.ReactNode;
};

/**
 * Reveals its children with a crisp hard-edged wipe. Scenes are layered so the
 * previous scene stays fully visible underneath while the new one wipes in.
 */
export const Wipe: React.FC<Props> = ({
  durationInFrames,
  from = 0,
  direction = "right",
  children,
}) => {
  const frame = useCurrentFrame();
  const p = enter(frame, from, durationInFrames);
  const pct = (1 - p) * 100;
  const clipPath =
    direction === "right"
      ? `inset(0 ${pct}% 0 0)`
      : direction === "left"
        ? `inset(0 0 0 ${pct}%)`
        : `inset(0 0 ${pct}% 0)`;
  return (
    <div style={{ position: "absolute", inset: 0, clipPath }}>{children}</div>
  );
};
