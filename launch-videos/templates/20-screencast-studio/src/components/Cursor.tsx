import React from "react";
import { interpolate } from "remotion";
import { easeInOut, easeOut, progress } from "../anim";
import { CONTENT_H, sx, sy, WINDOW_W } from "../layout";
import { color } from "../tokens";

export type CursorKey = { frame: number; x: number; y: number; click?: boolean };

export type CursorState = {
  x: number;
  y: number;
  /** 0..1 press amount (peaks on click frame). */
  press: number;
  /** frames since the most recent click, or -1 */
  sinceClick: number;
};

/**
 * Interpolate a cursor along keyframes (fractions of the content area) with
 * ease-in-out between keys — the "cursor smoothing" of a screen recorder.
 */
export const cursorAt = (keys: CursorKey[], frame: number): CursorState => {
  let x = keys[0].x;
  let y = keys[0].y;
  for (let i = 0; i < keys.length - 1; i++) {
    const a = keys[i];
    const b = keys[i + 1];
    if (frame >= b.frame) {
      x = b.x;
      y = b.y;
      continue;
    }
    if (frame > a.frame) {
      const t = progress(frame, a.frame, b.frame, easeInOut);
      x = a.x + (b.x - a.x) * t;
      y = a.y + (b.y - a.y) * t;
    }
    break;
  }
  let sinceClick = -1;
  for (const k of keys) {
    if (k.click && frame >= k.frame) sinceClick = frame - k.frame;
  }
  const press =
    sinceClick < 0
      ? 0
      : interpolate(sinceClick, [0, 3, 10], [1, 1, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        });
  return { x, y, press, sinceClick };
};

const RIPPLE_FRAMES = 16;

/** macOS-style arrow pointer plus click ripple, drawn in content coordinates. */
export const Cursor: React.FC<{ state: CursorState; opacity?: number; zoom: number }> = ({
  state,
  opacity = 1,
  zoom,
}) => {
  const px = sx(state.x) * WINDOW_W;
  const py = sy(state.y) * CONTENT_H;
  // Keep the pointer roughly the same size on screen regardless of zoom.
  const size = 30 / Math.sqrt(zoom);
  const showRipple = state.sinceClick >= 0 && state.sinceClick < RIPPLE_FRAMES;
  const rp = progress(state.sinceClick, 0, RIPPLE_FRAMES, easeOut);
  const rippleR = 10 + rp * 34;
  const rippleO = (1 - rp) * 0.55;
  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width: WINDOW_W,
        height: CONTENT_H,
        pointerEvents: "none",
        opacity,
      }}
    >
      {showRipple && (
        <div
          style={{
            position: "absolute",
            left: px - rippleR,
            top: py - rippleR,
            width: rippleR * 2,
            height: rippleR * 2,
            borderRadius: 999,
            border: `2px solid ${color.accent}`,
            opacity: rippleO,
          }}
        />
      )}
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        style={{
          position: "absolute",
          left: px - size * (5.5 / 24),
          top: py - size * (2.9 / 24),
          transform: `scale(${1 - state.press * 0.1})`,
          transformOrigin: `${(5.5 / 24) * 100}% ${(2.9 / 24) * 100}%`,
          filter: "drop-shadow(0 1px 2px rgba(0,0,0,0.35))",
        }}
      >
        <path
          d="M5.5 3.21V20.8c0 .45.54.67.85.35l4.86-4.86a.5.5 0 0 1 .35-.15h6.87c.45 0 .67-.54.35-.85L6.35 2.86a.5.5 0 0 0-.85.35Z"
          fill={color.ink}
          stroke={color.white}
          strokeWidth={1.4}
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};
