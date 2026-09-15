import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";
import { cropOf, croppedAspect, fitRect, type Rect } from "../geometry";

export const cardShadow =
  "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)";

type Props = {
  slot: MediaSlot;
  /** Slot to fit the media into. */
  into: Rect;
  fit: "contain" | "cover";
  brand: Brand;
  radius: number;
  /** 0-1: border, radius and shadow strength (0 = flush full-frame). */
  frame: number;
  opacity?: number;
};

/**
 * Pixel-preserving media card: the source is only cropped (via an overflow-hidden
 * window) and uniformly scaled. Never skewed or recolored.
 */
export const Media: React.FC<Props> = ({
  slot,
  into,
  fit,
  brand,
  radius,
  frame,
  opacity = 1,
}) => {
  const crop = cropOf(slot);
  const card = fitRect(into, croppedAspect(slot), fit);
  const innerW = card.w / crop.w;
  const innerH = card.h / crop.h;
  const inner: React.CSSProperties = {
    position: "absolute",
    left: -crop.x * innerW,
    top: -crop.y * innerH,
    width: innerW,
    height: innerH,
    display: "block",
  };
  return (
    <div
      style={{
        position: "absolute",
        left: card.x,
        top: card.y,
        width: card.w,
        height: card.h,
        overflow: "hidden",
        borderRadius: radius * frame,
        boxShadow: frame > 0 ? cardShadow : "none",
        outline: frame > 0 ? `1px solid ${brand.line}` : "none",
        outlineOffset: -1,
        backgroundColor: brand.surfaceAlt,
        opacity,
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
