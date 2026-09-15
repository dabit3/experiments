import React from "react";
import type { Brand } from "../schema";

type Props = {
  brand: Brand;
  left: string;
  right?: string;
  safeMargin: number;
  opacity?: number;
};

export const Header: React.FC<Props> = ({ brand, left, right, safeMargin, opacity = 1 }) => {
  return (
    <div
      style={{
        position: "absolute",
        top: safeMargin * 0.5,
        left: safeMargin,
        right: safeMargin,
        display: "flex",
        justifyContent: "space-between",
        fontFamily: brand.monoFontFamily,
        fontSize: 16,
        lineHeight: "20px",
        letterSpacing: 0.2,
        color: brand.inkSubtle,
        opacity,
      }}
    >
      <span>{left}</span>
      {right ? <span>{right}</span> : null}
    </div>
  );
};
