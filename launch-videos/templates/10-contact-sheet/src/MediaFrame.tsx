import React from "react";
import { Freeze, Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "./schema";

type Props = {
  slot: MediaSlot;
  brand: Brand;
  width: number;
  height: number;
  /**
   * Video only. `{ frame }` shows a single source frame (thumbnail / freeze);
   * `null` plays from `slot.startFrom` at the current Sequence frame.
   */
  still: { frame: number } | null;
  radius?: number;
  shadow?: boolean;
};

/**
 * Renders a media slot inside a fixed-size frame. The UI is only cropped and
 * scaled (never skewed or recolored): the full source is laid out so the crop
 * region maps onto the frame with the requested fit.
 */
export const MediaFrame: React.FC<Props> = ({ slot, brand, width, height, still, radius = 16, shadow = false }) => {
  const sw = slot.sourceWidth ?? 1920;
  const sh = slot.sourceHeight ?? 1080;
  const crop = slot.crop ?? { x: 0, y: 0, w: 1, h: 1 };
  const fit = slot.fit ?? "cover";

  const regionAspect = (crop.w * sw) / (crop.h * sh);
  const frameAspect = width / height;
  const fillWidth = fit === "cover" ? regionAspect < frameAspect : regionAspect > frameAspect;
  const rw = fillWidth ? width : height * regionAspect;
  const rh = fillWidth ? width / regionAspect : height;
  const rx = (width - rw) / 2;
  const ry = (height - rh) / 2;

  // The full source is laid out relative to the region box, which clips it.
  const fullW = rw / crop.w;
  const fullH = rh / crop.h;
  const left = -crop.x * fullW;
  const top = -crop.y * fullH;

  const mediaStyle: React.CSSProperties = {
    position: "absolute",
    left,
    top,
    width: fullW,
    height: fullH,
    objectFit: "fill",
  };

  const src = staticFile(slot.src);
  const startFrom = slot.startFrom ?? 0;

  let inner: React.ReactNode;
  if (slot.kind === "image") {
    inner = <Img src={src} style={mediaStyle} />;
  } else {
    const video = (
      <OffthreadVideo
        src={src}
        startFrom={startFrom}
        playbackRate={slot.playbackRate ?? 1}
        muted
        pauseWhenBuffering={false}
        style={mediaStyle}
      />
    );
    inner = still ? (
      <Freeze frame={Math.max(0, still.frame - startFrom)}>{video}</Freeze>
    ) : (
      video
    );
  }

  return (
    <div
      style={{
        position: "absolute",
        left: 0,
        top: 0,
        width,
        height,
        overflow: "hidden",
        borderRadius: radius,
        backgroundColor: brand.surface,
        boxShadow: shadow ? "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)" : undefined,
      }}
    >
      <div style={{ position: "absolute", left: rx, top: ry, width: rw, height: rh, overflow: "hidden" }}>{inner}</div>
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: radius,
          border: `1px solid ${brand.line}`,
          pointerEvents: "none",
        }}
      />
    </div>
  );
};
