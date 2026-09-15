import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { MediaSlot } from "../schema";

type Props = {
  slot: MediaSlot;
  width: number;
  height: number;
  /** contain = letterbox inside the box (primary display); cover = fill the box (bays). */
  fit: "contain" | "cover";
  /** Background shown in the letterbox area. */
  background?: string;
};

/**
 * Draws a media slot pixel-preserved into a box: the source is scaled uniformly and the
 * `crop` region (fractions of the source) is aligned to the box. No skew, no recolor.
 */
export const Media: React.FC<Props> = ({ slot, width, height, fit, background }) => {
  const ar = slot.aspectRatio ?? 16 / 9;
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };

  // Source measured in units where its height is 1.
  const regionW = crop.w * ar;
  const regionH = crop.h;
  const scale =
    fit === "contain"
      ? Math.min(width / regionW, height / regionH)
      : Math.max(width / regionW, height / regionH);

  const shownW = regionW * scale;
  const shownH = regionH * scale;
  const originX = (width - shownW) / 2;
  const originY = (height - shownH) / 2;

  const fullW = ar * scale;
  const fullH = scale;
  const left = originX - crop.x * fullW;
  const top = originY - crop.y * fullH;

  const src = staticFile(slot.src);
  const style: React.CSSProperties = {
    position: "absolute",
    left,
    top,
    width: fullW,
    height: fullH,
    objectFit: "fill",
  };

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        background,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: originX,
          top: originY,
          width: shownW,
          height: shownH,
          overflow: "hidden",
        }}
      >
        {slot.kind === "video" ? (
          <OffthreadVideo
            src={src}
            startFrom={slot.startFrom ?? 0}
            playbackRate={slot.playbackRate ?? 1}
            muted
            style={{ ...style, left: left - originX, top: top - originY }}
          />
        ) : (
          <Img src={src} style={{ ...style, left: left - originX, top: top - originY }} />
        )}
      </div>
    </div>
  );
};
