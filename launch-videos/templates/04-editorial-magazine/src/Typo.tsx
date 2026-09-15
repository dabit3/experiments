import React from "react";
import {
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import type { Brand, LayoutTokens, TypeScale } from "./schema";

export type Theme = {
  brand: Brand;
  tokens: LayoutTokens;
  type: TypeScale;
};

const easeOut = Easing.out(Easing.cubic);
const easeInOut = Easing.inOut(Easing.cubic);

/** Ease-out entrance: fade + 16px rise. `delay` staggers blocks. */
export const Enter: React.FC<{
  frames: number;
  delay?: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ frames, delay = 0, children, style }) => {
  const frame = useCurrentFrame();
  const t = interpolate(frame, [delay, delay + frames], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeOut,
  });
  return (
    <div
      style={{
        opacity: t,
        transform: `translateY(${(1 - t) * 16}px)`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

/** Brief horizontal reveal (left→right clip). Used as the "wipe" transition. */
export const Reveal: React.FC<{
  frames: number;
  enabled: boolean;
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ frames, enabled, children, style }) => {
  const frame = useCurrentFrame();
  const t = enabled
    ? interpolate(frame, [0, frames], [0, 1], {
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
        easing: easeInOut,
      })
    : 1;
  return (
    <div style={{ clipPath: `inset(0 ${(1 - t) * 100}% 0 0)`, ...style }}>
      {children}
    </div>
  );
};

export const Eyebrow: React.FC<{
  theme: Theme;
  children: React.ReactNode;
  color?: string;
}> = ({ theme, children, color }) => (
  <div
    style={{
      fontFamily: theme.brand.monoFontFamily,
      fontSize: theme.type.eyebrow,
      lineHeight: 1.4,
      letterSpacing: "0.08em",
      textTransform: "uppercase",
      fontWeight: 500,
      color: color ?? theme.brand.inkMuted,
    }}
  >
    {children}
  </div>
);

/** Headline with one accent word (first occurrence). */
export const Headline: React.FC<{
  theme: Theme;
  text: string;
  accentWord?: string;
  size: number;
  maxWidth?: number;
  color?: string;
}> = ({ theme, text, accentWord, size, maxWidth, color }) => {
  const idx = accentWord ? text.indexOf(accentWord) : -1;
  const parts =
    idx >= 0 && accentWord
      ? [text.slice(0, idx), accentWord, text.slice(idx + accentWord.length)]
      : [text, "", ""];
  return (
    <div
      style={{
        fontFamily: theme.brand.fontFamily,
        fontWeight: 500,
        fontSize: size,
        lineHeight: 0.98,
        letterSpacing: -0.038 * size,
        color: color ?? theme.brand.ink,
        maxWidth,
      }}
    >
      {parts[0]}
      {parts[1] ? (
        <span style={{ color: theme.brand.accent, whiteSpace: "nowrap" }}>
          {parts[1]}
        </span>
      ) : null}
      {parts[2]}
    </div>
  );
};

export const CaptionHeading: React.FC<{
  theme: Theme;
  children: React.ReactNode;
  size?: number;
  maxWidth?: number;
  color?: string;
}> = ({ theme, children, size, maxWidth, color }) => {
  const s = size ?? theme.type.heading;
  return (
    <div
      style={{
        fontFamily: theme.brand.fontFamily,
        fontWeight: 500,
        fontSize: s,
        lineHeight: 1.15,
        letterSpacing: -0.02 * s,
        color: color ?? theme.brand.ink,
        maxWidth,
      }}
    >
      {children}
    </div>
  );
};

export const Body: React.FC<{
  theme: Theme;
  children: React.ReactNode;
  size?: number;
  maxWidth?: number;
  color?: string;
}> = ({ theme, children, size, maxWidth, color }) => {
  const s = size ?? theme.type.body;
  return (
    <div
      style={{
        fontFamily: theme.brand.fontFamily,
        fontWeight: 400,
        fontSize: s,
        lineHeight: 1.4,
        letterSpacing: -0.012 * s,
        color: color ?? theme.brand.inkMuted,
        maxWidth,
      }}
    >
      {children}
    </div>
  );
};

/** Oversized word that lives in the margin; clipped by the frame, never over media. */
export const MarginWord: React.FC<{
  theme: Theme;
  word: string;
  style?: React.CSSProperties;
  color?: string;
}> = ({ theme, word, style, color }) => (
  <div
    style={{
      position: "absolute",
      fontFamily: theme.brand.fontFamily,
      fontWeight: 500,
      fontSize: theme.type.marginWord,
      lineHeight: 0.9,
      letterSpacing: -0.05 * theme.type.marginWord,
      color: color ?? theme.brand.ink,
      whiteSpace: "nowrap",
      pointerEvents: "none",
      ...style,
    }}
  >
    {word}
  </div>
);

/** Small hairline rule; accent only when asked. */
export const Rule: React.FC<{
  theme: Theme;
  width: number;
  accent?: boolean;
}> = ({ theme, width, accent }) => (
  <div
    style={{
      width,
      height: accent ? 2 : 1,
      background: accent ? theme.brand.accent : theme.brand.line,
    }}
  />
);

/** Running head + page number, the same on every page. */
export const Folio: React.FC<{
  theme: Theme;
  page: number;
  total: number;
  left: string;
  dark?: boolean;
}> = ({ theme, page, total, left, dark }) => {
  const { margin, showRunningHead, showPageNumbers, logoHeight } = theme.tokens;
  const color = dark ? theme.brand.white : theme.brand.ink;
  const muted = dark ? theme.brand.inkSubtle : theme.brand.inkMuted;
  return (
    <>
      <Img
        src={staticFile(dark ? theme.brand.logoDark : theme.brand.logoLight)}
        style={{
          position: "absolute",
          left: margin,
          top: 40,
          height: logoHeight,
        }}
      />
      {showRunningHead ? (
        <div
          style={{
            position: "absolute",
            right: margin,
            top: 48,
            fontFamily: theme.brand.monoFontFamily,
            fontSize: theme.type.eyebrow,
            letterSpacing: "0.06em",
            textTransform: "uppercase",
            color: muted,
          }}
        >
          {left}
        </div>
      ) : null}
      {showPageNumbers ? (
        <div
          style={{
            position: "absolute",
            right: margin,
            bottom: 44,
            fontFamily: theme.brand.monoFontFamily,
            fontSize: theme.type.eyebrow,
            letterSpacing: "0.06em",
            color,
          }}
        >
          {String(page).padStart(2, "0")}
          <span style={{ color: muted }}>
            {" "}
            / {String(total).padStart(2, "0")}
          </span>
        </div>
      ) : null}
    </>
  );
};

export const SpeedBadge: React.FC<{ theme: Theme; label: string }> = ({
  theme,
  label,
}) => (
  <div
    style={{
      position: "absolute",
      right: 16,
      top: 16,
      padding: "6px 10px",
      borderRadius: 8,
      background: theme.brand.ink,
      color: theme.brand.white,
      fontFamily: theme.brand.monoFontFamily,
      fontSize: theme.type.small,
      fontWeight: 500,
    }}
  >
    {label}
  </div>
);

export const Button: React.FC<{
  theme: Theme;
  label: string;
  dark?: boolean;
}> = ({ theme, label, dark }) => (
  <div
    style={{
      display: "inline-flex",
      alignItems: "center",
      height: 52,
      padding: "0 22px",
      borderRadius: 2,
      background: dark ? theme.brand.white : theme.brand.ink,
      color: dark ? theme.brand.ink : theme.brand.white,
      fontFamily: theme.brand.fontFamily,
      fontSize: 22,
      fontWeight: 500,
      letterSpacing: -0.3,
    }}
  >
    {label}
  </div>
);
