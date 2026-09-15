import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import { WIPE, WipeDirection } from "../scenes";
import { color, easeInOut } from "../theme";

/**
 * Hard geometric wipe: the children are revealed by a straight edge sweeping across the frame.
 * A thin accent rule rides the leading edge.
 */
export const Wipe: React.FC<{
  direction: WipeDirection;
  enabled: boolean;
  children: React.ReactNode;
}> = ({ direction, enabled, children }) => {
  const frame = useCurrentFrame();
  const p = enabled
    ? interpolate(frame, [0, WIPE], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeInOut,
      })
    : 1;
  const hidden = `${(1 - p) * 100}%`;
  const clipPath = {
    right: `inset(0 ${hidden} 0 0)`,
    left: `inset(0 0 0 ${hidden})`,
    down: `inset(0 0 ${hidden} 0)`,
    up: `inset(${hidden} 0 0 0)`,
  }[direction];

  const horizontal = direction === "left" || direction === "right";
  const edgePos = `${p * 100}%`;
  const edgeStyle: React.CSSProperties = horizontal
    ? {
        top: 0,
        bottom: 0,
        width: 6,
        [direction === "right" ? "left" : "right"]: edgePos,
        transform: direction === "right" ? "translateX(-6px)" : "translateX(6px)",
      }
    : {
        left: 0,
        right: 0,
        height: 6,
        [direction === "down" ? "top" : "bottom"]: edgePos,
        transform: direction === "down" ? "translateY(-6px)" : "translateY(6px)",
      };

  return (
    <AbsoluteFill style={{ clipPath }}>
      {children}
      {p < 1 && p > 0 ? (
        <div style={{ position: "absolute", background: color.accent, ...edgeStyle }} />
      ) : null}
    </AbsoluteFill>
  );
};
