import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";
import { cropOf, type Rect } from "../layout";

export const PLANE_SHADOW = "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)";

/**
 * A flat, front-facing product plane. The media is scaled and offset so the crop region
 * exactly fills `rect`; pixels are never skewed or recolored.
 */
export const Plane: React.FC<{
  slot: MediaSlot;
  rect: Rect;
  brand: Brand;
  radius?: number;
  opacity?: number;
  shadow?: boolean;
  speedBadge?: string;
  children?: React.ReactNode;
}> = ({ slot, rect, brand, radius = 12, opacity = 1, shadow = true, speedBadge, children }) => {
  const c = cropOf(slot);
  const mediaW = rect.w / c.w;
  const mediaH = rect.h / c.h;
  const mediaStyle: React.CSSProperties = {
    position: "absolute",
    left: -c.x * mediaW,
    top: -c.y * mediaH,
    width: mediaW,
    height: mediaH,
    display: "block",
  };
  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        borderRadius: radius,
        overflow: "hidden",
        background: brand.surfaceAlt,
        boxShadow: shadow ? PLANE_SHADOW : "none",
        outline: `1px solid ${brand.line}`,
        outlineOffset: -1,
        opacity,
      }}
    >
      {slot.kind === "video" ? (
        <OffthreadVideo
          src={staticFile(slot.src)}
          startFrom={slot.startFrom ?? 0}
          playbackRate={slot.playbackRate ?? 1}
          muted
          style={mediaStyle}
        />
      ) : (
        <Img src={staticFile(slot.src)} style={mediaStyle} />
      )}
      {slot.speedBadge && speedBadge ? (
        <div
          style={{
            position: "absolute",
            right: 16,
            top: 16,
            padding: "4px 10px",
            borderRadius: 8,
            background: brand.ink,
            color: brand.white,
            fontFamily: brand.monoFontFamily,
            fontSize: 14,
            letterSpacing: 0.28,
          }}
        >
          {speedBadge}
        </div>
      ) : null}
      {children}
    </div>
  );
};
