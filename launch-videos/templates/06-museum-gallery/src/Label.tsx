import React from "react";
import type { Brand } from "./schema";

type Props = {
  brand: Brand;
  width: number;
  eyebrow: string;
  title: string;
  caption: string;
  meta: string;
  style?: React.CSSProperties;
};

/** Exhibition-style wall label: number + stage, work title, one-sentence caption, medium. */
export const Label: React.FC<Props> = ({ brand, width, eyebrow, title, caption, meta, style }) => {
  return (
    <div
      style={{
        position: "absolute",
        width,
        display: "flex",
        flexDirection: "column",
        gap: 16,
        color: brand.ink,
        fontFamily: brand.fontFamily,
        ...style,
      }}
    >
      <div
        style={{
          fontFamily: brand.monoFontFamily,
          fontSize: 14,
          lineHeight: "20px",
          letterSpacing: 0.6,
          textTransform: "uppercase",
          color: brand.inkMuted,
          fontWeight: 500,
        }}
      >
        {eyebrow}
      </div>
      <div
        style={{
          width: 32,
          height: 2,
          backgroundColor: brand.accent,
        }}
      />
      <div
        style={{
          fontSize: 27,
          lineHeight: "34px",
          letterSpacing: -0.5,
          fontWeight: 500,
        }}
      >
        {title}
      </div>
      <div
        style={{
          fontSize: 20,
          lineHeight: "28px",
          letterSpacing: -0.3,
          fontWeight: 400,
          color: brand.ink,
        }}
      >
        {caption}
      </div>
      <div
        style={{
          fontFamily: brand.monoFontFamily,
          fontSize: 13,
          lineHeight: "19px",
          color: brand.inkSubtle,
          marginTop: 8,
        }}
      >
        {meta}
      </div>
    </div>
  );
};
