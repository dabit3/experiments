import React from "react";
import { AbsoluteFill } from "remotion";
import type { Brand, Lighting } from "../schema";

/**
 * The dark stage every scene sits on. The vignette is a very slight lift of the
 * center toward `blackRaised`, fading to `black` at the edges. It is drawn
 * underneath everything, so it never tints the product footage.
 */
export const Stage: React.FC<{
  brand: Brand;
  lighting: Lighting;
  children: React.ReactNode;
}> = ({ brand, lighting, children }) => {
  return (
    <AbsoluteFill style={{ background: brand.black, fontFamily: brand.fontFamily }}>
      {lighting.vignette > 0 ? (
        <AbsoluteFill
          style={{
            background: `radial-gradient(ellipse 70% 70% at 50% 45%, ${brand.blackRaised} 0%, ${brand.black} 100%)`,
            opacity: lighting.vignette,
          }}
        />
      ) : null}
      {children}
    </AbsoluteFill>
  );
};

/** Soft rim light behind a media frame — outside the interface only. */
export const RimLight: React.FC<{
  lighting: Lighting;
  left: number;
  top: number;
  width: number;
  height: number;
  radius: number;
  opacity: number;
}> = ({ lighting, left, top, width, height, radius, opacity }) => {
  if (lighting.edgeGlow <= 0) {
    return null;
  }
  const glow = lighting.edgeGlow * opacity;
  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width,
        height,
        borderRadius: radius,
        boxShadow: `0 0 96px rgba(255,255,255,${(0.14 * glow).toFixed(3)}), 0 0 1px rgba(255,255,255,${(
          0.55 * glow
        ).toFixed(3)})`,
        background: "transparent",
      }}
    />
  );
};
