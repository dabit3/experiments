import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";
import { fullCrop } from "../layout";

type Props = {
  slot: MediaSlot;
  width: number;
  height: number;
  brand: Brand;
  /** Frame border + shadow treatment. */
  framed?: boolean;
  style?: React.CSSProperties;
};

/**
 * Renders a media slot flat and pixel-preserved into a fixed box. The crop is a
 * fraction rectangle of the source; the source is scaled uniformly so the crop fills
 * the box. No skew, no recolor.
 */
export const Media: React.FC<Props> = ({
  slot,
  width,
  height,
  brand,
  framed = true,
  style,
}) => {
  const crop = slot.crop ?? fullCrop;
  const innerW = width / crop.w;
  const innerH = height / crop.h;
  const inner: React.CSSProperties = {
    position: "absolute",
    width: innerW,
    height: innerH,
    left: -crop.x * innerW,
    top: -crop.y * innerH,
    objectFit: "fill",
  };
  return (
    <div
      style={{
        position: "relative",
        width,
        height,
        overflow: "hidden",
        borderRadius: framed ? brand.radius : 0,
        border: framed ? `1px solid ${brand.line}` : undefined,
        boxShadow: framed
          ? "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)"
          : undefined,
        background: brand.surface,
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
