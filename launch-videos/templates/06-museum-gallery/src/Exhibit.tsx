import React from "react";
import { Sequence } from "remotion";
import { Label } from "./Label";
import { Media } from "./Media";
import { Wall } from "./Wall";
import { WIDTH } from "./defaults";
import { enter, linear, move } from "./motion";
import type { Brand, Content, ExhibitScene, Gallery, LaunchProps } from "./schema";

type Props = {
  scene: ExhibitScene;
  brand: Brand;
  content: Content;
  gallery: Gallery;
  media: LaunchProps["media"];
  /** Frame relative to the scene start (negative while the camera is still arriving). */
  localFrame: number;
  /** Frames the enclosing Sequence starts before the scene (the camera lead-in). */
  lead: number;
  /** Position of this exhibit in the run (e.g. "2 / 3") for the floor line. */
  wayfinding: string;
};

/**
 * One display surface on the wall. The composed screenshot is the subject first; the
 * camera dollies gently toward it, then the matching recording fades in as the display
 * expands to fill most of the frame. The label sits beside the display throughout.
 */
export const Exhibit: React.FC<Props> = ({
  scene,
  brand,
  content,
  gallery,
  media,
  localFrame,
  lead,
  wayfinding,
}) => {
  const still = media[scene.still];
  const motion = scene.motion ? media[scene.motion] : undefined;
  if (!still) {
    throw new Error(`Exhibit ${scene.id}: unknown media slot "${scene.still}"`);
  }

  const f = Math.max(0, localFrame);
  const revealAt = scene.revealAt ?? Math.round(scene.durationInFrames / 3);
  const hasMotion = Boolean(motion);

  // Slow dolly toward the still, then a deliberate expansion as the recording arrives.
  const dollyWidth = linear(
    f,
    0,
    hasMotion ? revealAt : scene.durationInFrames,
    gallery.displayWidthStill,
    gallery.displayWidthDolly,
  );
  const displayWidth = hasMotion
    ? Math.max(
        dollyWidth,
        move(f, revealAt, gallery.expandFrames, gallery.displayWidthDolly, gallery.displayWidthMotion),
      )
    : dollyWidth;
  const displayHeight = (displayWidth * 9) / 16;
  const displayLeft = gallery.safeMargin;
  const displayTop = gallery.displayCenterY - displayHeight / 2;

  const motionOpacity = hasMotion ? enter(f, revealAt, gallery.crossfadeFrames) : 0;

  const labelLeft = displayLeft + displayWidth + gallery.labelGap;
  const labelOpacity = enter(f, 6, 12);
  const labelShift = (1 - labelOpacity) * 12;

  const stage = content.stages[scene.stageIndex] ?? "";
  const useCase = content.useCases[scene.useCaseIndex] ?? "";
  const caption = content.captions[scene.captionIndex] ?? "";
  const rate = motion?.playbackRate ?? 1;
  const medium = hasMotion
    ? `Screenshot, then screen recording${rate !== 1 ? ` · ${content.speedBadge}` : ""}`
    : "Screenshot";
  const meta = `${scene.isResult ? "Delivered result" : "Real product UI"} · ${medium}`;

  return (
    <Wall brand={brand} gallery={gallery}>
      <div
        style={{
          position: "absolute",
          left: displayLeft,
          top: displayTop,
          width: displayWidth,
          height: displayHeight,
          borderRadius: gallery.displayRadius,
          boxShadow: gallery.displayShadow,
          border: `1px solid ${brand.line}`,
          overflow: "hidden",
          backgroundColor: brand.surfaceAlt,
        }}
      >
        <Media slot={still} width={displayWidth} height={displayHeight} />
        {motion ? (
          <Sequence from={revealAt + lead} layout="none">
            <Media
              slot={motion}
              width={displayWidth}
              height={displayHeight}
              style={{ position: "absolute", left: 0, top: 0, opacity: motionOpacity }}
            />
          </Sequence>
        ) : null}
        {motion && rate !== 1 ? (
          <div
            style={{
              position: "absolute",
              right: 16,
              top: 16,
              padding: "4px 10px",
              borderRadius: 8,
              backgroundColor: brand.ink,
              color: brand.white,
              fontFamily: brand.monoFontFamily,
              fontSize: 14,
              opacity: motionOpacity,
            }}
          >
            {content.speedBadge}
          </div>
        ) : null}
      </div>

      <Label
        brand={brand}
        width={gallery.labelWidth}
        eyebrow={`${scene.numeral} · ${stage}`}
        title={useCase}
        caption={caption}
        meta={meta}
        style={{
          left: labelLeft,
          top: gallery.displayCenterY - 140,
          opacity: labelOpacity,
          transform: `translateY(${labelShift}px)`,
        }}
      />

      <div
        style={{
          position: "absolute",
          left: gallery.safeMargin,
          right: gallery.safeMargin,
          bottom: 48,
          display: "flex",
          justifyContent: "space-between",
          fontFamily: brand.monoFontFamily,
          fontSize: 13,
          lineHeight: "19px",
          color: brand.inkSubtle,
          maxWidth: WIDTH - gallery.safeMargin * 2,
        }}
      >
        <span>{content.featureName}</span>
        <span>{wayfinding}</span>
      </div>
    </Wall>
  );
};
