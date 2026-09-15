import React from "react";
import { AbsoluteFill } from "remotion";
import type { Brand, Lighting } from "../schema";

/**
 * The studio: a paper-coloured backdrop lit by one soft key light, with a
 * gentle vignette. All "richness" lives here, outside the interface.
 */
export const Studio: React.FC<{ brand: Brand; lighting: Lighting }> = ({ brand, lighting }) => {
  const kx = lighting.keyX * 100;
  const ky = lighting.keyY * 100;
  const radius = lighting.keyRadius * 100;
  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse ${radius}% ${radius * 0.75}% at ${kx}% ${ky}%, ${brand.surfaceAlt} 0%, ${brand.paper} 70%)`,
          opacity: lighting.keyIntensity,
        }}
      />
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse 110% 110% at 50% 50%, rgba(0,0,0,0) 45%, rgba(0,0,0,${0.16 * lighting.vignette}) 100%)`,
        }}
      />
    </AbsoluteFill>
  );
};
