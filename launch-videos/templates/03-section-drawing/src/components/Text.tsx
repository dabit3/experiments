import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand } from "../schema";

export const Eyebrow: React.FC<{ brand: Brand; children: React.ReactNode; style?: React.CSSProperties }> = ({
  brand,
  children,
  style,
}) => (
  <div
    style={{
      fontFamily: brand.fontFamily,
      fontSize: 14,
      lineHeight: "20px",
      letterSpacing: 0.4,
      textTransform: "uppercase",
      fontWeight: 500,
      color: brand.inkMuted,
      ...style,
    }}
  >
    {children}
  </div>
);

/** Headline with one accent phrase (brand rule: a single accent word/phrase). */
export const Headline: React.FC<{
  brand: Brand;
  text: string;
  accent: string;
  size?: number;
  style?: React.CSSProperties;
}> = ({ brand, text, accent, size = 84, style }) => {
  const idx = accent ? text.indexOf(accent) : -1;
  const parts =
    idx >= 0
      ? [text.slice(0, idx), text.slice(idx, idx + accent.length), text.slice(idx + accent.length)]
      : [text, "", ""];
  return (
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontWeight: 500,
        fontSize: size,
        lineHeight: 1,
        letterSpacing: -size * 0.038,
        color: brand.ink,
        ...style,
      }}
    >
      {parts[0]}
      {parts[1] ? <span style={{ color: brand.accent }}>{parts[1]}</span> : null}
      {parts[2]}
    </div>
  );
};

export const Body: React.FC<{
  brand: Brand;
  children: React.ReactNode;
  size?: number;
  color?: string;
  style?: React.CSSProperties;
}> = ({ brand, children, size = 27, color, style }) => (
  <div
    style={{
      fontFamily: brand.fontFamily,
      fontWeight: 400,
      fontSize: size,
      lineHeight: 1.3,
      letterSpacing: -size * 0.015,
      color: color ?? brand.ink,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Mono: React.FC<{
  brand: Brand;
  children: React.ReactNode;
  size?: number;
  color?: string;
  style?: React.CSSProperties;
}> = ({ brand, children, size = 12, color, style }) => (
  <div
    style={{
      fontFamily: brand.monoFontFamily,
      fontSize: size,
      lineHeight: 1.4,
      letterSpacing: 0.28,
      textTransform: "uppercase",
      color: color ?? brand.inkMuted,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Logo: React.FC<{ brand: Brand; height?: number; style?: React.CSSProperties }> = ({
  brand,
  height = 32,
  style,
}) => (
  <Img
    src={staticFile(brand.logoLight)}
    style={{ height, width: height * (2984 / 1024), display: "block", ...style }}
  />
);

/** Reveals children through a precise rectangular mask (left-to-right or top-to-bottom). */
export const MaskReveal: React.FC<{
  progress: number;
  direction?: "right" | "down";
  children: React.ReactNode;
  style?: React.CSSProperties;
}> = ({ progress, direction = "right", children, style }) => {
  const p = Math.max(0, Math.min(1, progress));
  const inset =
    direction === "right"
      ? `inset(0 ${(1 - p) * 100}% 0 0)`
      : `inset(0 0 ${(1 - p) * 100}% 0)`;
  return <div style={{ clipPath: inset, ...style }}>{children}</div>;
};
