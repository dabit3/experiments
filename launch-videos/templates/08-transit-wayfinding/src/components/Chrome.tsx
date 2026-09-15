import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand, Content } from "../schema";
import { SAFE, TYPE, WIDTH } from "../geometry";

// Persistent top bar: lockup on the left, eyebrow + feature name on the right.
export const TopBar: React.FC<{ brand: Brand; content: Content; opacity?: number }> = ({ brand, content, opacity = 1 }) => {
  return (
    <div style={{ position: "absolute", left: SAFE, right: SAFE, top: 56, height: 40, opacity }}>
      <Img src={staticFile(brand.logoLight)} style={{ height: 40, position: "absolute", left: 0, top: 0 }} />
      <div
        style={{
          position: "absolute",
          right: 0,
          top: 4,
          display: "flex",
          alignItems: "center",
          gap: 12,
          fontFamily: brand.fontFamily,
        }}
      >
        <span
          style={{
            padding: "5px 12px",
            borderRadius: 9999,
            background: brand.accent,
            color: brand.white,
            fontSize: TYPE.eyebrow.size,
            letterSpacing: TYPE.eyebrow.tracking,
            textTransform: "uppercase",
            fontWeight: 500,
            lineHeight: 1.3,
          }}
        >
          {content.eyebrow}
        </span>
        <span style={{ fontSize: TYPE.label.size, letterSpacing: TYPE.label.tracking, color: brand.inkMuted }}>
          {content.featureName}
        </span>
      </div>
    </div>
  );
};

// Directional wipe: content is revealed left -> right, in the direction of travel.
export const Wipe: React.FC<{ t: number; children: React.ReactNode; style?: React.CSSProperties }> = ({ t, children, style }) => {
  const pct = Math.round((1 - Math.min(1, Math.max(0, t))) * 1000) / 10;
  return <div style={{ clipPath: `inset(0 ${pct}% 0 0)`, ...style }}>{children}</div>;
};

export const Headline: React.FC<{ brand: Brand; text: string; accentWord?: string; size?: number; style?: React.CSSProperties }> = ({
  brand,
  text,
  accentWord,
  size = TYPE.display.size,
  style,
}) => {
  const words = text.split(" ");
  let done = false;
  return (
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontSize: size,
        lineHeight: TYPE.display.lineHeight,
        letterSpacing: (TYPE.display.tracking * size) / TYPE.display.size,
        fontWeight: 500,
        color: brand.ink,
        maxWidth: WIDTH - SAFE * 2,
        ...style,
      }}
    >
      {words.map((w, i) => {
        const isAccent = !done && accentWord !== undefined && w.replace(/[^\w]/g, "") === accentWord;
        if (isAccent) {
          done = true;
        }
        return (
          <span key={`${w}-${i}`} style={{ color: isAccent ? brand.accent : undefined }}>
            {w}
            {i < words.length - 1 ? " " : ""}
          </span>
        );
      })}
    </div>
  );
};
