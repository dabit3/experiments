import React from "react";
import { Easing, interpolate, useCurrentFrame } from "remotion";
import { color, EASE_IN_OUT, EASE_OUT } from "../tokens";

type Pt = { x: number; y: number };

type Props = {
  /** Start / end positions in the parent's (source-image) pixel space. */
  from: Pt;
  to: Pt;
  /** Frame range of the move. */
  moveStart: number;
  moveEnd: number;
  /** Frame at which the click/tap ring fires (optional). */
  clickAt?: number;
  /** Pixel size of the arrow in source space (retina screenshots → ~2x). */
  size?: number;
};

/** macOS-style pointer with an optional tap ring, animated with ease-in-out. */
export const Cursor: React.FC<Props> = ({
  from,
  to,
  moveStart,
  moveEnd,
  clickAt,
  size = 44,
}) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [moveStart, moveEnd], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(...EASE_IN_OUT),
  });
  const x = from.x + (to.x - from.x) * p;
  const y = from.y + (to.y - from.y) * p;

  const ring =
    clickAt === undefined
      ? 0
      : interpolate(frame, [clickAt, clickAt + 12], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: Easing.bezier(...EASE_OUT),
        });
  const ringSize = size * 2.4 * ring;
  const ringOpacity = clickAt === undefined || frame < clickAt ? 0 : 1 - ring;

  return (
    <>
      {ringOpacity > 0 ? (
        <div
          style={{
            position: "absolute",
            left: x - ringSize / 2,
            top: y - ringSize / 2,
            width: ringSize,
            height: ringSize,
            borderRadius: 999,
            border: `${size / 10}px solid ${color.accent}`,
            opacity: ringOpacity,
          }}
        />
      ) : null}
      <svg
        width={size}
        height={size * 1.4}
        viewBox="0 0 20 28"
        style={{ position: "absolute", left: x, top: y, overflow: "visible" }}
      >
        <path
          d="M2 2 L2 22 L7.5 17 L11 25.5 L14.5 24 L11 16 L18 16 Z"
          fill={color.black}
          stroke={color.white}
          strokeWidth={1.6}
          strokeLinejoin="round"
        />
      </svg>
    </>
  );
};
