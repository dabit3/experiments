import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { MediaSlot } from "../schema";

type Props = {
  slot: MediaSlot;
  width: number;
  height: number;
  radius: number;
  borderColor: string;
};

/**
 * Real product footage, flat and pixel-preserved. Only crop and uniform scale are
 * applied; the crop is done by an overflow-hidden window over the full source.
 */
export const Media: React.FC<Props> = ({ slot, width, height, radius, borderColor }) => {
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const innerW = width / crop.w;
  const innerH = height / crop.h;
  const innerStyle: React.CSSProperties = {
    position: "absolute",
    left: -crop.x * innerW,
    top: -crop.y * innerH,
    width: innerW,
    height: innerH,
    objectFit: "fill",
    display: "block",
  };
  const src = staticFile(slot.src);
  return (
    <div
      style={{
        position: "relative",
        width,
        height,
        overflow: "hidden",
        borderRadius: radius,
        boxShadow: `inset 0 0 0 1px ${borderColor}`,
        background: "#FFFFFF",
      }}
    >
      {slot.kind === "video" ? (
        <OffthreadVideo
          src={src}
          trimBefore={slot.startFrom}
          playbackRate={slot.playbackRate}
          muted
          style={innerStyle}
        />
      ) : (
        <Img src={src} style={innerStyle} />
      )}
      {/* hairline border on top so the frame stays crisp over the media */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: radius,
          boxShadow: `inset 0 0 0 1px ${borderColor}`,
          pointerEvents: "none",
        }}
      />
    </div>
  );
};
