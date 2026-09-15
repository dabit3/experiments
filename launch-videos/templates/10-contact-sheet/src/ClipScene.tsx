import React from "react";
import { AbsoluteFill, interpolate, useCurrentFrame } from "remotion";
import type { ClipScene as ClipSceneProps, LaunchProps } from "./schema";
import { ContactSheet } from "./ContactSheet";
import { MediaFrame } from "./MediaFrame";
import { cellRect, easeInOut, fade, IndexFrame, lerpRect, MARGIN, pad2, STAGE } from "./layout";

type Props = {
  scene: ClipSceneProps;
  props: LaunchProps;
  frames: IndexFrame[];
};

const COLLAPSE_FRAMES = 12;

/**
 * One selected frame: grows out of its contact-sheet cell into the stage,
 * plays (or holds), freezes on its end state, then shrinks back to the index
 * while the next frame is selected.
 */
export const ClipScene: React.FC<Props> = ({ scene, props, frames }) => {
  const f = useCurrentFrame();
  const { brand, media, content, sheet } = props;
  const slot = media[scene.media];
  const D = scene.durationInFrames;
  const E = scene.expandFrames;
  const I = scene.indexFrames;
  const returnStart = D - I;
  const collapse = Math.min(COLLAPSE_FRAMES, I);

  const cell = cellRect(sheet, frames.length, scene.frameIndex);

  // Frame growth / return.
  const grow = interpolate(f, [0, E], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  const shrink = interpolate(f, [returnStart, returnStart + collapse], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: easeInOut,
  });
  const t = f < returnStart ? grow : 1 - shrink;
  const rect = lerpRect(cell, STAGE, t);

  const sheetOpacity = f < returnStart ? 1 - grow : shrink;
  const onStage = f >= E && f < returnStart;
  const captionOpacity = Math.min(fade(f, E, E + 10), fade(f, returnStart - 10, returnStart, true));

  // Playback and freeze. While the cell grows it shows its index thumbnail; the
  // video then plays from `startFrom` and freezes at `freezeAt` (clip-local frames).
  const playFrames = returnStart - E - scene.freezeHoldFrames;
  const freezeAt = scene.freezeAtFrame ?? Math.max(0, playFrames);
  const playLocal = Math.min(Math.max(0, f - E), freezeAt);
  const startFrom = slot?.startFrom ?? 0;
  const sourceFrame = f < E ? (slot?.thumbFrame ?? startFrom) : startFrom + playLocal;

  const nextSelected = scene.frameIndex + 1 < frames.length ? scene.frameIndex + 1 : null;
  const selected = f >= returnStart + collapse + 6 ? nextSelected : scene.frameIndex;
  const viewedUpTo = f >= returnStart ? scene.frameIndex + 1 : scene.frameIndex;

  if (!slot) {
    return null;
  }

  return (
    <AbsoluteFill style={{ backgroundColor: brand.paper, fontFamily: brand.fontFamily }}>
      <ContactSheet
        brand={brand}
        content={content}
        media={media}
        sheet={sheet}
        frames={frames}
        selected={selected}
        viewedUpTo={viewedUpTo}
        hideIndex={scene.frameIndex}
        opacity={sheetOpacity}
      />

      {/* Chapter number at the left edge, kept while the frame is enlarged. */}
      <div
        style={{
          position: "absolute",
          left: MARGIN,
          top: STAGE.y,
          opacity: captionOpacity,
          fontFamily: brand.monoFontFamily,
          color: brand.ink,
        }}
      >
        <div style={{ fontSize: 22, lineHeight: "28px", fontWeight: 500 }}>{pad2(scene.frameIndex + 1)}</div>
        <div style={{ fontSize: 13, lineHeight: "20px", color: brand.inkSubtle }}>/ {pad2(frames.length)}</div>
      </div>

      {/* Caption outside the footage. */}
      <div
        style={{
          position: "absolute",
          left: STAGE.x,
          width: STAGE.w,
          top: STAGE.y + STAGE.h + 40,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "baseline",
          gap: 48,
          opacity: captionOpacity,
        }}
      >
        <div
          style={{
            fontFamily: brand.fontFamily,
            fontWeight: 500,
            fontSize: 30,
            lineHeight: "38px",
            letterSpacing: -0.6,
            color: brand.ink,
            maxWidth: 1180,
          }}
        >
          {scene.caption}
        </div>
        <div
          style={{
            fontFamily: brand.monoFontFamily,
            fontWeight: 400,
            fontSize: 13,
            lineHeight: "20px",
            letterSpacing: 0.3,
            textTransform: "uppercase",
            color: brand.inkSubtle,
            whiteSpace: "nowrap",
          }}
        >
          {scene.label}
        </div>
      </div>

      {/* The selected frame. */}
      <div style={{ position: "absolute", left: rect.x, top: rect.y, width: rect.w, height: rect.h }}>
        <MediaFrame
          slot={slot}
          brand={brand}
          width={rect.w}
          height={rect.h}
          radius={interpolate(t, [0, 1], [8, 16])}
          shadow={onStage}
          still={{ frame: sourceFrame }}
        />
      </div>
    </AbsoluteFill>
  );
};
