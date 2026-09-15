import React from "react";
import type { Brand, Layout, RevealKind, Surface } from "../schema";
import { easeInOut, easeOut, plateShadow, progress, type Box } from "../lib";

type Props = {
  kind: RevealKind;
  /** Frame relative to the start of the divider's motion (0..duration). */
  frame: number;
  duration: number;
  box: Box;
  brand: Brand;
  layout: Layout;
  surface: Surface;
  label?: string;
};

const OVERSHOOT = 120;

/**
 * A plain matte sheet that passes over the stage to uncover the next demonstration.
 * The physical motion is applied to this sheet only, never to the product beneath.
 *
 * - lift:   rises from below the stage, covers it, and continues up out of frame
 * - sleeve: slides in from the right and out to the left
 * - fold:   slides up to cover, then folds away around its top edge
 * - cut:    no divider
 */
export const Divider: React.FC<Props> = ({
  kind,
  frame,
  duration,
  box,
  brand,
  layout,
  surface,
  label,
}) => {
  if (kind === "cut" || frame < 0 || frame > duration) return null;

  const t = progress(frame, 0, duration, easeInOut);
  // Lifted while moving, resting at the middle when it covers the stage.
  const elevation = 1 + 2.2 * Math.sin(Math.PI * Math.min(1, frame / duration));

  let transform = "";
  let transformOrigin = "center";
  let perspective: number | undefined;

  if (kind === "lift") {
    const y = (box.h + OVERSHOOT) * (1 - 2 * t);
    transform = `translateY(${y}px)`;
  } else if (kind === "sleeve") {
    const x = (box.w + OVERSHOOT) * (1 - 2 * t);
    transform = `translateX(${x}px)`;
  } else {
    const half = duration / 2;
    const slideIn = progress(frame, 0, half, easeOut);
    const fold = progress(frame, half, duration, easeInOut);
    const y = (box.h + OVERSHOOT) * (1 - slideIn);
    const angle = -90 * fold;
    transform = `translateY(${y}px) rotateX(${angle}deg)`;
    transformOrigin = "top center";
    perspective = 2600;
    if (fold >= 1) return null;
  }

  const sheet = (
    <div
      style={{
        position: "absolute",
        left: box.x,
        top: box.y,
        width: box.w,
        height: box.h,
        background: brand.surface,
        borderRadius: layout.plateRadius,
        boxShadow: plateShadow(surface, elevation),
        transform,
        transformOrigin,
        backfaceVisibility: "hidden",
      }}
    >
      {kind === "fold" ? (
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: 0,
            height: 1,
            background: brand.line,
          }}
        />
      ) : null}
      {label ? (
        <div
          style={{
            position: "absolute",
            left: layout.platePadding + 8,
            top: layout.platePadding + 6,
            fontFamily: brand.monoFontFamily,
            fontSize: 14,
            letterSpacing: 0.28,
            textTransform: "uppercase",
            color: brand.inkSubtle,
          }}
        >
          {label}
        </div>
      ) : null}
    </div>
  );

  if (perspective) {
    return (
      <div
        style={{
          position: "absolute",
          inset: 0,
          perspective,
          perspectiveOrigin: `${box.x + box.w / 2}px ${box.y}px`,
        }}
      >
        {sheet}
      </div>
    );
  }
  return sheet;
};
