import React from "react";
import { Img } from "remotion";
import type { Brand, Content, Layout } from "./schema";

type Column = { x: number; y: number; w: number; h: number };

const type = {
  eyebrow: (brand: Brand): React.CSSProperties => ({
    fontFamily: brand.monoFontFamily,
    fontSize: 14,
    lineHeight: "20px",
    letterSpacing: 0.6,
    textTransform: "uppercase",
    color: brand.inkMuted,
    fontWeight: 500,
  }),
  headline: (brand: Brand): React.CSSProperties => ({
    fontFamily: brand.fontFamily,
    fontSize: 64,
    lineHeight: "70px",
    letterSpacing: -2.3,
    color: brand.ink,
    fontWeight: 500,
  }),
  subhead: (brand: Brand): React.CSSProperties => ({
    fontFamily: brand.fontFamily,
    fontSize: 24,
    lineHeight: "32px",
    letterSpacing: -0.3,
    color: brand.inkMuted,
    fontWeight: 400,
  }),
  caption: (brand: Brand): React.CSSProperties => ({
    fontFamily: brand.fontFamily,
    fontSize: 34,
    lineHeight: "42px",
    letterSpacing: -0.5,
    color: brand.ink,
    fontWeight: 500,
  }),
  label: (brand: Brand): React.CSSProperties => ({
    fontFamily: brand.fontFamily,
    fontSize: 19,
    lineHeight: "26px",
    letterSpacing: -0.2,
    color: brand.inkMuted,
    fontWeight: 400,
  }),
  mono: (brand: Brand): React.CSSProperties => ({
    fontFamily: brand.monoFontFamily,
    fontSize: 15,
    lineHeight: "20px",
    color: brand.inkSubtle,
    fontWeight: 400,
  }),
};

export const Headline: React.FC<{ text: string; accentWord: string; brand: Brand }> = ({
  text,
  accentWord,
  brand,
}) => {
  const parts = text.split(" ");
  return (
    <div style={type.headline(brand)}>
      {parts.map((word, i) => (
        <React.Fragment key={i}>
          <span style={word === accentWord ? { color: brand.accent } : undefined}>{word}</span>
          {i < parts.length - 1 ? " " : null}
        </React.Fragment>
      ))}
    </div>
  );
};

/** Title block shown in the margin while the full interface establishes context. */
export const TitleBlock: React.FC<{
  content: Content;
  brand: Brand;
  column: Column;
  opacity: number;
  rise: number;
}> = ({ content, brand, column, opacity, rise }) => (
  <div
    style={{
      position: "absolute",
      left: column.x,
      top: column.y,
      width: column.w,
      height: column.h,
      display: "flex",
      flexDirection: "column",
      justifyContent: "center",
      gap: 24,
      opacity,
      transform: `translateY(${rise}px)`,
    }}
  >
    <div style={type.eyebrow(brand)}>{content.eyebrow}</div>
    <Headline text={content.headline} accentWord={content.accentWord} brand={brand} />
    <div style={type.subhead(brand)}>{content.subhead}</div>
  </div>
);

/** Caption + annotation for one inspection, tied to the region under the window. */
export const CaptionBlock: React.FC<{
  index: number;
  total: number;
  caption: string;
  label?: string;
  magnification?: number;
  brand: Brand;
  layout: Layout;
  column: Column;
  captionOpacity: number;
  labelOpacity: number;
  rise: number;
}> = ({
  index,
  total,
  caption,
  label,
  magnification,
  brand,
  layout,
  column,
  captionOpacity,
  labelOpacity,
  rise,
}) => (
  <div
    style={{
      position: "absolute",
      left: column.x,
      top: column.y,
      width: column.w,
      height: column.h,
      display: "flex",
      flexDirection: "column",
      justifyContent: "center",
      gap: 20,
      transform: `translateY(${rise}px)`,
    }}
  >
    {layout.showSceneCounter ? (
      <div style={{ ...type.eyebrow(brand), opacity: captionOpacity }}>
        {String(index + 1).padStart(2, "0")} / {String(total).padStart(2, "0")}
      </div>
    ) : null}
    <div style={{ ...type.caption(brand), opacity: captionOpacity }}>{caption}</div>
    {label ? (
      <div
        style={{
          display: "flex",
          alignItems: "flex-start",
          gap: 12,
          opacity: labelOpacity,
          marginTop: 4,
        }}
      >
        <div
          style={{
            width: 20,
            height: 20,
            marginTop: 3,
            flexShrink: 0,
            borderRadius: 4,
            boxShadow: `0 0 0 1.5px ${brand.accent}`,
          }}
        />
        <div style={type.label(brand)}>
          {label}
          {layout.showMagnification && magnification ? (
            <span style={{ ...type.mono(brand), marginLeft: 10 }}>
              {magnification.toFixed(1)}x
            </span>
          ) : null}
        </div>
      </div>
    ) : null}
  </div>
);

/** Persistent chrome: lockup at the top of the margin, feature name at the bottom. */
export const MarginChrome: React.FC<{
  brand: Brand;
  content: Content;
  column: Column;
  logoSrc: string;
  logoHeight: number;
  safeMargin: number;
  opacity: number;
}> = ({ brand, content, column, logoSrc, logoHeight, safeMargin, opacity }) => (
  <>
    <Img
      src={logoSrc}
      style={{
        position: "absolute",
        left: column.x,
        top: safeMargin,
        height: logoHeight,
        opacity,
      }}
    />
    <div
      style={{
        position: "absolute",
        left: column.x,
        bottom: safeMargin,
        ...type.mono(brand),
        opacity,
      }}
    >
      {content.featureName}
    </div>
  </>
);

export const textStyles = type;
