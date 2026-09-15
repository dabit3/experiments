import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { MediaSlot } from "../schema";

export const mediaAspect = (slot: MediaSlot): number => {
  const source = slot.aspect ?? 16 / 9;
  if (!slot.crop) {
    return source;
  }
  return (source * slot.crop.w) / slot.crop.h;
};

/**
 * Renders a media slot pixel-preserved (scale/crop only) into a box of the
 * given size. The box must have the slot's cropped aspect ratio.
 */
export const Media: React.FC<{ slot: MediaSlot; width: number; height: number }> = ({
  slot,
  width,
  height,
}) => {
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const innerWidth = width / crop.w;
  const innerHeight = height / crop.h;
  const inner: React.CSSProperties = {
    position: "absolute",
    left: -crop.x * innerWidth,
    top: -crop.y * innerHeight,
    width: innerWidth,
    height: innerHeight,
    objectFit: "fill",
    display: "block",
  };
  const src = staticFile(slot.src);

  return (
    <div style={{ position: "relative", width, height, overflow: "hidden" }}>
      {slot.kind === "video" ? (
        <OffthreadVideo
          src={src}
          startFrom={slot.startFrom ?? 0}
          playbackRate={slot.playbackRate ?? 1}
          muted
          style={inner}
        />
      ) : (
        <Img src={src} style={inner} />
      )}
    </div>
  );
};
