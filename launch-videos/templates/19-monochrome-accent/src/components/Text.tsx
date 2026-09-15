import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { MONO, SANS } from "../fonts";
import { easeIn, easeOut, Palette, size, tracking, color } from "../theme";

type Reveal = {
  /** Frame (relative to the scene) at which the element starts entering. */
  at?: number;
  /** Frame at which the element starts leaving. Omit to keep it on screen. */
  until?: number;
  /** Entrance offset in px (slides up). */
  rise?: number;
};

/** Fade + slide-up entrance (ease-out), fade exit (ease-in). */
export const useReveal = ({ at = 0, until, rise = 28 }: Reveal) => {
  const frame = useCurrentFrame();
  const inP = interpolate(frame, [at, at + 20], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  const outP =
    until === undefined
      ? 0
      : interpolate(frame, [until, until + 12], [0, 1], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
          easing: easeIn,
        });
  return {
    opacity: inP * (1 - outP),
    transform: `translateY(${(1 - inP) * rise}px)`,
  };
};

export const Headline: React.FC<
  Reveal & {
    palette: Palette;
    fontSize?: number;
    children: React.ReactNode;
    style?: React.CSSProperties;
  }
> = ({ palette, fontSize = size.h1, children, style, ...reveal }) => {
  const anim = useReveal(reveal);
  return (
    <div
      style={{
        fontFamily: SANS,
        fontWeight: 500,
        fontSize,
        lineHeight: 1.04,
        letterSpacing: tracking.heading,
        color: palette.fg,
        margin: 0,
        ...anim,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

export const Body: React.FC<
  Reveal & { palette: Palette; children: React.ReactNode; style?: React.CSSProperties }
> = ({ palette, children, style, ...reveal }) => {
  const anim = useReveal(reveal);
  return (
    <div
      style={{
        fontFamily: SANS,
        fontWeight: 400,
        fontSize: size.h3,
        lineHeight: 1.2,
        letterSpacing: tracking.body,
        color: palette.muted,
        ...anim,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/** Small uppercase mono label, e.g. "01 / CHOOSE MACOS". */
export const Label: React.FC<
  Reveal & { palette: Palette; children: React.ReactNode; style?: React.CSSProperties }
> = ({ palette, children, style, ...reveal }) => {
  const anim = useReveal({ rise: 12, ...reveal });
  return (
    <div
      style={{
        fontFamily: MONO,
        fontWeight: 500,
        fontSize: size.label,
        lineHeight: 1,
        letterSpacing: tracking.caps,
        textTransform: "uppercase",
        color: palette.muted,
        display: "flex",
        alignItems: "center",
        gap: 14,
        ...anim,
        ...style,
      }}
    >
      <span style={{ width: 10, height: 10, background: color.accent, display: "inline-block" }} />
      {children}
    </div>
  );
};

export const Accent: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <span style={{ color: color.accent }}>{children}</span>
);
