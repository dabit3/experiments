import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { MediaSlot } from "./schema";

type Props = {
  slot: MediaSlot;
  width: number;
  height: number;
  style?: React.CSSProperties;
};

/**
 * Renders a media slot into a width x height box, pixel-preserving: the (optionally
 * cropped) source is uniformly scaled to cover the box and centered. No skew, no
 * recolor - only crop and scale.
 */
export const Media: React.FC<Props> = ({ slot, width, height, style }) => {
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const cropW = slot.width * crop.w;
  const cropH = slot.height * crop.h;
  const scale = Math.max(width / cropW, height / cropH);
  const drawW = slot.width * scale;
  const drawH = slot.height * scale;
  const offsetX = (width - cropW * scale) / 2 - crop.x * slot.width * scale;
  const offsetY = (height - cropH * scale) / 2 - crop.y * slot.height * scale;

  const inner: React.CSSProperties = {
    position: "absolute",
    left: offsetX,
    top: offsetY,
    width: drawW,
    height: drawH,
    display: "block",
  };

  return (
    <div style={{ position: "relative", width, height, overflow: "hidden", ...style }}>
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
