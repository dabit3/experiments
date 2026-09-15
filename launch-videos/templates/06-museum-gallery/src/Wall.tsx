import React from "react";
import { AbsoluteFill } from "remotion";
import type { Brand, Gallery } from "./schema";

/**
 * The gallery architecture: a flat paper wall meeting a slightly darker floor along a
 * hairline. Nothing else - no furniture, no visitors, no scenery.
 */
export const Wall: React.FC<{ brand: Brand; gallery: Gallery; children?: React.ReactNode }> = ({
  brand,
  gallery,
  children,
}) => {
  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper }}>
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          bottom: 0,
          height: gallery.floorHeight,
          backgroundColor: brand.surface,
          borderTop: `1px solid ${brand.line}`,
        }}
      />
      {children}
    </AbsoluteFill>
  );
};
