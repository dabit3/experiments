import React from "react";
import { Img, staticFile } from "remotion";
import type { Feature, Outcome } from "../content";
import { color, fontMono, fontSans, radius, shadow, type } from "../tokens";

const PAD = 32;
const LABEL_TOP = 30;
const CARD_TOP = 84;
const BLEED = 40;

export const eyebrowStyle: React.CSSProperties = {
  fontFamily: fontMono,
  fontSize: type.sizes1080p.label,
  fontWeight: 500,
  letterSpacing: type.tracking.caps,
  textTransform: "uppercase",
  lineHeight: 1,
};

// Compact tile: label row + a screenshot figure that bleeds off the
// bottom-right, clipped by the tile.
export const CompactTile: React.FC<{ feature: Feature; w: number; h: number; children?: React.ReactNode }> = ({
  feature,
  w,
  h,
  children,
}) => {
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <div
        style={{
          position: "absolute",
          left: PAD,
          top: LABEL_TOP,
          display: "flex",
          alignItems: "baseline",
          gap: 14,
        }}
      >
        <span style={{ ...eyebrowStyle, color: color.gray400 }}>{feature.index}</span>
        <span
          style={{
            fontFamily: fontSans,
            fontSize: type.sizes1080p.caption,
            fontWeight: 500,
            letterSpacing: type.tracking.body,
            color: color.ink,
            lineHeight: 1,
          }}
        >
          {feature.label}
        </span>
      </div>
      <div
        style={{
          position: "absolute",
          left: PAD,
          top: CARD_TOP,
          width: w - PAD + BLEED,
          height: h - CARD_TOP + BLEED,
          borderRadius: radius.md,
          border: `1px solid ${color.border}`,
          boxShadow: shadow.figure,
          background: color.white,
          overflow: "hidden",
        }}
      >
        {children}
      </div>
    </div>
  );
};

export const compactFigureSize = (w: number, h: number) => ({
  width: w - PAD + BLEED,
  height: h - CARD_TOP + BLEED,
});

export const OutcomeTile: React.FC<{ outcome: Outcome; wide: boolean }> = ({ outcome, wide }) => (
  <div style={{ position: "absolute", inset: 0 }}>
    <div style={{ position: "absolute", left: PAD, top: LABEL_TOP, ...eyebrowStyle, color: color.gray500 }}>
      {outcome.label}
    </div>
    <div
      style={{
        position: "absolute",
        left: PAD,
        right: PAD,
        bottom: PAD - 4,
        fontFamily: fontSans,
        fontSize: wide ? 48 : type.sizes1080p.h3,
        fontWeight: 500,
        letterSpacing: type.tracking.heading,
        lineHeight: type.leading.heading,
        color: color.ink,
      }}
    >
      {outcome.text}
    </div>
  </div>
);

export const BRAND_MARK = 112;

export const BrandTile: React.FC<{ markOpacity?: number }> = ({ markOpacity = 1 }) => (
  <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
    <Img
      src={staticFile("brand/devin-mark-white.png")}
      style={{ width: BRAND_MARK, height: BRAND_MARK, opacity: markOpacity }}
    />
  </div>
);
