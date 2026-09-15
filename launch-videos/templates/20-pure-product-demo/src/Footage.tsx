import React from "react";
import {
  Easing,
  Img,
  OffthreadVideo,
  interpolate,
  staticFile,
  useCurrentFrame,
} from "remotion";
import type { Brand, MediaSlot, Zoom } from "./schema";

export type Box = { width: number; height: number };

const fullCrop = { x: 0, y: 0, w: 1, h: 1 };

// Size of the cropped region once "contain"-fitted into the stage box.
export const fitCrop = (slot: MediaSlot, box: Box): Box => {
  const crop = slot.crop ?? fullCrop;
  const aspect = (crop.w * slot.width) / (crop.h * slot.height);
  if (box.width / box.height > aspect) {
    return { width: Math.round(box.height * aspect), height: box.height };
  }
  return { width: box.width, height: Math.round(box.width / aspect) };
};

type Props = {
  slot: MediaSlot;
  box: Box;
  brand: Brand;
  radius: number;
  zoom?: Zoom;
  durationInFrames: number;
};

// Renders one media slot flat and pixel-preserved: the source is scaled uniformly so
// that the crop region exactly fills a viewport, then optionally pushed in with a slow
// ease-in-out zoom. No skew, no recolor.
export const Footage: React.FC<Props> = ({ slot, box, brand, radius, zoom, durationInFrames }) => {
  const frame = useCurrentFrame();
  const crop = slot.crop ?? fullCrop;
  const size = fitCrop(slot, box);
  const mediaWidth = size.width / crop.w;
  const mediaHeight = size.height / crop.h;

  const scale = zoom
    ? interpolate(frame, [0, durationInFrames], [zoom.from, zoom.to], {
        easing: Easing.inOut(Easing.cubic),
        extrapolateLeft: "clamp",
        extrapolateRight: "clamp",
      })
    : 1;
  const origin = zoom ? `${zoom.originX * 100}% ${zoom.originY * 100}%` : "50% 50%";

  const mediaStyle: React.CSSProperties = {
    position: "absolute",
    left: -crop.x * mediaWidth,
    top: -crop.y * mediaHeight,
    width: mediaWidth,
    height: mediaHeight,
    display: "block",
  };

  return (
    <div
      style={{
        position: "relative",
        width: size.width,
        height: size.height,
        overflow: "hidden",
        borderRadius: radius,
        border: `1px solid ${brand.line}`,
        boxShadow: "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)",
        backgroundColor: brand.white,
      }}
    >
      <div
        style={{
          position: "absolute",
          inset: 0,
          transform: `scale(${scale})`,
          transformOrigin: origin,
        }}
      >
        {slot.kind === "image" ? (
          <Img src={staticFile(slot.src)} style={mediaStyle} />
        ) : (
          <OffthreadVideo
            src={staticFile(slot.src)}
            startFrom={slot.startFrom ?? 0}
            playbackRate={slot.playbackRate ?? 1}
            muted
            style={mediaStyle}
          />
        )}
      </div>
    </div>
  );
};
