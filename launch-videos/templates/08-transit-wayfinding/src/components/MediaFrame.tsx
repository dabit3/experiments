import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";
import { TYPE, cropPx, type Rect } from "../geometry";

type Props = {
  brand: Brand;
  slot: MediaSlot;
  // Final (fully expanded) rect of the frame; `rect` is where it is right now.
  target: Rect;
  rect: Rect;
  speedBadge?: string;
  radius?: number;
};

// Product footage, flat and front-facing. Crop + uniform scale only.
export const MediaFrame: React.FC<Props> = ({ brand, slot, target, rect, speedBadge, radius = 16 }) => {
  const c = cropPx(slot);
  const scale = target.w / c.w;
  const grow = rect.w / target.w;
  const mediaStyle: React.CSSProperties = {
    position: "absolute",
    left: -c.x * scale,
    top: -c.y * scale,
    width: slot.sourceWidth * scale,
    height: slot.sourceHeight * scale,
    display: "block",
  };
  const src = staticFile(slot.src);

  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        overflow: "hidden",
        borderRadius: radius * grow,
        background: brand.paper,
        boxShadow: "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)",
        outline: `1px solid ${brand.line}`,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: 0,
          top: 0,
          width: target.w,
          height: target.h,
          transform: `scale(${grow})`,
          transformOrigin: "top left",
        }}
      >
        {slot.kind === "video" ? (
          <OffthreadVideo
            src={src}
            startFrom={slot.startFrom ?? 0}
            playbackRate={slot.playbackRate ?? 1}
            muted
            style={mediaStyle}
          />
        ) : (
          <Img src={src} style={mediaStyle} />
        )}
        {speedBadge ? (
          <div
            style={{
              position: "absolute",
              right: 16,
              top: 16,
              padding: "4px 10px",
              borderRadius: 8,
              background: brand.ink,
              color: brand.white,
              fontFamily: brand.monoFontFamily,
              fontSize: TYPE.label.size,
              fontWeight: 500,
            }}
          >
            {speedBadge}
          </div>
        ) : null}
      </div>
    </div>
  );
};
