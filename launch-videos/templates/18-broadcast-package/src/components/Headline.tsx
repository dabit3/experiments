import React from "react";
import type { Brand } from "../schema";

type Props = {
  brand: Brand;
  text: string;
  accent: string;
  color: string;
  style: React.CSSProperties;
};

/** Headline with an optional accent-colored substring. */
export const Headline: React.FC<Props> = ({ brand, text, accent, color, style }) => {
  const i = accent ? text.indexOf(accent) : -1;
  return (
    <div style={{ fontFamily: brand.fontFamily, color, ...style }}>
      {i < 0 ? (
        text
      ) : (
        <>
          {text.slice(0, i)}
          <span style={{ color: brand.accent }}>{accent}</span>
          {text.slice(i + accent.length)}
        </>
      )}
    </div>
  );
};
