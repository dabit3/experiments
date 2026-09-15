import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";

type Props = {
  slot: MediaSlot;
  brand: Brand;
  areaWidth: number;
  areaHeight: number;
  speedBadge: string;
  monoFontFamily: string;
};

/**
 * Fits a media slot (optionally cropped) inside the media area, preserving the source
 * aspect ratio. Crop and scale only: the UI is never stretched or skewed.
 */
export const MediaView: React.FC<Props> = ({
  slot,
  brand,
  areaWidth,
  areaHeight,
  speedBadge,
  monoFontFamily,
}) => {
  const srcW = slot.width ?? 1920;
  const srcH = slot.height ?? 1080;
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const cropW = srcW * crop.w;
  const cropH = srcH * crop.h;
  const scale = Math.min(areaWidth / cropW, areaHeight / cropH);
  const frameW = Math.round(cropW * scale);
  const frameH = Math.round(cropH * scale);
  const innerW = frameW / crop.w;
  const innerH = frameH / crop.h;
  const src = staticFile(slot.src);
  const rate = slot.playbackRate ?? 1;

  const mediaStyle: React.CSSProperties = {
    position: "absolute",
    left: -crop.x * innerW,
    top: -crop.y * innerH,
    width: innerW,
    height: innerH,
    objectFit: "fill",
  };

  return (
    <div
      style={{
        position: "absolute",
        left: (areaWidth - frameW) / 2,
        top: (areaHeight - frameH) / 2,
        width: frameW,
        height: frameH,
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          overflow: "hidden",
          borderRadius: 12,
          border: `1px solid ${brand.line}`,
          boxShadow: "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)",
          background: brand.white,
        }}
      >
        {slot.kind === "video" ? (
          <OffthreadVideo
            src={src}
            startFrom={slot.startFrom ?? 0}
            playbackRate={rate}
            muted
            style={mediaStyle}
          />
        ) : (
          <Img src={src} style={mediaStyle} />
        )}
      </div>
      {rate > 1 ? (
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
            lineHeight: "20px",
          }}
        >
          {speedBadge}
        </div>
      ) : null}
    </div>
  );
};
