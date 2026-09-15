import React from "react";
import type { Rect } from "../layout";
import type { Brand } from "../schema";

type Props = {
  rect: Rect;
  brand: Brand;
  radius: number;
  /** Accent hairline marks the current point of attention. */
  emphasis?: boolean;
  opacity?: number;
  children?: React.ReactNode;
};

export const Panel: React.FC<Props> = ({
  rect,
  brand,
  radius,
  emphasis = false,
  opacity = 1,
  children,
}) => {
  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        borderRadius: radius,
        background: brand.blackRaised,
        boxShadow: `inset 0 0 0 1px ${emphasis ? brand.accent : brand.consoleLine}`,
        overflow: "hidden",
        opacity,
      }}
    >
      {children}
    </div>
  );
};

type LabelProps = {
  brand: Brand;
  children: React.ReactNode;
  color?: string;
  size?: number;
};

/** Mono, uppercase, tracked label used for every console annotation. */
export const MonoLabel: React.FC<LabelProps> = ({ brand, children, color, size = 13 }) => (
  <span
    style={{
      fontFamily: brand.monoFontFamily,
      fontSize: size,
      lineHeight: 1,
      letterSpacing: size * 0.08,
      textTransform: "uppercase",
      color: color ?? brand.inkSubtle,
      whiteSpace: "nowrap",
    }}
  >
    {children}
  </span>
);
