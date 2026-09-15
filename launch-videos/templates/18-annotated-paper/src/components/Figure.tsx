import React, { useContext } from "react";
import { Img, staticFile } from "remotion";
import { useProgress } from "../anim";
import { color, ease, radius } from "../theme";
import { FigureContext, type FigureCtx } from "./FigureContext";

/** Normalised crop of the source image (0–1). */
export type Crop = { x: number; y: number; w: number; h: number };

/** Slow camera move; from/to are scale + translate in figure px. */
export type Move = {
  from: { scale: number; x?: number; y?: number };
  to: { scale: number; x?: number; y?: number };
  start?: number;
  duration: number;
};

export const useFigure = () => {
  const ctx = useContext(FigureContext);
  if (!ctx) throw new Error("useFigure must be used inside <Figure>");
  return ctx;
};

/** Source aspect ratios (width / height) of the shared screenshots. */
export const ASPECT = {
  web: 2990 / 1624,
  desktop: 2626 / 1858,
  desktop9: 3024 / 1898,
  cli: 3130 / 2122,
} as const;

export const figureHeight = (width: number, aspect: number, crop: Crop = FULL) =>
  (crop.h * (width / crop.w)) / aspect;

export const FULL: Crop = { x: 0, y: 0, w: 1, h: 1 };

type FigureProps = {
  /** Omit to render a transparent annotation-only layer with the same mapping. */
  src?: string;
  width: number;
  aspect: number;
  crop?: Crop;
  move?: Move;
  opacity?: number;
  /** Absolutely positioned on top of the previous figure (for cross-fades). */
  stacked?: boolean;
  children?: React.ReactNode;
};

/**
 * A screenshot printed on the sheet. Children are drawn inside the moving
 * layer so annotations stay locked to the UI they point at.
 */
export const Figure: React.FC<FigureProps> = ({
  src,
  width,
  aspect,
  crop = FULL,
  move,
  opacity = 1,
  stacked = false,
  children,
}) => {
  const imgW = width / crop.w;
  const imgH = imgW / aspect;
  const height = crop.h * imgH;

  const t = useProgress(move?.start ?? 0, move?.duration ?? 1, ease.inOut);
  const scale = move ? move.from.scale + (move.to.scale - move.from.scale) * t : 1;
  const tx = move ? (move.from.x ?? 0) + ((move.to.x ?? 0) - (move.from.x ?? 0)) * t : 0;
  const ty = move ? (move.from.y ?? 0) + ((move.to.y ?? 0) - (move.from.y ?? 0)) * t : 0;

  const ctx: FigureCtx = {
    toPx: (nx, ny) => ({ x: (nx - crop.x) * imgW, y: (ny - crop.y) * imgH }),
    width,
    height,
    scaleX: imgW,
    scaleY: imgH,
  };

  return (
    <FigureContext.Provider value={ctx}>
      <div
        style={{
          position: stacked ? "absolute" : "relative",
          left: stacked ? 0 : undefined,
          top: stacked ? 0 : undefined,
          width,
          height,
          overflow: "hidden",
          borderRadius: radius.md,
          border: src ? `1px solid ${color.border}` : "none",
          boxSizing: "border-box",
          backgroundColor: src ? color.offWhite : "transparent",
          opacity,
        }}
      >
        <div
          style={{
            position: "absolute",
            inset: 0,
            transform: `scale(${scale}) translate(${tx}px, ${ty}px)`,
            transformOrigin: "50% 50%",
          }}
        >
          {src ? (
            <Img
              src={staticFile(src)}
              style={{
                position: "absolute",
                left: -crop.x * imgW,
                top: -crop.y * imgH,
                width: imgW,
                height: imgH,
                display: "block",
              }}
            />
          ) : null}
          {children}
        </div>
      </div>
    </FigureContext.Provider>
  );
};
