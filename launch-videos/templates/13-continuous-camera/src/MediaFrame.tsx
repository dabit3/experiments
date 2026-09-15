import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "./schema";

export const DEFAULT_SOURCE_SIZE = { w: 1920, h: 1080 };

/** Canvas size of a media frame for a given display width. */
export const frameSize = (slot: MediaSlot, width: number) => {
  const src = slot.sourceSize ?? DEFAULT_SOURCE_SIZE;
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const cropW = src.w * crop.w;
  const cropH = src.h * crop.h;
  return { width, height: Math.round((width * cropH) / cropW) };
};

type Props = {
  slot: MediaSlot;
  width: number;
  brand: Brand;
  opacity?: number;
  /** Absolute canvas position of the frame's top-left. */
  left: number;
  top: number;
  badge?: string;
  monoFontFamily: string;
};

/**
 * Flat, front-facing product frame. The source is only cropped and scaled:
 * the full asset is laid out at (width / crop.w) and shifted so the crop
 * window fills the frame.
 */
export const MediaFrame: React.FC<Props> = ({
  slot,
  width,
  brand,
  opacity = 1,
  left,
  top,
  badge,
  monoFontFamily,
}) => {
  const src = slot.sourceSize ?? DEFAULT_SOURCE_SIZE;
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const { height } = frameSize(slot, width);
  const fullW = width / crop.w;
  const fullH = (fullW * src.h) / src.w;
  const inner: React.CSSProperties = {
    position: "absolute",
    width: fullW,
    height: fullH,
    left: -crop.x * fullW,
    top: -crop.y * fullH,
    objectFit: "fill",
  };
  return (
    <div
      style={{
        position: "absolute",
        left,
        top,
        width,
        height,
        opacity,
        borderRadius: 16,
        overflow: "hidden",
        border: `1px solid ${brand.line}`,
        background: brand.surfaceAlt,
        boxShadow: "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)",
      }}
    >
      {slot.kind === "video" ? (
        <OffthreadVideo
          src={staticFile(slot.src)}
          startFrom={slot.startFrom ?? 0}
          playbackRate={slot.playbackRate ?? 1}
          muted
          style={inner}
        />
      ) : (
        <Img src={staticFile(slot.src)} style={inner} />
      )}
      {badge ? (
        <div
          style={{
            position: "absolute",
            right: 16,
            top: 16,
            padding: "4px 10px",
            borderRadius: 8,
            background: brand.ink,
            color: brand.white,
            fontFamily: monoFontFamily,
            fontSize: 16,
            lineHeight: "22px",
          }}
        >
          {badge}
        </div>
      ) : null}
    </div>
  );
};
