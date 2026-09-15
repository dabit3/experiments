import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand, Content } from "../schema";

export const SAFE = 96;

export const Eyebrow: React.FC<{ brand: Brand; children: React.ReactNode; mono?: boolean }> = ({
  brand,
  children,
  mono,
}) => (
  <div
    style={{
      fontFamily: mono ? brand.monoFontFamily : brand.fontFamily,
      fontSize: 15,
      lineHeight: "22px",
      letterSpacing: 0.4,
      textTransform: "uppercase",
      fontWeight: 500,
      color: brand.inkMuted,
      display: "flex",
      alignItems: "center",
      gap: 12,
    }}
  >
    <span
      style={{
        display: "inline-block",
        width: 8,
        height: 8,
        borderRadius: 999,
        backgroundColor: brand.accent,
      }}
    />
    {children}
  </div>
);

const Accented: React.FC<{ text: string; accent: string; color: string }> = ({ text, accent, color }) => {
  const i = accent ? text.indexOf(accent) : -1;
  if (i < 0) {
    return <>{text}</>;
  }
  return (
    <>
      {text.slice(0, i)}
      <span style={{ color }}>{accent}</span>
      {text.slice(i + accent.length)}
    </>
  );
};

export const TitleBlock: React.FC<{ brand: Brand; content: Content }> = ({ brand, content }) => (
  <div style={{ display: "flex", flexDirection: "column", gap: 28 }}>
    <Eyebrow brand={brand} mono>
      {content.eyebrow} · {content.featureName}
    </Eyebrow>
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontWeight: 500,
        fontSize: 64,
        lineHeight: "68px",
        letterSpacing: -2.3,
        color: brand.ink,
      }}
    >
      <Accented text={content.headline} accent={content.headlineAccent} color={brand.accent} />
    </div>
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontWeight: 400,
        fontSize: 21.5,
        lineHeight: "32px",
        letterSpacing: -0.31,
        color: brand.inkMuted,
        maxWidth: 520,
      }}
    >
      {content.subhead}
    </div>
  </div>
);

export const CaptionBlock: React.FC<{
  brand: Brand;
  eyebrow: string | null;
  text: string;
}> = ({ brand, eyebrow, text }) => (
  <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
    {eyebrow ? (
      <Eyebrow brand={brand} mono>
        {eyebrow}
      </Eyebrow>
    ) : null}
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontWeight: 500,
        fontSize: 30,
        lineHeight: "38px",
        letterSpacing: -0.5,
        color: brand.ink,
      }}
    >
      {text}
    </div>
  </div>
);

export const CtaBlock: React.FC<{ brand: Brand; content: Content }> = ({ brand, content }) => (
  <div style={{ display: "flex", flexDirection: "column", gap: 32 }}>
    <div
      style={{
        fontFamily: brand.fontFamily,
        fontWeight: 500,
        fontSize: 44,
        lineHeight: "50px",
        letterSpacing: -1.4,
        color: brand.ink,
      }}
    >
      {content.outroLine}
    </div>
    <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
      <div
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 16,
          lineHeight: "33px",
          height: 33,
          padding: "0 14px",
          borderRadius: 2,
          backgroundColor: brand.ink,
          color: brand.white,
          fontWeight: 500,
          whiteSpace: "nowrap",
        }}
      >
        {content.cta.label}
      </div>
      <div
        style={{
          fontFamily: brand.monoFontFamily,
          fontSize: 15,
          color: brand.inkMuted,
          whiteSpace: "nowrap",
        }}
      >
        {content.cta.url}
      </div>
    </div>
  </div>
);

export const Logo: React.FC<{ brand: Brand; opacity: number }> = ({ brand, opacity }) => (
  <Img
    src={staticFile(brand.logoLight)}
    style={{
      position: "absolute",
      left: SAFE,
      top: SAFE - 8,
      height: 30,
      opacity,
    }}
  />
);

export const SpeedBadge: React.FC<{ brand: Brand; label: string; left: number; top: number }> = ({
  brand,
  label,
  left,
  top,
}) => (
  <div
    style={{
      position: "absolute",
      left,
      top,
      fontFamily: brand.monoFontFamily,
      fontSize: 13,
      lineHeight: "22px",
      padding: "0 8px",
      borderRadius: 8,
      backgroundColor: brand.ink,
      color: brand.white,
    }}
  >
    {label}
  </div>
);
