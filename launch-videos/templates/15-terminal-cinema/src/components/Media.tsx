import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";

export type Fit = { w: number; h: number };

const fullCrop = { x: 0, y: 0, w: 1, h: 1 };

export const fitMedia = (slot: MediaSlot, boxW: number, boxH: number): Fit => {
  const crop = slot.crop ?? fullCrop;
  const aspect = (slot.sourceAspect ?? 16 / 9) * (crop.w / crop.h);
  if (aspect > boxW / boxH) {
    return { w: boxW, h: boxW / aspect };
  }
  return { w: boxH * aspect, h: boxH };
};

type Props = {
  slot: MediaSlot;
  fit: Fit;
  brand: Brand;
  radius: number;
};

export const Media: React.FC<Props> = ({ slot, fit, brand, radius }) => {
  const crop = slot.crop ?? fullCrop;
  const innerW = fit.w / crop.w;
  const innerH = fit.h / crop.h;
  const inner: React.CSSProperties = {
    position: "absolute",
    left: -crop.x * innerW,
    top: -crop.y * innerH,
    width: innerW,
    height: innerH,
    display: "block",
  };
  return (
    <div
      style={{
        position: "relative",
        width: fit.w,
        height: fit.h,
        overflow: "hidden",
        borderRadius: radius,
        border: `1px solid ${brand.line}`,
        backgroundColor: brand.surface,
        boxShadow: "0 4px 8px rgba(0,0,0,.22), 0 1px 1.5px rgba(0,0,0,.14)",
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
