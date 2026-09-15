import { Img, OffthreadVideo, staticFile } from "remotion";
import type { Brand, MediaSlot } from "../schema";

type Props = {
  slot: MediaSlot;
  brand: Brand;
  /** Panel size in px. The crop region is scaled to fill it exactly. */
  width: number;
  height: number;
  /** 0..1 fraction of the panel width that is currently uncovered (from the left). */
  reveal?: number;
};

const fullCrop = { x: 0, y: 0, w: 1, h: 1 };

/**
 * Size a panel so that it matches the aspect ratio of the crop region and
 * fits inside the given box, anchored to the top-left grid intersection.
 */
export const fitPanel = (slot: MediaSlot, maxWidth: number, maxHeight: number) => {
  const crop = slot.crop ?? fullCrop;
  const aspect = (slot.sourceWidth * crop.w) / (slot.sourceHeight * crop.h);
  let width = maxWidth;
  let height = width / aspect;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * aspect;
  }
  return { width: Math.round(width), height: Math.round(height) };
};

/**
 * Flat, front-facing product footage. The source is only ever translated and
 * uniformly scaled; the panel clips it to the crop region.
 */
export const MediaPanel = ({ slot, brand, width, height, reveal = 1 }: Props) => {
  const crop = slot.crop ?? fullCrop;
  const scale = width / (slot.sourceWidth * crop.w);
  const mediaStyle = {
    position: "absolute" as const,
    left: -crop.x * slot.sourceWidth * scale,
    top: -crop.y * slot.sourceHeight * scale,
    width: slot.sourceWidth * scale,
    height: slot.sourceHeight * scale,
    display: "block",
  };
  return (
    <div
      style={{
        position: "relative",
        width: Math.max(0, Math.round(width * reveal)),
        height,
        overflow: "hidden",
        background: brand.surface,
        boxShadow: `inset 0 0 0 1px ${brand.line}`,
      }}
    >
      {slot.kind === "video" ? (
        <OffthreadVideo
          src={staticFile(slot.src)}
          trimBefore={slot.startFrom}
          playbackRate={slot.playbackRate}
          muted
          style={mediaStyle}
        />
      ) : (
        <Img src={staticFile(slot.src)} style={mediaStyle} />
      )}
      <div
        style={{
          position: "absolute",
          inset: 0,
          boxShadow: `inset 0 0 0 1px ${brand.line}`,
          pointerEvents: "none",
        }}
      />
    </div>
  );
};
