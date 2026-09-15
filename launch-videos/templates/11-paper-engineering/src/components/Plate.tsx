import React from "react";
import type { Brand, Layout, MediaSlot, Surface } from "../schema";
import { plateShadow, type Box } from "../lib";
import { Media } from "./Media";

type Props = {
  box: Box;
  slot: MediaSlot;
  brand: Brand;
  layout: Layout;
  surface: Surface;
  elevation?: number;
  style?: React.CSSProperties;
};

/** A perfectly flat matte presentation surface with the product sitting on it. */
export const Plate: React.FC<Props> = ({
  box,
  slot,
  brand,
  layout,
  surface,
  elevation = 1,
  style,
}) => {
  const p = layout.platePadding;
  return (
    <div
      style={{
        position: "absolute",
        left: box.x,
        top: box.y,
        width: box.w,
        height: box.h,
        background: brand.surfaceAlt,
        borderRadius: layout.plateRadius,
        boxShadow: plateShadow(surface, elevation),
        ...style,
      }}
    >
      <div style={{ position: "absolute", left: p, top: p }}>
        <Media
          slot={slot}
          width={box.w - p * 2}
          height={box.h - p * 2}
          radius={layout.mediaRadius}
          borderColor={brand.line}
        />
      </div>
    </div>
  );
};
