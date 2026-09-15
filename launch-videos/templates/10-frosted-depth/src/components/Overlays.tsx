import React from "react";
import { useCurrentFrame } from "remotion";
import { color, fontSans } from "../tokens";
import { enter, linear, move } from "../lib/motion";

/** Positions are fractions of the shot window (0..1). */
type Frac = { x: number; y: number };

const pct = (v: number) => `${v * 100}%`;

/** macOS-style pointer that eases from `from` to `to` between frames [f0, f1], then clicks at `clickAt`. */
export const Cursor: React.FC<{ from: Frac; to: Frac; f0: number; f1: number; clickAt?: number; appearAt?: number }> = ({
  from,
  to,
  f0,
  f1,
  clickAt,
  appearAt = f0 - 8,
}) => {
  const frame = useCurrentFrame();
  const x = move(frame, f0, f1, from.x, to.x);
  const y = move(frame, f0, f1, from.y, to.y);
  const opacity = enter(frame, appearAt, 8);
  const ripple = clickAt === undefined ? 0 : linear(frame, clickAt, clickAt + 16);
  const pressed = clickAt !== undefined && frame >= clickAt && frame < clickAt + 6;
  return (
    <div style={{ position: "absolute", left: pct(x), top: pct(y), opacity, transform: `scale(${pressed ? 0.9 : 1})` }}>
      {ripple > 0 && ripple < 1 && (
        <div
          style={{
            position: "absolute",
            left: -22 + 4,
            top: -22 + 4,
            width: 44,
            height: 44,
            borderRadius: 999,
            border: `2px solid ${color.accent}`,
            opacity: (1 - ripple) * 0.8,
            transform: `scale(${0.3 + ripple * 0.9})`,
          }}
        />
      )}
      <svg width="26" height="32" viewBox="0 0 26 32" style={{ display: "block", filter: "drop-shadow(1px 2px 2px rgba(0,0,0,0.35))" }}>
        <path
          d="M2 2 L2 24 L8.5 18.5 L13 29 L17.5 27 L13 16.5 L22 16.5 Z"
          fill="#000"
          stroke="#fff"
          strokeWidth="1.6"
          strokeLinejoin="round"
        />
      </svg>
    </div>
  );
};

/**
 * Types `text` over a screenshot's prompt field. A white plate hides the placeholder underneath.
 * Sizes are in fractions of the shot window so the overlay scales with the image.
 */
export const TypedPrompt: React.FC<{
  at: Frac;
  plateWidth: number;
  plateHeight: number;
  text: string;
  f0: number;
  f1: number;
  fontSize: number;
}> = ({ at, plateWidth, plateHeight, text, f0, f1, fontSize }) => {
  const frame = useCurrentFrame();
  const t = linear(frame, f0, f1);
  const n = Math.round(t * text.length);
  const shown = text.slice(0, n);
  const caretOn = Math.floor(frame / 15) % 2 === 0 && frame >= f0 - 20;
  return (
    <div
      style={{
        position: "absolute",
        left: pct(at.x),
        top: pct(at.y),
        width: pct(plateWidth),
        height: pct(plateHeight),
        background: color.white,
        display: "flex",
        alignItems: "center",
        fontFamily: fontSans,
        fontSize,
        fontWeight: 400,
        letterSpacing: "-0.01em",
        color: color.ink,
        whiteSpace: "nowrap",
      }}
    >
      {shown}
      <span
        style={{
          display: "inline-block",
          width: 2,
          height: fontSize * 1.15,
          marginLeft: 2,
          background: color.ink,
          opacity: caretOn ? 1 : 0,
        }}
      />
    </div>
  );
};

/** Expanding tap ring for "Devin taps the Simulator" beats. */
export const Tap: React.FC<{ at: Frac; f0: number }> = ({ at, f0 }) => {
  const frame = useCurrentFrame();
  const t = linear(frame, f0, f0 + 20);
  if (t <= 0 || t >= 1) return null;
  return (
    <div
      style={{
        position: "absolute",
        left: pct(at.x),
        top: pct(at.y),
        width: 60,
        height: 60,
        marginLeft: -30,
        marginTop: -30,
        borderRadius: 999,
        border: `3px solid ${color.accent}`,
        background: `rgba(34,0,255,${0.25 * (1 - t)})`,
        opacity: 1 - t,
        transform: `scale(${0.35 + t})`,
      }}
    />
  );
};
