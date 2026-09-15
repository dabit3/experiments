import React from "react";
import { MONO, SANS } from "../fonts";
import { color, type } from "../tokens";

const sizes = {
  hero: 144,
  h1: 104,
  h2: 72,
  h3: 52,
  body: 36,
  label: 24,
};

type TextProps = {
  children: React.ReactNode;
  style?: React.CSSProperties;
};

export const Headline: React.FC<TextProps & { size?: "hero" | "h1" | "h2" | "h3" }> = ({
  children,
  size = "h1",
  style,
}) => (
  <div
    style={{
      fontFamily: SANS,
      fontWeight: type.weights.medium,
      fontSize: sizes[size],
      lineHeight: type.leading.heading,
      letterSpacing: size === "hero" ? type.tracking.hero : type.tracking.heading,
      color: color.ink,
      margin: 0,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Body: React.FC<TextProps> = ({ children, style }) => (
  <div
    style={{
      fontFamily: SANS,
      fontWeight: type.weights.regular,
      fontSize: sizes.body,
      lineHeight: type.leading.body,
      letterSpacing: type.tracking.body,
      color: color.warmGray,
      margin: 0,
      ...style,
    }}
  >
    {children}
  </div>
);

export const Label: React.FC<TextProps> = ({ children, style }) => (
  <div
    style={{
      fontFamily: MONO,
      fontWeight: type.weights.regular,
      fontSize: sizes.label,
      lineHeight: 1,
      letterSpacing: type.tracking.caps,
      textTransform: "uppercase",
      color: color.warmGray,
      margin: 0,
      ...style,
    }}
  >
    {children}
  </div>
);
