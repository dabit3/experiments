import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import { FULL_CROP } from "./geometry";
import type { MediaSlot } from "./schema";

type Props = {
  slot: MediaSlot;
  /** Size of the box the visible (cropped) media fills at zoom 1. */
  width: number;
  height: number;
  /** Uniform scale of the media relative to the box (1 = fills the box). */
  zoom?: number;
  /** Translation, in output pixels, applied after zooming. */
  offsetX?: number;
  offsetY?: number;
};

/**
 * Renders a media slot pixel-preserved (crop + uniform scale only). The element is
 * laid out at its natural aspect ratio; the crop is applied by offsetting the full
 * frame inside an overflow-hidden box.
 */
export const Media: React.FC<Props> = ({
  slot,
  width,
  height,
  zoom = 1,
  offsetX = 0,
  offsetY = 0,
}) => {
  const crop = slot.crop ?? FULL_CROP;
  const boxW = width * zoom;
  const boxH = height * zoom;
  const fullW = boxW / crop.w;
  const fullH = boxH / crop.h;
  const style: React.CSSProperties = {
    position: "absolute",
    left: -crop.x * fullW,
    top: -crop.y * fullH,
    width: fullW,
    height: fullH,
    display: "block",
  };
  return (
    <div
      style={{
        position: "absolute",
        left: offsetX,
        top: offsetY,
        width: boxW,
        height: boxH,
        overflow: "hidden",
      }}
    >
      {slot.kind === "video" ? (
        <OffthreadVideo
          src={staticFile(slot.src)}
          startFrom={slot.startFrom ?? 0}
          playbackRate={slot.playbackRate ?? 1}
          muted
          style={style}
        />
      ) : (
        <Img src={staticFile(slot.src)} style={style} />
      )}
    </div>
  );
};
