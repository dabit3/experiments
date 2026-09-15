import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, LayoutTokens, MediaSlot } from "./schema";

type Props = {
  slot: MediaSlot;
  width: number;
  height: number;
  brand: Brand;
  tokens: LayoutTokens;
  /** Flat 1px hairline + soft shadow per brand.md. Off for bleeds. */
  framed?: boolean;
  style?: React.CSSProperties;
};

/**
 * Places a crop window of the source (fractions of the intrinsic size) so that it
 * covers a width x height box. Uniform scale only: pixels are never stretched or
 * recolored, and overflow is clipped.
 */
export const Media: React.FC<Props> = ({
  slot,
  width,
  height,
  brand,
  tokens,
  framed = true,
  style,
}) => {
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const srcW = slot.aspect;
  const srcH = 1;
  const scale = Math.max(width / (crop.w * srcW), height / (crop.h * srcH));
  const dispW = srcW * scale;
  const dispH = srcH * scale;
  const left = -crop.x * dispW + (width - crop.w * dispW) / 2;
  const top = -crop.y * dispH + (height - crop.h * dispH) / 2;

  const inner: React.CSSProperties = {
    position: "absolute",
    left,
    top,
    width: dispW,
    height: dispH,
    display: "block",
  };

  return (
    <div
      style={{
        position: "relative",
        width,
        height,
        overflow: "hidden",
        background: brand.surfaceAlt,
        borderRadius: framed ? tokens.radius : 0,
        border: framed ? `1px solid ${brand.line}` : "none",
        boxShadow: framed
          ? "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)"
          : "none",
        ...style,
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
    </div>
  );
};
