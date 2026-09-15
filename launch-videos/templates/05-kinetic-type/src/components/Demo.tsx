import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";
import type { Rect } from "../layout";

/**
 * Real product footage, cover-fitted into `rect` by crop + scale only. The
 * source is never redrawn, skewed or recolored.
 */
export const CroppedMedia: React.FC<{ media: MediaSlot; rect: Rect }> = ({
  media,
  rect,
}) => {
  const crop = media.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const cropW = crop.w * media.naturalWidth;
  const cropH = crop.h * media.naturalHeight;
  const scale = Math.max(rect.w / cropW, rect.h / cropH);
  const overflowX = cropW * scale - rect.w;
  const overflowY = cropH * scale - rect.h;
  const align = media.align ?? "center";
  const shiftY = align === "top" ? 0 : align === "bottom" ? -overflowY : -overflowY / 2;
  const style: React.CSSProperties = {
    position: "absolute",
    width: media.naturalWidth * scale,
    height: media.naturalHeight * scale,
    left: -crop.x * media.naturalWidth * scale - overflowX / 2,
    top: -crop.y * media.naturalHeight * scale + shiftY,
    maxWidth: "none",
  };
  const src = staticFile(media.src);
  return media.kind === "video" ? (
    <OffthreadVideo
      src={src}
      muted
      startFrom={media.startFrom ?? 0}
      playbackRate={media.playbackRate ?? 1}
      style={style}
    />
  ) : (
    <Img src={src} style={style} />
  );
};

/** Hairline frame that the phrase lives in before the footage arrives. */
export const Frame: React.FC<{
  rect: Rect;
  brand: Brand;
  radius: number;
  opacity: number;
}> = ({ rect, brand, radius, opacity }) => (
  <div
    style={{
      position: "absolute",
      left: rect.x,
      top: rect.y,
      width: rect.w,
      height: rect.h,
      border: `1px solid ${brand.line}`,
      borderRadius: radius,
      backgroundColor: brand.surface,
      opacity,
    }}
  />
);

export const Demo: React.FC<{
  media: MediaSlot;
  rect: Rect;
  brand: Brand;
  radius: number;
  opacity: number;
  offsetY?: number;
  speedBadge?: string;
  monoFontFamily: string;
}> = ({ media, rect, brand, radius, opacity, offsetY = 0, speedBadge, monoFontFamily }) => (
  <div
    style={{
      position: "absolute",
      left: rect.x,
      top: rect.y + offsetY,
      width: rect.w,
      height: rect.h,
      opacity,
    }}
  >
    <div
      style={{
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        borderRadius: radius,
        border: `1px solid ${brand.line}`,
        boxShadow: "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)",
        backgroundColor: brand.surface,
      }}
    >
      <CroppedMedia media={media} rect={rect} />
    </div>
    {speedBadge && (media.playbackRate ?? 1) > 1 ? (
      <div
        style={{
          position: "absolute",
          right: 16,
          bottom: 16,
          padding: "4px 10px",
          borderRadius: 8,
          background: brand.ink,
          color: brand.white,
          fontFamily: monoFontFamily,
          fontSize: 16,
          fontWeight: 500,
        }}
      >
        {speedBadge}
      </div>
    ) : null}
  </div>
);
