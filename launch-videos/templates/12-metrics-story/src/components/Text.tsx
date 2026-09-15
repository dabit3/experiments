import React from "react";
import { color, fontMono, fontSans, sizes, track } from "../tokens";

type Base = {
  children: React.ReactNode;
  style?: React.CSSProperties;
};

/** Large tabular numeral (Inter Medium, tabular figures). */
export const Numeral: React.FC<Base & { size?: number; color?: string }> = ({
  children,
  size = 160,
  color: c = color.ink,
  style,
}) => (
  <div
    style={{
      fontFamily: fontSans,
      fontWeight: 500,
      fontSize: size,
      lineHeight: 1,
      letterSpacing: track.hero,
      fontVariantNumeric: "tabular-nums",
      fontFeatureSettings: '"tnum" 1',
      color: c,
      whiteSpace: "nowrap",
      ...style,
    }}
  >
    {children}
  </div>
);

/** Uppercase Geist Mono label. */
export const MonoLabel: React.FC<Base & { color?: string; size?: number }> = ({
  children,
  color: c = color.gray500,
  size = sizes.label,
  style,
}) => (
  <div
    style={{
      fontFamily: fontMono,
      fontWeight: 500,
      fontSize: size,
      lineHeight: 1.3,
      letterSpacing: track.caps,
      textTransform: "uppercase",
      color: c,
      fontVariantNumeric: "tabular-nums",
      whiteSpace: "nowrap",
      ...style,
    }}
  >
    {children}
  </div>
);

/** Narration line: Inter Medium, tight tracking. */
export const Narration: React.FC<Base & { size?: number; color?: string; maxWidth?: number }> = ({
  children,
  size = sizes.h3,
  color: c = color.ink,
  maxWidth = 820,
  style,
}) => (
  <div
    style={{
      fontFamily: fontSans,
      fontWeight: 500,
      fontSize: size,
      lineHeight: 1.15,
      letterSpacing: track.heading,
      color: c,
      maxWidth,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Heading: React.FC<Base & { size?: number; color?: string }> = ({
  children,
  size = sizes.h1,
  color: c = color.ink,
  style,
}) => (
  <div
    style={{
      fontFamily: fontSans,
      fontWeight: 500,
      fontSize: size,
      lineHeight: 1.05,
      letterSpacing: track.hero,
      color: c,
      ...style,
    }}
  >
    {children}
  </div>
);
