import React from "react";
import type { Brand, Content } from "../schema";
import { CONTENT_H, CONTENT_TOP, MARGIN, colW } from "../defaults";

const Accented: React.FC<{
  text: string;
  accentWord: string;
  accent: string;
}> = ({ text, accentWord, accent }) => {
  if (!accentWord || !text.includes(accentWord)) return <>{text}</>;
  const i = text.indexOf(accentWord);
  return (
    <>
      {text.slice(0, i)}
      <span style={{ color: accent }}>{accentWord}</span>
      {text.slice(i + accentWord.length)}
    </>
  );
};

/** Title block in the left half of the content box. */
export const Title: React.FC<{
  brand: Brand;
  content: Content;
  progress: number;
  exit: number;
}> = ({ brand, content, progress, exit }) => {
  const opacity = progress * (1 - exit);
  const rise = (1 - progress) * 16;
  return (
    <div
      style={{
        position: "absolute",
        left: MARGIN,
        top: CONTENT_TOP,
        width: colW(6),
        height: CONTENT_H,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 28,
        opacity,
        transform: `translateY(${rise}px)`,
      }}
    >
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 14,
          lineHeight: "20px",
          letterSpacing: 0.4,
          textTransform: "uppercase",
          fontWeight: 500,
          color: brand.inkMuted,
        }}
      >
        {content.eyebrow} · {content.featureName}
      </div>
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 76,
          lineHeight: "78px",
          letterSpacing: -2.8,
          fontWeight: 500,
          color: brand.ink,
          maxWidth: 720,
        }}
      >
        <Accented
          text={content.headline}
          accentWord={content.headlineAccent}
          accent={brand.accent}
        />
      </div>
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 27,
          lineHeight: "38px",
          letterSpacing: -0.4,
          color: brand.inkMuted,
          maxWidth: 760,
        }}
      >
        {content.subhead}
      </div>
    </div>
  );
};
