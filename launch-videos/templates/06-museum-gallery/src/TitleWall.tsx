import React from "react";
import { Img, staticFile } from "remotion";
import { Wall } from "./Wall";
import { enter } from "./motion";
import type { Brand, Content, Gallery } from "./schema";

type Props = {
  brand: Brand;
  content: Content;
  gallery: Gallery;
  localFrame: number;
};

const Headline: React.FC<{ text: string; accentWord?: string; accent: string }> = ({
  text,
  accentWord,
  accent,
}) => {
  if (!accentWord) return <>{text}</>;
  const idx = text.indexOf(accentWord);
  if (idx === -1) return <>{text}</>;
  return (
    <>
      {text.slice(0, idx)}
      <span style={{ color: accent }}>{accentWord}</span>
      {text.slice(idx + accentWord.length)}
    </>
  );
};

/** Entrance wall: lockup, eyebrow, headline and subhead set as gallery wall text. */
export const TitleWall: React.FC<Props> = ({ brand, content, gallery, localFrame }) => {
  const f = Math.max(0, localFrame);
  const a1 = enter(f, 0, 14);
  const a2 = enter(f, 8, 14);
  const a3 = enter(f, 18, 14);
  const rise = (a: number) => `translateY(${(1 - a) * 16}px)`;

  return (
    <Wall brand={brand} gallery={gallery}>
      <Img
        src={staticFile(brand.logoLight)}
        style={{
          position: "absolute",
          left: gallery.safeMargin,
          top: 84,
          height: 34,
          opacity: a1,
        }}
      />
      <div
        style={{
          position: "absolute",
          left: gallery.safeMargin,
          top: 372,
          width: 1200,
          color: brand.ink,
          fontFamily: brand.fontFamily,
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
            opacity: a1,
            transform: rise(a1),
            display: "flex",
            alignItems: "center",
            gap: 12,
          }}
        >
          <span style={{ width: 8, height: 8, borderRadius: 9999, backgroundColor: brand.accent }} />
          {content.eyebrow} · {content.featureName}
        </div>
        <div
          style={{
            marginTop: 28,
            fontSize: 88,
            lineHeight: "92px",
            letterSpacing: -3.3,
            fontWeight: 500,
            opacity: a2,
            transform: rise(a2),
          }}
        >
          <Headline
            text={content.headline}
            accentWord={content.headlineAccentWord}
            accent={brand.accent}
          />
        </div>
        <div
          style={{
            marginTop: 32,
            maxWidth: 900,
            fontSize: 27,
            lineHeight: "38px",
            letterSpacing: -0.4,
            color: brand.inkMuted,
            opacity: a3,
            transform: rise(a3),
          }}
        >
          {content.subhead}
        </div>
      </div>
      <div
        style={{
          position: "absolute",
          left: gallery.safeMargin,
          bottom: 48,
          fontFamily: brand.monoFontFamily,
          fontSize: 13,
          lineHeight: "19px",
          color: brand.inkSubtle,
          opacity: a3,
        }}
      >
        {content.stages.join("  →  ")}
      </div>
    </Wall>
  );
};
