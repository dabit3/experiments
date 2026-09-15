import React from "react";
import { Img, staticFile } from "remotion";
import type { Brand, Content, Layout, Surface } from "../schema";
import { HEIGHT, WIDTH } from "../lib";

/** Paper background with an extremely subtle grain, kept outside the product. */
export const Paper: React.FC<{ brand: Brand; surface: Surface }> = ({ brand, surface }) => (
  <div style={{ position: "absolute", inset: 0, background: brand.paper }}>
    {surface.texture > 0 ? (
      <svg
        width={WIDTH}
        height={HEIGHT}
        style={{ position: "absolute", inset: 0, opacity: 0.05 * surface.texture, mixBlendMode: "multiply" }}
      >
        <filter id="grain">
          <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" stitchTiles="stitch" />
          <feColorMatrix type="saturate" values="0" />
        </filter>
        <rect width={WIDTH} height={HEIGHT} filter="url(#grain)" />
      </svg>
    ) : null}
  </div>
);

/** Logo row above the stage. The lockup is only ever faded or slid, never redrawn. */
export const Header: React.FC<{
  brand: Brand;
  content: Content;
  layout: Layout;
  opacity?: number;
}> = ({ brand, content, layout, opacity = 1 }) => {
  const h = 26;
  return (
    <div
      style={{
        position: "absolute",
        left: layout.margin,
        right: layout.margin,
        top: layout.margin,
        height: h,
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        opacity,
      }}
    >
      <Img src={staticFile(brand.logoLight)} style={{ height: h, width: "auto", display: "block" }} />
      <span
        style={{
          fontFamily: brand.fontFamily,
          fontSize: 16,
          letterSpacing: -0.15,
          color: brand.inkMuted,
        }}
      >
        {content.featureName}
      </span>
    </div>
  );
};
