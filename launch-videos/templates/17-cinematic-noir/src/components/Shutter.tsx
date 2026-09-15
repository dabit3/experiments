import React from "react";
import type { Brand, Mask } from "../schema";
import { move } from "../motion";

/**
 * Reveals its children through a clean rectangular mask that opens from a
 * slit (horizontal, vertical, or both = iris). A thin white slit can sit on the
 * moving edges while the shutter opens; it lives in the still-dark area, never
 * over the interface.
 */
export const Shutter: React.FC<{
  frame: number;
  mask: Mask;
  brand: Brand;
  width: number;
  height: number;
  children: React.ReactNode;
}> = ({ frame, mask, brand, width, height, children }) => {
  if (mask.kind === "none" || mask.durationInFrames === 0) {
    return <div style={{ width, height, position: "relative" }}>{children}</div>;
  }

  const progress = move(frame, mask.delayInFrames, mask.durationInFrames);
  const openY = mask.kind === "shutter-horizontal" || mask.kind === "iris";
  const openX = mask.kind === "shutter-vertical" || mask.kind === "iris";
  const insetY = openY ? (1 - progress) * 50 : 0;
  const insetX = openX ? (1 - progress) * 50 : 0;

  const slitOpacity = mask.slit ? Math.min(1, progress * 6) * (1 - progress) * 0.9 : 0;
  const slitStyle: React.CSSProperties = {
    position: "absolute",
    background: brand.white,
    opacity: slitOpacity,
    pointerEvents: "none",
  };

  return (
    <div style={{ width, height, position: "relative" }}>
      <div
        style={{
          width,
          height,
          clipPath: `inset(${insetY}% ${insetX}% ${insetY}% ${insetX}%)`,
        }}
      >
        {children}
      </div>
      {openY ? (
        <>
          <div style={{ ...slitStyle, left: 0, right: 0, height: 1, top: `calc(${insetY}% - 1px)` }} />
          <div style={{ ...slitStyle, left: 0, right: 0, height: 1, bottom: `calc(${insetY}% - 1px)` }} />
        </>
      ) : null}
      {openX ? (
        <>
          <div style={{ ...slitStyle, top: 0, bottom: 0, width: 1, left: `calc(${insetX}% - 1px)` }} />
          <div style={{ ...slitStyle, top: 0, bottom: 0, width: 1, right: `calc(${insetX}% - 1px)` }} />
        </>
      ) : null}
    </div>
  );
};
