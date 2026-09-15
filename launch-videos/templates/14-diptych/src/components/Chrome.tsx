import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand, Layout } from "../schema";
import { HEIGHT, WIDTH, bands } from "../geometry";

/** Brand type scale (site px x1.27 for 1920 video). */
export const type = {
  display: { fontSize: 89, lineHeight: "89px", letterSpacing: "-3.4px", fontWeight: 500 },
  h2: { fontSize: 81, lineHeight: "94px", letterSpacing: "-3px", fontWeight: 500 },
  h3: { fontSize: 34, lineHeight: "42px", letterSpacing: "-0.53px", fontWeight: 500 },
  h5: { fontSize: 27, lineHeight: "41px", letterSpacing: "-0.4px", fontWeight: 400 },
  label: { fontSize: 20, lineHeight: "28px", letterSpacing: "-0.2px", fontWeight: 500 },
  eyebrow: {
    fontSize: 14.4,
    lineHeight: "22px",
    letterSpacing: "0.36px",
    fontWeight: 500,
    textTransform: "uppercase" as const,
  },
} as const;

export const TopBar: React.FC<{
  brand: Brand;
  layout: Layout;
  featureName: string;
  opacity: number;
  dark?: boolean;
}> = ({ brand, layout, featureName, opacity, dark }) => (
  <div
    style={{
      position: "absolute",
      left: layout.margin,
      right: layout.margin,
      top: bands(layout).top,
      height: 24,
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      opacity,
    }}
  >
    <Img
      src={staticFile(dark ? brand.logoDark : brand.logoLight)}
      style={{ height: 24, width: "auto", display: "block" }}
    />
    <div
      style={{
        ...type.eyebrow,
        fontFamily: brand.fontFamily,
        color: dark ? brand.inkSubtle : brand.inkMuted,
      }}
    >
      {featureName}
    </div>
  </div>
);

export const PanelLabel: React.FC<{
  brand: Brand;
  layout: Layout;
  x: number;
  w: number;
  text: string;
  opacity: number;
  shift?: number;
}> = ({ brand, layout, x, w, text, opacity, shift = 0 }) => (
  <div
    style={{
      position: "absolute",
      left: x,
      top: bands(layout).labelY + shift,
      width: w,
      ...type.label,
      fontFamily: brand.fontFamily,
      color: brand.ink,
      whiteSpace: "nowrap",
      overflow: "hidden",
      textOverflow: "ellipsis",
      opacity,
    }}
  >
    {text}
  </div>
);

export const Caption: React.FC<{
  brand: Brand;
  layout: Layout;
  text: string;
  opacity: number;
  shift?: number;
}> = ({ brand, layout, text, opacity, shift = 0 }) => (
  <div
    style={{
      position: "absolute",
      left: layout.margin,
      top: bands(layout).captionY + shift,
      width: WIDTH - layout.margin * 2,
      ...type.h3,
      fontFamily: brand.fontFamily,
      color: brand.ink,
      whiteSpace: "nowrap",
      opacity,
    }}
  >
    {text}
  </div>
);

export const Divider: React.FC<{
  brand: Brand;
  layout: Layout;
  x: number;
  opacity: number;
}> = ({ brand, layout, x, opacity }) => {
  const { panelTop, panelBottom } = bands(layout);
  return (
    <div
      style={{
        position: "absolute",
        left: x - 0.5,
        top: panelTop,
        width: 1,
        height: panelBottom - panelTop,
        backgroundColor: brand.line,
        opacity,
      }}
    />
  );
};

export const Backdrop: React.FC<{ color: string }> = ({ color }) => (
  <div
    style={{
      position: "absolute",
      left: 0,
      top: 0,
      width: WIDTH,
      height: HEIGHT,
      backgroundColor: color,
    }}
  />
);
