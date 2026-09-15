import React from "react";
import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, CameraView, Crop, Lighting, MediaSlot } from "../schema";
import { FRAME_HEIGHT, FRAME_WIDTH } from "../defaults";

const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

export const lerpCrop = (a: Crop, b: Crop, t: number): Crop => ({
  x: lerp(a.x, b.x, t),
  y: lerp(a.y, b.y, t),
  w: lerp(a.w, b.w, t),
  h: lerp(a.h, b.h, t),
});

export const lerpView = (a: CameraView, b: CameraView, t: number): CameraView => ({
  crop: lerpCrop(a.crop, b.crop, t),
  planeWidth: lerp(a.planeWidth, b.planeWidth, t),
  x: lerp(a.x, b.x, t),
  y: lerp(a.y, b.y, t),
});

export type PlaneRect = { left: number; top: number; width: number; height: number };

/** Pixel rectangle of the display plane for a camera view. */
export const planeRect = (slot: MediaSlot, view: CameraView): PlaneRect => {
  const width = view.planeWidth * FRAME_WIDTH;
  const aspect = (view.crop.w * slot.width) / (view.crop.h * slot.height);
  const height = width / aspect;
  return {
    width,
    height,
    left: view.x * FRAME_WIDTH - width / 2,
    top: view.y * FRAME_HEIGHT - height / 2,
  };
};

export type PlaneMotion = {
  opacity: number;
  rotateY: number;
  translateX: number;
};

/**
 * A thin display plane showing a pixel-preserved window of the source media.
 * The media is only ever cropped and uniformly scaled; the plane itself may
 * tilt a few degrees while a transition runs, never during a demonstration.
 */
export const Plane: React.FC<{
  slot: MediaSlot;
  view: CameraView;
  motion: PlaneMotion;
  brand: Brand;
  lighting: Lighting;
}> = ({ slot, view, motion, brand, lighting }) => {
  const rect = planeRect(slot, view);
  const innerW = rect.width / view.crop.w;
  const innerH = rect.height / view.crop.h;
  const s = lighting.shadowStrength;
  const closeUp = view.planeWidth >= 0.999;

  const mediaStyle: React.CSSProperties = {
    position: "absolute",
    width: innerW,
    height: innerH,
    left: -view.crop.x * innerW,
    top: -view.crop.y * innerH,
    display: "block",
  };

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        perspective: 2400,
        perspectiveOrigin: "50% 50%",
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          position: "absolute",
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          opacity: motion.opacity,
          transform: `translateX(${motion.translateX}px) rotateY(${motion.rotateY}deg)`,
          transformOrigin: "50% 50%",
          backfaceVisibility: "hidden",
          borderRadius: closeUp ? 0 : 16,
          overflow: "hidden",
          backgroundColor: brand.white,
          boxShadow: closeUp
            ? "none"
            : `0 4px 8px rgba(0,0,0,${0.22 * s}), 0 1px 1.5px rgba(0,0,0,${0.14 * s}), 0 40px 90px rgba(0,0,0,${0.12 * s})`,
          outline: lighting.planeBorder && !closeUp ? `1px solid ${brand.line}` : "none",
          outlineOffset: -1,
        }}
      >
        {slot.kind === "video" ? (
          <OffthreadVideo
            src={staticFile(slot.src)}
            startFrom={slot.startFrom ?? 0}
            playbackRate={slot.playbackRate ?? 1}
            muted
            style={mediaStyle}
          />
        ) : (
          <Img src={staticFile(slot.src)} style={mediaStyle} />
        )}
      </div>
    </div>
  );
};
